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

for _cmd in groupadd getent; do
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
GROUP_ID=${GROUP_ID:-11000}
GROUP_NAME=${GROUP_NAME:-devs}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -g, --gid, --group-id [GID]         Specify the GID for the new group. Default 11000
    -n, --group, --group-name [NAME]    Specify the name for the new group. Default 'devs'
    -h, --help                          Show help.

EXAMPLES:
    ${0} --gid 11000 --group devs
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-g | --gid | --group-id)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			GROUP_ID="${2}"
			shift 2;;
		-g=* | --gid=* | --group-id=*)
			GROUP_ID="${1#*=}"
			shift;;
		-n | --group | --group-name)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			GROUP_NAME="${2}"
			shift 2;;
		-n=* | --group=* | --group-name=*)
			GROUP_NAME="${1#*=}"
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
	echo "[INFO]: Creating a new group..."

	if [ -z "${GROUP_ID}" ]; then
		echo "[ERROR]: GROUP_ID variable is empty!" >&2
		exit 1
	fi

	if ! [[ "${GROUP_ID}" =~ ^[0-9]+$ ]] || [ "${GROUP_ID}" -lt 1000 ]; then
		echo "[ERROR]: Group GID '${GROUP_ID}' is invalid, must be a number and >= 1000!" >&2
		exit 1
	fi

	if [ -z "${GROUP_NAME}" ]; then
		echo "[ERROR]: GROUP_NAME variable is empty!" >&2
		exit 1
	fi

	if ! [[ "${GROUP_NAME}" =~ ^[a-z_][a-zA-Z0-9_-]*$ ]]; then
		echo "[ERROR]: Group name '${GROUP_NAME}' is invalid, must be lowercase alphanumeric and can include underscores or hyphens!" >&2
		exit 1
	fi

	if getent group "${GROUP_ID}" >/dev/null 2>&1; then
		echo "[ERROR]: Group with '${GROUP_ID}' GID already exists!" >&2
		exit 1
	fi

	if getent group "${GROUP_NAME}" >/dev/null 2>&1; then
		echo "[ERROR]: Group with name '${GROUP_NAME}' already exists!" >&2
		exit 1
	fi


	echo "[INFO]: Creating new group '${GROUP_NAME}' with GID '${GROUP_ID}'..."
	${_SUDO} groupadd -f -g "${GROUP_ID}" "${GROUP_NAME}" || exit 2
	echo "[OK]: Done."

	echo "[OK]: Successfully created a new group."
	echo ""
}

main
## --- Main --- ##
