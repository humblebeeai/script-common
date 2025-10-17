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
if [ "${_OS}" != "Linux" ] && [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' and 'macOS' are supported!"
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

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!"
	exit 2
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
				-a | --install-all-runtimes)
					ALL_RUNTIMES=true
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -a, --install-all-runtimes"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	echo "[INFO]: Setting up user environment..."

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/setup-user-workspaces.sh | bash || {
		echo "[ERROR]: Failed to create workspaces!"
		exit 2
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/setup-user-ohmyzsh.sh | bash || {
		echo "[ERROR]: Failed to install 'oh-my-zsh'!"
		exit 2
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/setup-user-shell.sh | bash || {
		echo "[ERROR]: Failed to setup shell configs!"
		exit 2
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/runtimes/install-user-miniconda.sh | bash || {
		echo "[ERROR]: Failed to install 'Miniconda'!"
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/runtimes/install-user-nvm.sh | bash || {
		echo "[ERROR]: Failed to install 'NVM'!"
	}

	if [ "${ALL_RUNTIMES}" = true ]; then
		curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/runtimes/install-user-rust.sh | bash || {
			echo "[ERROR]: Failed to install 'Rust'!"
		}

		curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/runtimes/install-user-go.sh | bash || {
			echo "[ERROR]: Failed to install 'Go'!"
		}
	fi

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/setup-user-nvchad.sh | bash || {
		echo "[ERROR]: Failed to setup 'NvChad'!"
		exit 2
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/post-setup-user.sh | bash || {
		echo "[ERROR]: Failed to post setup!"
		exit 2
	}

	echo -e "[OK]: Done.\n"
}

main "${@:-}"
## --- Main --- ##
