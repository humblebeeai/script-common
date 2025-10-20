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

if ! command -v usermod >/dev/null 2>&1; then
	echo "[ERROR]: 'usermod' command not found or not installed!" >&2
	exit 1
fi


_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
elif ! command -v sudo >/dev/null 2>&1; then
	echo "[ERROR]: 'sudo' is required when not running as root!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
GROUP=${GROUP:-}
USERNAMES="${USERNAMES:-$(id -un)}"
ALL_USERS=${ALL_USERS:-false}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -g, --group [GROUP]                     Specify the group to add users to. REQUIRED.
    -u, --users, --usernames [USERNAMES]    Comma-separated list of usernames to add to the group. Default <current-user>
    -a, --all, --all-users                  Add all users with UID >= 1000 (excluding 'nobody') to the group. Default false
    -h, --help                              Show help.

EXAMPLES:
    ${0} --group sudo
    ${0} -g sudo -u user1,user2
    ${0} --group docker --all-users
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-g | --group)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			GROUP="${2}"
			shift 2;;
		-g=* | --group=*)
			GROUP="${1#*=}"
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
	echo "[INFO]: Adding users to group..."

	if [ -z "${GROUP}" ]; then
		echo "[ERROR]: GROUP variable is empty!" >&2
		exit 1
	fi

	if ! getent group "${GROUP}" >/dev/null 2>&1; then
		echo "[ERROR]: Group '${GROUP}' does not exist!" >&2
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

		if id -nG "${_username}" | grep -wq "${GROUP}"; then
			echo "[WARN]: User '${_username}' is already in '${GROUP}' group, skipping!"
			continue
		fi

		echo "[INFO]: Adding user '${_username}' to '${GROUP}' group..."
		${_SUDO} usermod -aG "${GROUP}" "${_username}" || exit 2
		echo "[OK]: Done."
	done

	echo "[OK]: Successfully added users to group."
	echo ""
}

main
## --- Main --- ##
