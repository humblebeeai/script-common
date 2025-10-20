#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
cd "${_SCRIPT_DIR}" || exit 2


# shellcheck disable=SC1091
[ -f .env ] && . .env


_OS="$(uname)"
if [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'macOS' is supported!" >&2
	exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' command not found or not installed!" >&2
	exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
	echo "[ERROR]: Current user is 'root', please run this script as a normal user!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
ALL_RUNTIMES=${ALL_RUNTIMES:-false}
SCRIPT_BASE_URL="${SCRIPT_BASE_URL:-https://github.com/humblebeeai/script-common/raw/main/src}"
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -a, --all, --all-runtimes    Install all runtimes (Rust, Go, Miniconda, NVM). Default: false
    -h, --help                   Show help.

EXAMPLES:
    ${0} --all
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-a | --all | --all-runtimes)
			ALL_RUNTIMES=true
			shift;;
		-h | --help)
			_usage_help
			exit 0;;
		*)
			echo "[ERROR]: Failed to parse argument -> ${1}!" >&2
			_usage_help
			exit 1;;
	esac
done
## --- Menu arguments --- ##


## --- Main --- ##
_fetch()
{
	if [ -z "${1:-}" ]; then
		echo "[ERROR]: URL is empty!" >&2
		exit 1
	fi

	curl -H 'Cache-Control: no-cache' -fsSL "${1}";
}

main()
{
	echo ""
	echo "[INFO]: Setting up development environment on macOS..."

	if [ -z "${SCRIPT_BASE_URL}" ]; then
		echo "[ERROR]: SCRIPT_BASE_URL is empty!" >&2
		exit 1
	fi


	_fetch "${SCRIPT_BASE_URL}/setup/unix/macos/install-essentials.sh" | bash || {
		echo "[ERROR]: Failed to install essential packages!" >&2
		exit 2
	}

	local _arg_all=""
	if [ "${ALL_RUNTIMES}" = true ]; then
		_arg_all="-s -- -a"
	fi
	#shellcheck disable=SC2086
	_fetch "${SCRIPT_BASE_URL}/setup/unix/setup-user-env.sh" | \
		bash ${_arg_all} || {
			echo "[ERROR]: Failed to setup user environment!" >&2
			exit 2
		}

	echo "[OK]: Successfully setup development environment on macOS."
	echo ""
}

main
## --- Main --- ##
