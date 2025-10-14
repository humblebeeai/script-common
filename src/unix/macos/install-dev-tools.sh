#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
# cd "${_SCRIPT_DIR}" || exit 2


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

if ! command -v brew >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'brew' command, install Homebrew first!"
	exit 1
fi
## --- Base --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Installing development tools..."

	echo "[INFO]: Updating Homebrew package lists..."
	brew update || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing 'neovim'..."
	brew install neovim || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing 'gh' (GitHub CLI)..."
	brew install gh || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Cleaning up..."
	brew cleanup --prune=all || exit 2
	echo -e "[OK]: Done.\n"

	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
