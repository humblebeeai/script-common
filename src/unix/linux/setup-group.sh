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
_IS_ROOT_USER=false
_SUDO="sudo"
if [ "${_OS}" = "Linux" ]; then
	if [ "$(id -u)" -eq 0 ]; then
		_IS_ROOT_USER=true
		_SUDO=""
	fi
else
	echo "[ERROR]: Unsupported OS '${_OS}'!"
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
NEW_GID=${NEW_GID:-11000}
NEW_GROUP=${NEW_GROUP:-devs}
TARGET_USERS=${TARGET_USERS:-"${id -un}"}
ALL_USERS=${ALL_USERS:-true}
## --- Variables --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Setting up group..."
	if getent group "${NEW_GID}" >/dev/null 2>&1; then
		echo "[INFO]: Group with '${NEW_GID}' GID already exists. Skipping..."
	else
		echo "[INFO]: Creating new group '${NEW_GROUP}' with GID '${NEW_GID}'..."
		${_SUDO} groupadd -f -g "${NEW_GID}" "${NEW_GROUP}" || exit 2
		echo -e "[OK]: Done.\n"
	fi

	if [ "${ALL_USERS}" = true ]; then
		TARGET_USERS=""
		local _user_home_dir
		for _user_home_dir in /home/*; do
			local _username
			_username=$(basename "${_user_home_dir}")
			if getent passwd "${_username}" >/dev/null; then
				TARGET_USERS="${TARGET_USERS} ${_username}"
			else
				echo "[WARN]: Not found '${_username}' user in the system but found home directory '${_user_home_dir}'!"
			fi
		done
	fi

	local _user
	for _user in ${TARGET_USERS}; do
		if [ "$(id -g "${_user}")" -eq "${NEW_GID}" ]; then
			echo "[INFO]: '${_user}' user's primary group is already set to '${NEW_GID}'. Skipping..."
		else
			echo "[INFO]: Changing primary group of user '${_user}' to '${NEW_GID}'..."
			${_SUDO} usermod -g "${NEW_GID}" "${_user}" || exit 2
			echo -e "[OK]: Done.\n"
		fi
	done
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
