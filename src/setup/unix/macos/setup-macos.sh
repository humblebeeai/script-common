#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
cd "${_SCRIPT_DIR}" || exit 2


# Loading .env file (if exists):
if [ -f ".env" ]; then
	# shellcheck disable=SC1091
	source .env
fi


_OS="$(uname)"
if [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'macOS' is supported!"
	exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' command not found or not installed!"
	exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
	echo "[ERROR]: Current user is 'root', please run this script as a normal user!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
ALL_RUNTIMES=${ALL_RUNTIMES:-false}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-a | --all-runtimes | --install-all-runtimes)
					ALL_RUNTIMES=true
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -a, --all-runtimes, --install-all-runtimes"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	echo "[INFO]: Setting up development environment on macOS..."

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/setup/unix/macos/install-essentials.sh | bash || {
		echo "[ERROR]: Failed to install essential packages!"
		exit 2
	}

	local _arg_all_runtimes=""
	if [ "${ALL_RUNTIMES}" = true ]; then
		_arg_all_runtimes="-s -- -a"
	fi
	#shellcheck disable=SC2086
	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/setup/unix/setup-user-env.sh | \
		bash ${_arg_all_runtimes} || {
			echo "[ERROR]: Failed to setup user environment!"
			exit 2
		}

	echo -e "[OK]: Done.\n"
}

main "${@:-}"
## --- Main --- ##
