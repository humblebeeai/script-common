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

if ! command -v userdel >/dev/null 2>&1; then
	echo "[ERROR]: 'userdel' command not found or not installed!" >&2
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
USERNAMES="${USERNAMES:-}"
ALL_USERS=${ALL_USERS:-false}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -u, --users, --usernames [USER1,USER2,...]    Comma-separated list of usernames to delete.
    -a, --all, --all-users                        Delete all non-system users (UID > 1000). Default: false
    -h, --help                                    Show help.

EXAMPLES:
    ${0} --users user1,user2,user3
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
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
	echo "[INFO]: Deleting users..."

	if [ "${ALL_USERS}" = true ]; then
		USERNAMES="$(getent passwd | awk -F: '$3>1000 && $1!="nobody"{print $1}' | paste -sd, -)"
	fi

	if [ -z "${USERNAMES}" ]; then
		echo "[ERROR]: USERNAMES variable is empty!" >&2
		exit 1
	fi

	case ",${USERNAMES}," in
		*",root,"*) echo "[ERROR]: Cannot delete 'root' user!" >&2; exit 1;;
	esac


	local _usernames_arr
	IFS=',' read -r -a _usernames_arr <<< "${USERNAMES}"
	local _username
	for _username in "${_usernames_arr[@]}"; do
		[ -n "${_username}" ] || continue

		if ! id "${_username}" >/dev/null 2>&1; then
			echo "[WARN]: User '${_username}' does not exist, skipping!" >&2
			continue
		fi

		echo "[INFO]: Deleting user '${_username}'..."
		${_SUDO} userdel -r -f "${_username}" || exit 2
		echo "[OK]: Done."
	done

	echo "[INFO]: Successfully deleted users."
	echo ""
}

main
## --- Main --- ##
