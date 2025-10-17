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

if ! ${_SUDO} command -v usermod >/dev/null 2>&1; then
	echo "[ERROR]: 'usermod' command not found or not installed!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
USERNAMES=${USERNAMES:-}
GROUP=${GROUP:-}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-u=* | --users=* | --usernames=*)
					USERNAMES="${_input#*=}"
					shift;;
				-g=* | --group=*)
					GROUP="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -u=*, --users=*, --usernames=* |  -g=*, --group=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -z "${GROUP}" ]; then
		echo "[ERROR]: GROUP variable is empty!"
		exit 1
	fi

	USERNAMES=$(echo "${USERNAMES}" | tr ',' ' ' | xargs -n1 | grep -v "^root$" | xargs || echo "")
	if [ -z "${USERNAMES}" ]; then
		echo "[ERROR]: No users specified or only 'root' user provided!"
		exit 1
	fi

	local _username
	for _username in ${USERNAMES}; do
		if ! id "${_username}" >/dev/null 2>&1; then
			echo "[WARN]: User '${_username}' does not exist, skipping...!"
			continue
		fi

		if id -nG "${_username}" | grep -qw "sudo"; then
			echo "[WARN]: User '${_username}' is already in '${GROUP}' group, skipping...!"
			continue
		fi

		echo "[INFO]: Adding user '${_username}' to '${GROUP}' group..."
		${_SUDO} usermod -aG "${GROUP}" "${_username}" || exit 2
		echo -e "[OK]: Done.\n"
	done
}

main "${@:-}"
## --- Main --- ##
