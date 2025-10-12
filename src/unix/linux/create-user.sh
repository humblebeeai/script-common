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

if ! command -v useradd >/dev/null 2>&1; then
	echo "[ERROR]: 'useradd' command not found or not installed!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
PRIMARY_GID=${PRIMARY_GID:-11000}
NEW_UID=${NEW_UID:-}
NEW_USER=${NEW_USER:-user}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-g=* | --primary-gid=*)
					PRIMARY_GID="${_input#*=}"
					shift;;
				-n=* | --username=*)
					NEW_USER="${_input#*=}"
					shift;;
				-u=* | --uid=*)
					NEW_UID="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -g=*, --primary-gid=* | -n=*, --username=* | -u=*, --uid=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -z "${PRIMARY_GID}" ] || ! [[ "${PRIMARY_GID}" =~ ^[0-9]+$ ]] || [ "${PRIMARY_GID}" -lt 1000 ]; then
		echo "[ERROR]: Primary GID '${PRIMARY_GID}' is invalid, must be a number and >= 1000!"
		exit 1
	fi

	if [ -z "${NEW_USER}" ] || ! [[ "${NEW_USER}" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
		echo "[ERROR]: Username '${NEW_USER}' is invalid, must be alphanumeric and can include underscores or hyphens!"
		exit 1
	fi

	if ! getent group "${PRIMARY_GID}" >/dev/null 2>&1; then
		echo "[ERROR]: Group with '${PRIMARY_GID}' GID does not exist!"
		exit 1
	fi

	local _arg_uid=""
	if [ -n "${NEW_UID}" ]; then
		if ! [[ "${NEW_UID}" =~ ^[0-9]+$ ]] || [ "${NEW_UID}" -lt 1000 ]; then
			echo "[ERROR]: UID '${NEW_UID}' is invalid, must be a number and >= 1000!"
			exit 1
		fi

		if getent passwd "${NEW_UID}" >/dev/null 2>&1; then
			echo "[ERROR]: User with '${NEW_UID}' UID already exists!"
			exit 1
		fi

		_arg_uid="-u ${NEW_UID}"
	fi

	if getent passwd "${NEW_USER}" >/dev/null 2>&1; then
		echo "[ERROR]: User '${NEW_USER}' already exists!"
		exit 1
	fi


	echo "[INFO]: Creating new user..."
	#shellcheck disable=SC2086
	${_SUDO} useradd -s /bin/bash -m -d "/home/${NEW_USER}" -N -g "${PRIMARY_GID}" ${_arg_uid} "${NEW_USER}"
	echo -e "[OK]: Done.\n"
}

main "${@:-}"
## --- Main --- ##
