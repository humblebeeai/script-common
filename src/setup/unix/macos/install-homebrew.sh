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
## --- Base --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Installing homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
