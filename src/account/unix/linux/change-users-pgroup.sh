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

for _cmd in usermod getent; do
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
USERNAMES="${USERNAMES:-$(id -un)}"
ALL_USERS=${ALL_USERS:-false}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -g, --gid, --primary-gid [GID]          Specify the primary GID to set for the users. Default 11000
    -u, --users, --usernames [USERNAMES]    Comma-separated list of usernames to change primary group for. Default <current-user>
    -a, --all, --all-users                  Change primary group for all non-system users. Default is false
    -h, --help                              Show help.

EXAMPLES:
    ${0} --all-users
    ${0} --users user1,user2
    ${0} -g 11000 -u user1,user2
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
		-u | --users | --usernames)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			USERNAMES="${2}"
			shift 2;;
		-u=* | --users=* | --usernames=*)
			USERNAMES="${1#*=}"
			shift;;
		-a | --all | --all-users)
			ALL_USERS=true
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
	echo "[INFO]: Changing users' primary group..."

	if [ -z "${PRIMARY_GID}" ]; then
		echo "[ERROR]: PRIMARY_GID variable is empty!" >&2
		exit 1
	fi

	if ! [[ "${PRIMARY_GID}" =~ ^[0-9]+$ ]] || [ "${PRIMARY_GID}" -lt 1000 ]; then
		echo "[ERROR]: GID '${PRIMARY_GID}' is invalid, must be a number and >= 1000!" >&2
		exit 1
	fi

	if ! getent group "${PRIMARY_GID}" >/dev/null 2>&1; then
		echo "[ERROR]: Group with GID '${PRIMARY_GID}' does not exist!" >&2
		exit 1
	fi

	if [ "${ALL_USERS}" = true ]; then
		USERNAMES="$(getent passwd | awk -F: '$3>=1000 && $1!="nobody"{print $1}' | paste -sd, -)"
	fi

	if [ -z "${USERNAMES}" ]; then
		echo "[ERROR]: USERNAMES variable is empty!" >&2
		exit 1
	fi

	case ",${USERNAMES}," in
		*",root,"*) echo "[ERROR]: Cannot change 'root' user's primary group!" >&2; exit 1;;
	esac


	local _usernames_arr
	IFS=',' read -r -a _usernames_arr <<< "${USERNAMES}"
	local _username
	for _username in "${_usernames_arr[@]}"; do
		if ! id "${_username}" >/dev/null 2>&1; then
			echo "[WARN]: User '${_username}' does not exist, skipping!" >&2
			continue
		fi

		if [ "$(id -g "${_username}")" -eq "${PRIMARY_GID}" ]; then
			echo "[INFO]: '${_username}' user's primary group is already set to '${PRIMARY_GID}', skipping."
			continue
		fi

		echo "[INFO]: Changing primary group of user '${_username}' to '${PRIMARY_GID}'..."
		${_SUDO} usermod -g "${PRIMARY_GID}" -aG "${PRIMARY_GID}" "${_username}" || exit 2
		echo "[OK]: Done."
	done

	echo "[OK]: Successfully changed users' primary group."
	echo ""
}

main
## --- Main --- ##
