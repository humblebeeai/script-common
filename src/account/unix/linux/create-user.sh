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
_OS_DISTRO=""
if [ "${_OS}" = "Linux" ]; then
	if [ -r /etc/os-release ]; then
		# shellcheck disable=SC1091
		_OS_DISTRO="$(source /etc/os-release && echo "${ID}")"
		_OS_DISTRO="$(echo "${_OS_DISTRO}" | tr '[:upper:]' '[:lower:]')"

		if [ "${_OS_DISTRO}" = "debian" ]; then
			PATH="/usr/sbin:${PATH}"
		fi
	fi
else
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' is supported!"
	exit 1
fi

if ! command -v useradd >/dev/null 2>&1; then
	echo "[ERROR]: 'useradd' command not found or not installed!"
	exit 1
fi

if ! command -v usermod >/dev/null 2>&1; then
	echo "[ERROR]: 'usermod' command not found or not installed!"
	exit 1
fi

if ! command -v getent >/dev/null 2>&1; then
	echo "[ERROR]: 'getent' command not found or not installed!"
	exit 1
fi

if ! command -v chmod >/dev/null 2>&1; then
	echo "[ERROR]: 'chmod' command not found or not installed!"
	exit 1
fi


_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
fi
## --- Base --- ##


## --- Variables --- ##
PRIMARY_GID=${PRIMARY_GID:-11000}
USER_ID=${USER_ID:-}
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
				-g=* | --gid=* | --primary-gid=*)
					PRIMARY_GID="${_input#*=}"
					shift;;
				-u=* | --user=* | --username=*)
					USERNAME="${_input#*=}"
					shift;;
				-i=* | --uid=* | --user-id=*)
					USER_ID="${_input#*=}"
					shift;;
				-s | --sudo | --with-sudo)
					WITH_SUDO=true
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -g=*, --gid=*, --primary-gid=* | -u=*, --user=*, --username=* | -i=*, --uid=*, --user-id=* | -s, --sudo, --with-sudo"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -z "${PRIMARY_GID}" ]; then
		echo "[ERROR]: Primary GID is empty!"
		exit 1
	fi

	if ! [[ "${PRIMARY_GID}" =~ ^[0-9]+$ ]] || [ "${PRIMARY_GID}" -lt 1000 ]; then
		echo "[ERROR]: Primary GID '${PRIMARY_GID}' is invalid, must be a number and >= 1000!"
		exit 1
	fi

	if [ -z "${USERNAME}" ]; then
		echo "[ERROR]: Username is empty!"
		exit 1
	fi

	if ! [[ "${USERNAME}" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]] || [ "${USERNAME}" = "root" ]; then
		echo "[ERROR]: Username '${USERNAME}' is invalid, must be alphanumeric and not 'root'!"
		exit 1
	fi

	if ! getent group "${PRIMARY_GID}" >/dev/null 2>&1; then
		echo "[ERROR]: Group with '${PRIMARY_GID}' GID does not exist!"
		exit 1
	fi

	local _arg_uid=""
	if [ -n "${USER_ID}" ]; then
		if ! [[ "${USER_ID}" =~ ^[0-9]+$ ]] || [ "${USER_ID}" -lt 1000 ]; then
			echo "[ERROR]: UID '${USER_ID}' is invalid, must be a number and >= 1000!"
			exit 1
		fi

		if id "${USER_ID}" >/dev/null 2>&1; then
			echo "[ERROR]: User with '${USER_ID}' UID already exists!"
			exit 1
		fi

		_arg_uid="-u ${USER_ID}"
	fi

	if id "${USERNAME}" >/dev/null 2>&1; then
		echo "[ERROR]: User '${USERNAME}' already exists!"
		exit 1
	fi


	local _arg_sudo_group=""
	if [ "${WITH_SUDO}" = true ]; then
		_arg_sudo_group=",sudo"
	fi

	echo "[INFO]: Creating new user..."
	#shellcheck disable=SC2086
	${_SUDO} useradd -s /bin/bash -m -d "/home/${USERNAME}" -N -g "${PRIMARY_GID}" -G "${PRIMARY_GID}${_arg_sudo_group}" ${_arg_uid} "${USERNAME}" || exit 2
	${_SUDO} chmod -c 755 "/home/${USERNAME}" || exit 2
	echo -e "[OK]: Done.\n"

	if getent group docker >/dev/null 2>&1; then
		echo "[INFO]: Adding user '${USERNAME}' to 'docker' group..."
		${_SUDO} usermod -aG docker "${USERNAME}" || exit 2
		echo -e "[OK]: Done.\n"
	fi
}

main "${@:-}"
## --- Main --- ##
