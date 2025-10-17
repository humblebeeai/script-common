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
if [ "${_OS}" != "Linux" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' is supported!"
	exit 1
fi

_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
fi

if ! ${_SUDO} command -v groupadd >/dev/null 2>&1; then
	echo "[ERROR]: 'groupadd' command not found or not installed!"
	exit 1
fi

if ! command -v getent >/dev/null 2>&1; then
	echo "[ERROR]: 'getent' command not found or not installed!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
GROUP_ID=${GROUP_ID:-11000}
GROUP_NAME=${GROUP_NAME:-devs}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-g=* | --gid=* | --group-id=*)
					GROUP_ID="${_input#*=}"
					shift;;
				-n=* | --group=* | --group-name=*)
					GROUP_NAME="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -g=*, --gid=*, --group-id=* | -n=*, --group=*, --group-name=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -z "${GROUP_ID}" ]; then
		echo "[ERROR]: Group ID is empty!"
		exit 1
	fi

	if ! [[ "${GROUP_ID}" =~ ^[0-9]+$ ]] || [ "${GROUP_ID}" -lt 1000 ]; then
		echo "[ERROR]: Group GID '${GROUP_ID}' is invalid, must be a number and >= 1000!"
		exit 1
	fi

	if [ -z "${GROUP_NAME}" ]; then
		echo "[ERROR]: Group name is empty!"
		exit 1
	fi

	if ! [[ "${GROUP_NAME}" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
		echo "[ERROR]: Group name '${GROUP_NAME}' is invalid, must be alphanumeric and can include underscores or hyphens!"
		exit 1
	fi

	if getent group "${GROUP_ID}" >/dev/null 2>&1; then
		echo "[ERROR]: Group with '${GROUP_ID}' GID already exists!"
		exit 1
	fi

	if getent group "${GROUP_NAME}" >/dev/null 2>&1; then
		echo "[ERROR]: Group with name '${GROUP_NAME}' already exists!"
		exit 1
	fi


	echo "[INFO]: Creating new group '${GROUP_NAME}' with GID '${GROUP_ID}'..."
	${_SUDO} groupadd -f -g "${GROUP_ID}" "${GROUP_NAME}" || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
