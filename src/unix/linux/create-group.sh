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
	echo "[INFO]: Creating group..."
	if ! getent group "${NEW_GID}" >/dev/null 2>&1; then
		echo "[INFO]: Creating new group '${NEW_GROUP}' with GID '${NEW_GID}'..."
		${_SUDO} groupadd -f -g "${NEW_GID}" "${NEW_GROUP}" || exit 2
		echo -e "[OK]: Done.\n"
	else
		echo "[WARN]: Group with '${NEW_GID}' GID already exists!"
	fi
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
