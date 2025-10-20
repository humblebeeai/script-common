#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
cd "${_SCRIPT_DIR}" || exit 2


# shellcheck disable=SC1091
[ -f .env ] && . .env


_OS="$(uname)"
case "${_OS}" in
	Linux | Darwin) : ;;
	*) echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' and 'macOS' are supported!" >&2; exit 1;;
esac

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
	echo "[INFO]: Setting up user development environment..."

	if [ -z "${SCRIPT_BASE_URL}" ]; then
		echo "[ERROR]: SCRIPT_BASE_URL is empty!" >&2
		exit 1
	fi


	_fetch "${SCRIPT_BASE_URL}/setup/unix/setup-user-workspaces.sh" | bash || {
		echo "[ERROR]: Failed to create workspaces!" >&2
		exit 2
	}

	_fetch "${SCRIPT_BASE_URL}/setup/unix/setup-user-ohmyzsh.sh" | bash || {
		echo "[ERROR]: Failed to install 'oh-my-zsh'!" >&2
		exit 2
	}

	_fetch "${SCRIPT_BASE_URL}/setup/unix/setup-user-configs.sh" | bash || {
		echo "[ERROR]: Failed to setup configs!" >&2
		exit 2
	}

	echo "[INFO]: Installing runtimes..."
	_fetch "${SCRIPT_BASE_URL}/setup/unix/runtimes/install-user-miniconda.sh" | bash || {
		echo "[WARN]: Failed to install 'Miniconda', skipping!" >&2
	}

	_fetch "${SCRIPT_BASE_URL}/setup/unix/runtimes/install-user-nvm.sh" | bash || {
		echo "[WARN]: Failed to install 'NVM', skipping!" >&2
	}

	if [ "${ALL_RUNTIMES}" = true ]; then
		_fetch "${SCRIPT_BASE_URL}/setup/unix/runtimes/install-user-rust.sh" | bash || {
			echo "[WARN]: Failed to install 'Rust', skipping!" >&2
		}

		_fetch "${SCRIPT_BASE_URL}/setup/unix/runtimes/install-user-go.sh" | bash || {
			echo "[WARN]: Failed to install 'Go', skipping!" >&2
		}
	fi
	echo "[OK]: Done."

	_fetch "${SCRIPT_BASE_URL}/setup/unix/setup-user-nvchad.sh" | bash || {
		echo "[WARN]: Failed to setup 'NvChad', skipping!" >&2
	}

	echo "[OK]: Successfully setup user development environment!"
	echo ""
}

main
## --- Main --- ##
