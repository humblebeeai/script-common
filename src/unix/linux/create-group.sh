#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# cd "${_SCRIPT_DIR}" || exit 2


# Loading .env file:
if [ -f ".env" ]; then
	# shellcheck disable=SC1091
	source .env
fi


_OS="$(uname)"
_SUDO="sudo"
if [ "${_OS}" = "Linux" ]; then
	if [ "$(id -u)" -eq 0 ]; then
		_SUDO=""
	fi
else
	echo "[ERROR]: Unsupported OS '${_OS}'!"
	exit 1
fi

if ! command -v getent >/dev/null 2>&1; then
	echo "[ERROR]: 'getent' command not found or not installed!"
	exit 1
fi

if ! command -v groupadd >/dev/null 2>&1; then
	echo "[ERROR]: 'groupadd' command not found or not installed!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
NEW_GID=${NEW_GID:-11000}
NEW_GROUP=${NEW_GROUP:-devs}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-g=* | --gid=*)
					NEW_GID="${_input#*=}"
					shift;;
				-n=* | --group-name=*)
					NEW_GROUP="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -g=*, --gid=* | -n=*, --group-name=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -z "${NEW_GID}" ] || ! [[ "${NEW_GID}" =~ ^[0-9]+$ ]] || [ "${NEW_GID}" -lt 1000 ]; then
		echo "[ERROR]: Group GID '${NEW_GID}' is invalid, must be a number and >= 1000!"
		exit 1
	fi

	if [ -z "${NEW_GROUP}" ] || ! [[ "${NEW_GROUP}" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
		echo "[ERROR]: Group name '${NEW_GROUP}' is invalid, must be alphanumeric and can include underscores or hyphens!"
		exit 1
	fi

	if getent group "${NEW_GID}" >/dev/null 2>&1; then
		echo "[ERROR]: Group with '${NEW_GID}' GID already exists!"
		exit 1
	fi

	if getent group "${NEW_GROUP}" >/dev/null 2>&1; then
		echo "[ERROR]: Group with name '${NEW_GROUP}' already exists!"
		exit 1
	fi


	echo "[INFO]: Creating new group '${NEW_GROUP}' with GID '${NEW_GID}'..."
	${_SUDO} groupadd -f -g "${NEW_GID}" "${NEW_GROUP}" || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
