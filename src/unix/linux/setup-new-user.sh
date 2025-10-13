#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
cd "${_SCRIPT_DIR}" || exit 2


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
## --- Base --- ##


## --- Variables --- ##
USERNAME=${USERNAME:-}
WITH_SUDO=${WITH_SUDO:-false}
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
				-s | --sudo | --with-sudo)
					WITH_SUDO=true
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -u=*, --user=*, --username=* | -s, --sudo, --with-sudo"
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
		_arg_sudo=""
		if [ "${WITH_SUDO}" = true ]; then
			_arg_sudo="-s"
		fi

		./create-user.sh -u="${USERNAME}" ${_arg_sudo} || {
			echo "[ERROR]: Failed to create user '${USERNAME}'!"
			exit 1
		}
	fi
}

main "${@:-}"
## --- Main --- ##
