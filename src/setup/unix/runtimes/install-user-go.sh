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
if [ "${_OS}" != "Linux" ] && [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' and 'macOS' are supported!"
	exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' not found or not installed!"
	exit 1
fi

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!"
	exit 2
fi
## --- Base --- ##


## --- Variables --- ##
GO_DIR=${GO_DIR:-"${HOME}/workspaces/runtimes/go"}
## --- Variables --- ##


## --- Main --- ##
_setup_shell()
{
	echo "[INFO]: ..."
}

main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-i=* | --install-dir=*)
					GO_DIR="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -i=*, --install-dir=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -z "${GO_DIR}" ]; then
		echo "[ERROR]: GO_DIR variable is empty!"
		exit 2
	fi

	echo "[INFO]: Installing Go in '${GO_DIR}'..."
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
