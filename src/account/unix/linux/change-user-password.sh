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

if ! command -v chpasswd >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'chpasswd' command, please install it first!" >&2
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
USERNAME=${USERNAME:-}
if [ -z "${USERNAME}" ] && [ "$(id -u)" -ne 0 ]; then
	USERNAME=$(id -un)
fi
PASSWORD="${PASSWORD:-}"
PASSWORD_PATH="${PASSWORD_PATH:-}"
IS_HASHED=${IS_HASHED:-false}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -u, --user, --username [USERNAME]          Specify the username to change password for. Default <current-user>
    -p, --pass, --password [PASSWORD]          Specify the new password for the user.
    -P, --pass-path, --password-path [PATH]    Specify the path to a file containing the new password for the user.
    -H, --hashed, --hashed-password            Indicate that the provided password is already hashed.
    -h, --help                                 Show help.

EXAMPLES:
    ${0} --password "NewP@ssw0rd!"
    ${0} -u user1 -P /run/secrets/user1_password.txt -H
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-u | --user | --username)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			USERNAME="${2}"
			shift 2;;
		-u=* | --user=* | --username=*)
			USERNAME="${1#*=}"
			shift;;
		-p | --pass | --password)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			PASSWORD="${2}"
			shift 2;;
		-p=* | --pass=* | --password=*)
			PASSWORD="${1#*=}"
			shift;;
		-P | --pass-path | --password-path)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			PASSWORD_PATH="${2}"
			shift 2;;
		-P=* | --pass-path=* | --password-path=*)
			PASSWORD_PATH="${1#*=}"
			shift;;
		-H | --hashed | --hashed-password)
			IS_HASHED=true
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
	echo "[INFO]: Changing user password..." >&2

	if [ -z "${USERNAME}" ]; then
		echo "[ERROR]: USERNAME variable is empty!" >&2
		exit 1
	fi

	if ! [[ "${USERNAME}" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]] || [ "${USERNAME}" = "root" ]; then
		echo "[ERROR]: Username '${USERNAME}' is invalid, must be alphanumeric and not 'root'!" >&2
		exit 1
	fi

	if ! id "${USERNAME}" >/dev/null 2>&1; then
		echo "[ERROR]: User '${USERNAME}' does not exist!" >&2
		exit 1
	fi

	if [ -n "${PASSWORD_PATH}" ]; then
		if [ ! -f "${PASSWORD_PATH}" ]; then
			echo "[ERROR]: Password file '${PASSWORD_PATH}' does not exist!" >&2
			exit 1
		fi

		echo "[INFO]: Reading password from file '${PASSWORD_PATH}'..."
		PASSWORD="$(head -n1 -- "${PASSWORD_PATH}" | tr -d '\n')"
		echo "[OK]: Done."
	fi

	if [ -z "${PASSWORD}" ]; then
		echo "[ERROR]: PASSWORD variable is empty!" >&2
		exit 1
	fi


	if [ "${IS_HASHED}" = false ]; then
		if ! command -v openssl >/dev/null 2>&1; then
			echo "[ERROR]: Not found 'openssl' command, please install it first!" >&2
			exit 1
		fi
		echo "[INFO]: Hashing password..."
		PASSWORD=$(echo "${PASSWORD}" | openssl passwd -6 -stdin)
		echo "[OK]: Done."
	fi

	echo "[INFO]: Changing password for user '${USERNAME}'..."
	echo "${USERNAME}:${PASSWORD}" | ${_SUDO} chpasswd -e
	echo "[OK]: Done."

	echo "[INFO]: Successfully changed user password."
	echo ""
}

main
## --- Main --- ##
