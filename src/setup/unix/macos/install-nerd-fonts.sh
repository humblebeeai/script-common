#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
# _SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
# cd "${_SCRIPT_DIR}" || exit 2


# shellcheck disable=SC1091
[ -f .env ] && . .env


_OS="$(uname)"
if [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'macOS' is supported!"
	exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
	echo "[ERROR]: 'brew' command not found or not installed!" >&2
	exit 1
fi
## --- Base --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Installing Nerd Fonts..."

	echo "[INFO]: Installing Ubuntu Mono Nerd Font..."
	brew install font-ubuntu-mono-nerd-font || {
		echo "[WARN]: Failed to install 'Ubuntu Mono Nerd Font', skipping!" >&2
	}
	echo "[OK]: Done."

	echo "[INFO]: Installing Ubuntu Nerd Font..."
	brew install font-ubuntu-nerd-font || {
		echo "[WARN]: Failed to install 'Ubuntu Nerd Font', skipping!" >&2
	}
	echo "[OK]: Done."

	echo "[INFO]: Installing Roboto Mono Nerd Font..."
	brew install font-roboto-mono-nerd-font || {
		echo "[WARN]: Failed to install 'Roboto Mono Nerd Font', skipping!" >&2
	}
	echo "[OK]: Done."

	echo "[INFO]: Installing Terminess Nerd Font..."
	brew install font-terminess-ttf-nerd-font || {
		echo "[WARN]: Failed to install 'Terminess Nerd Font', skipping!" >&2
	}
	echo "[OK]: Done."

	echo "[OK]: Successfully installed Nerd Fonts."
}

main
## --- Main --- ##
