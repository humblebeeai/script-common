#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
# _SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
# cd "${_SCRIPT_DIR}" || exit 2


# shellcheck disable=SC1091
[ -f .env ] && . .env


_OS="$(uname)"
if [ "${_OS}" != "Linux" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' is supported!" >&2
	exit 1
fi

case ":${PATH}:" in
	*:/usr/sbin:*) : ;;
	*) PATH="/usr/sbin:${PATH}";;
esac
case ":${PATH}:" in
	*:/sbin:*) : ;;
	*) PATH="/sbin:${PATH}";;
esac

for _cmd in useradd usermod getent chmod; do
	if ! command -v "${_cmd}" >/dev/null 2>&1; then
		echo "[ERROR]: Not found '${_cmd}' command, please install it first!" >&2
		exit 1
	fi
done


_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
elif ! command -v sudo >/dev/null 2>&1; then
	echo "[ERROR]: 'sudo' is required when not running as root!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
PRIMARY_GID=${PRIMARY_GID:-11000}
USER_ID=${USER_ID:-}
USERNAME=${USERNAME:-}
WITH_SUDO=${WITH_SUDO:-false}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -g, --gid, --primary-gid [GID]       Primary GID for the new user. Default: 11000
    -u, --uid, --user-id [UID]           UID for the new user. Default: <auto-assign>
    -n, --user, --username [USERNAME]    Username for the new user. REQUIRED.
    -s, --sudo, --with-sudo              Add the new user to 'sudo' group. Default: false
    -h, --help                           Show help.

EXAMPLES:
    ${0} --username newuser --sudo
    ${0} -g=11000 -u=1001 -n=anotheruser
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-g | --gid | --primary-gid)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			PRIMARY_GID="${2}"
			shift 2;;
		-g=* | --gid=* | --primary-gid=*)
			PRIMARY_GID="${1#*=}"
			shift;;
		-u | --uid | --user-id)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			USER_ID="${2}"
			shift 2;;
		-u=* | --uid=* | --user-id=*)
			USER_ID="${1#*=}"
			shift;;
		-n | --user | --username)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			USERNAME="${2}"
			shift 2;;
		-n=* | --user=* | --username=*)
			USERNAME="${1#*=}"
			shift;;
		-s | --sudo | --with-sudo)
			WITH_SUDO=true
			shift;;
		-h | --help)
			_usage_help
			exit 0;;
		*)
			echo "[ERROR]: Failed to parse argument -> ${1}!" >&2
			_usage_help
			exit 1;;
	esac
done
## --- Menu arguments --- ##


## --- Main --- ##
main()
{
	echo ""
	echo "[INFO]: Creating a new user..."

	if [ -z "${PRIMARY_GID}" ]; then
		echo "[ERROR]: Primary GID is empty!" >&2
		exit 1
	fi

	if ! [[ "${PRIMARY_GID}" =~ ^[0-9]+$ ]] || [ "${PRIMARY_GID}" -lt 1000 ]; then
		echo "[ERROR]: Primary GID '${PRIMARY_GID}' is invalid, must be a number and >= 1000!" >&2
		exit 1
	fi

	if [ -z "${USERNAME}" ]; then
		echo "[ERROR]: USERNAME variable is empty!" >&2
		exit 1
	fi

	if ! [[ "${USERNAME}" =~ ^[a-z_][a-z0-9_-]*$ ]] || [ "${USERNAME}" = "root" ]; then
		echo "[ERROR]: Username '${USERNAME}' is invalid, must be lowercase alphanumeric and not 'root'!" >&2
		exit 1
	fi

	if ! getent group "${PRIMARY_GID}" >/dev/null 2>&1; then
		echo "[ERROR]: Group with '${PRIMARY_GID}' GID does not exist!" >&2
		exit 1
	fi

	local _arg_uid=""
	if [ -n "${USER_ID}" ]; then
		if ! [[ "${USER_ID}" =~ ^[0-9]+$ ]] || [ "${USER_ID}" -lt 1000 ]; then
			echo "[ERROR]: UID '${USER_ID}' is invalid, must be a number and >= 1000!" >&2
			exit 1
		fi

		if id "${USER_ID}" >/dev/null 2>&1; then
			echo "[ERROR]: User with '${USER_ID}' UID already exists!" >&2
			exit 1
		fi

		_arg_uid="-u ${USER_ID}"
	fi

	if id "${USERNAME}" >/dev/null 2>&1; then
		echo "[ERROR]: User '${USERNAME}' already exists!" >&2
		exit 1
	fi


	echo "[INFO]: Creating user '${USERNAME}'..."
	local _arg_sudo=""
	if [ "${WITH_SUDO}" = true ]; then
		_arg_sudo=",sudo"
	fi
	#shellcheck disable=SC2086
	${_SUDO} useradd -s /bin/bash -m -d "/home/${USERNAME}" -N -g "${PRIMARY_GID}" -G "${PRIMARY_GID}${_arg_sudo}" ${_arg_uid} "${USERNAME}" || exit 2
	${_SUDO} chmod -c 755 "/home/${USERNAME}" || exit 2
	echo "[OK]: Done."

	if getent group docker >/dev/null 2>&1; then
		echo "[INFO]: Adding user '${USERNAME}' to 'docker' group..."
		${_SUDO} usermod -aG docker "${USERNAME}" || exit 2
		echo "[OK]: Done."
	fi

	echo "[OK]: Successfully created a new user."
	echo ""
}

main
## --- Main --- ##
