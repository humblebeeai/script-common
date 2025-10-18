#!/bin/bash
set -euo pipefail


## --- Base --- ##
# _SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
# cd "${_SCRIPT_DIR}" || exit 2


if [ -f ".env" ]; then
	# shellcheck disable=SC1091
	. .env
fi


_OS="$(uname)"
if [ "${_OS}" != "Linux" ] && [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' and 'macOS' are supported!" >&2
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

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
INSTALL_ALL_RUNTIMES=${INSTALL_ALL_RUNTIMES:-false}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -a, --all, --install-all-runtimes    Install all runtimes (Rust, Go, Miniconda, NVM).
    -h, --help                           Show help.

EXAMPLES:
    ${0} --all
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-a | --all | --install-all-runtimes)
			INSTALL_ALL_RUNTIMES=true
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
main()
{
	echo ""
	echo "[INFO]: Setting up user development environment..."

	curl -H 'Cache-Control: no-cache' -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/setup-user-workspaces.sh | bash || {
		echo "[ERROR]: Failed to create workspaces!" >&2
		exit 2
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/setup-user-ohmyzsh.sh | bash || {
		echo "[ERROR]: Failed to install 'oh-my-zsh'!" >&2
		exit 2
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/setup-user-shell.sh | bash || {
		echo "[ERROR]: Failed to setup shellrc!" >&2
		exit 2
	}

	echo "[INFO]: Installing runtimes..."
	curl -H 'Cache-Control: no-cache' -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/runtimes/install-user-miniconda.sh | bash || {
		echo "[WARN]: Failed to install 'Miniconda'!"
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/runtimes/install-user-nvm.sh | bash || {
		echo "[WARN]: Failed to install 'NVM'!"
	}

	if [ "${INSTALL_ALL_RUNTIMES}" = true ]; then
		curl -H 'Cache-Control: no-cache' -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/runtimes/install-user-rust.sh | bash || {
			echo "[WARN]: Failed to install 'Rust'!"
		}

		curl -H 'Cache-Control: no-cache' -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/runtimes/install-user-go.sh | bash || {
			echo "[WARN]: Failed to install 'Go'!"
		}
	fi
	echo "[OK]: Done."

	curl -H 'Cache-Control: no-cache' -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/setup-user-nvchad.sh | bash || {
		echo "[ERROR]: Failed to setup 'NvChad'!" >&2
		exit 2
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/post-setup-user.sh | bash || {
		echo "[ERROR]: Failed to post setup!" >&2
		exit 2
	}

	echo "[OK]: Successfully setup user development environment!"
	echo ""
}

main
## --- Main --- ##
