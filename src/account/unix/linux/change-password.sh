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

if ! ${_SUDO} command -v chpasswd >/dev/null 2>&1; then
	echo "[ERROR]: 'chpasswd' command not found or not installed!"
	exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
	echo "[ERROR]: 'openssl' command not found or not installed!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
USERNAME=${USERNAME:-}
if [ -z "${USERNAME}" ] && [ -n "${_SUDO}" ]; then
	USERNAME=$(id -un)
fi
PASSWORD=${PASSWORD:-}
PASSWORD_PATH=${PASSWORD_PATH:-}
IS_HASHED=${IS_HASHED:-true}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-u=* | --user=* | --username=*)
					USERNAME="${_input#*=}"
					shift;;
				-p=* | --pass=* | --password=*)
					PASSWORD="${_input#*=}"
					shift;;
				-f=* | --password-file | --password-path=*)
					PASSWORD_PATH="${_input#*=}"
					shift;;
				-i | --is-plain | --is-plain-password)
					IS_HASHED=false
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -u=*, --user=*, --username=* | -p=*, --pass=*, --password=* | -f=*, --password-file=*, --password-path=* | -i, --is-plain, --is-plain-password"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##

	if [ -z "${USERNAME}" ]; then
		echo "[ERROR]: Username is empty!"
		exit 1
	fi

	if ! [[ "${USERNAME}" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]] || [ "${USERNAME}" = "root" ]; then
		echo "[ERROR]: Username '${USERNAME}' is invalid, must be alphanumeric and not 'root'!"
		exit 1
	fi

	if ! id "${USERNAME}" >/dev/null 2>&1; then
		echo "[ERROR]: User '${USERNAME}' does not exist!"
		exit 1
	fi

	if [ -n "${PASSWORD_PATH}" ]; then
		if [ ! -f "${PASSWORD_PATH}" ]; then
			echo "[ERROR]: Password file '${PASSWORD_PATH}' does not exist!"
			exit 1
		fi

		echo "[INFO]: Reading password from file '${PASSWORD_PATH}'..."
		PASSWORD=$(< "${PASSWORD_PATH}")
		echo -e "[OK]: Done.\n"
	fi

	if [ -z "${PASSWORD}" ]; then
		echo "[ERROR]: Password is empty!"
		exit 1
	fi


	if [ "${IS_HASHED}" = false ]; then
		echo "[INFO]: Hashing password..."
		PASSWORD=$(echo "${PASSWORD}" | openssl passwd -6 -stdin)
		echo -e "[OK]: Done.\n"
	fi

	echo "[INFO]: Changing password for user '${USERNAME}'..."
	echo -e "${USERNAME}:${PASSWORD}" | ${_SUDO} chpasswd -e
	echo -e "[OK]: Done.\n"
}

main "${@:-}"
## --- Main --- ##
