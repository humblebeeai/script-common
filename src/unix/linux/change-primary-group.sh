#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
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

if ! command -v usermod >/dev/null 2>&1; then
	echo "[ERROR]: 'usermod' command not found or not installed!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
PRIMARY_GID=${PRIMARY_GID:-11000}
PRIMARY_GROUP=${PRIMARY_GROUP:-devs}
USERNAMES=${USERNAMES:-"$(id -un)"}
ALL_USERS=${ALL_USERS:-true}
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
				-p=* | --group=* | --primary-group=*)
					PRIMARY_GROUP="${_input#*=}"
					shift;;
				-u=* | --users=* | --usernames=*)
					USERNAMES="${_input#*=}"
					ALL_USERS=false
					shift;;
				-a | --all | --all-users)
					ALL_USERS=true
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -g=*, --gid=*, --primary-gid=* | -p=*, --group=*, --primary-group=* | -u=*, --users=*, --usernames=* | -a, --all, --all-users"
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
		echo "[ERROR]: GID '${PRIMARY_GID}' is invalid, must be a number and >= 1000!"
		exit 1
	fi

	if [ -z "${PRIMARY_GROUP}" ]; then
		echo "[ERROR]: Primary group name is empty!"
		exit 1
	fi

	if ! [[ "${PRIMARY_GROUP}" =~ ^[a-zA-Z_][a-zA-Z0-9_-]*$ ]]; then
		echo "[ERROR]: Group name '${PRIMARY_GROUP}' is invalid, must be alphanumeric and can include underscores or hyphens!"
		exit 1
	fi


	if getent group "${PRIMARY_GID}" >/dev/null 2>&1; then
		echo "[INFO]: Group with '${PRIMARY_GID}' GID already exists. Skipping group creation..."
	else
		echo "[INFO]: Creating new group '${PRIMARY_GROUP}' with GID '${PRIMARY_GID}'..."
		${_SUDO} groupadd -f -g "${PRIMARY_GID}" "${PRIMARY_GROUP}" || exit 2
		echo -e "[OK]: Done.\n"
	fi

	local _username
	if [ "${ALL_USERS}" = true ]; then
		USERNAMES=""
		local _user_home_dir
		for _user_home_dir in /home/*; do
			_username=$(basename "${_user_home_dir}")
			if ! id "${_username}" >/dev/null 2>&1; then
				echo "[WARN]: Not found '${_username}' user in the system but found home directory '${_user_home_dir}'! Skipping..."
				continue
			fi

			if [ "$(id -u "${_username}")" -lt 1000 ]; then
				echo "[WARN]: '${_username}' user is a system user (UID < 1000)! Skipping..."
				continue
			fi

			USERNAMES="${USERNAMES},${_username}"
		done
	fi

	USERNAMES=$(echo "${USERNAMES}" | tr ',' ' ' | xargs -n1 | grep -v "^root$" | xargs || echo "")
	for _username in ${USERNAMES}; do
		if ! id "${_username}" >/dev/null 2>&1; then
			echo "[WARN]: User '${_username}' does not exist! Skipping..."
			continue
		fi

		if [ "$(id -g "${_username}")" -eq "${PRIMARY_GID}" ]; then
			echo "[INFO]: '${_username}' user's primary group is already set to '${PRIMARY_GID}'. Skipping..."
			continue
		fi

		echo "[INFO]: Changing primary group of user '${_username}' to '${PRIMARY_GID}'..."
		${_SUDO} usermod -g "${PRIMARY_GID}" -aG "${PRIMARY_GID}" "${_username}" || exit 2
		echo -e "[OK]: Done.\n"
	done
}

main "${@:-}"
## --- Main --- ##
