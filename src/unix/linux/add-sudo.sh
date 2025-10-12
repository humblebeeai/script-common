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

if ! command -v usermod >/dev/null 2>&1; then
	echo "[ERROR]: 'usermod' command not found or not installed!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
USERS=${USERS:-}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-u=* | --users=*)
					USERS="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -u=*, --users=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	USERS=$(echo "${USERS}" | tr ',' ' ' | xargs -n1 | grep -v "^root$" | xargs || echo "")
	if [ -z "${USERS}" ]; then
		echo "[ERROR]: No users specified or only 'root' user provided!"
		exit 1
	fi

	local _user
	for _user in ${USERS}; do
		if ! id "${_user}" >/dev/null 2>&1; then
			echo "[WARN]: User '${_user}' does not exist! Skipping..."
			continue
		fi

		if id -nG "${_user}" | grep -qw "sudo"; then
			echo "[WARN]: User '${_user}' is already in 'sudo' group! Skipping..."
			continue
		fi

		echo "[INFO]: Adding user '${_user}' to 'sudo' group..."
		${_SUDO} usermod -aG sudo "${_user}" || exit 2
		echo -e "[OK]: Done.\n"
	done
}

main "${@:-}"
## --- Main --- ##
