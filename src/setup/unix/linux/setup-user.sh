#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
cd "${_SCRIPT_DIR}" || exit 2


# shellcheck disable=SC1091
[ -f .env ] && . .env


_OS="$(uname)"
if [ "${_OS}" != "Linux" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' is supported!" >&2
	exit 1
fi

for _cmd in getent curl chmod; do
	if ! command -v "${_cmd}" >/dev/null 2>&1; then
		echo "[ERROR]: Not found '${_cmd}' command, please install it first." >&2
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
USERNAME=${USERNAME:-}
if [ -z "${USERNAME}" ] && [ "$(id -u)" -ne 0 ]; then
	USERNAME=$(id -un)
fi
PASSWORD=${PASSWORD:-}
IS_HASHED=${IS_HASHED:-false}
WITH_SUDO=${WITH_SUDO:-false}
RUNTIMES=${RUNTIMES:-conda,nvm}
SCRIPT_BASE_URL="${SCRIPT_BASE_URL:-https://github.com/humblebeeai/script-common/raw/main/src}"
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -g, --gid, --primary-gid [GID]       Specify the primary GID for the new user. Default: 11000
    -u, --user, --username [USERNAME]    Specify the username for the new user. Default: <current-user>
    -p, --pass, --password [PASSWORD]    Specify the password for the new user. If new user created and password not provided, set to '<username>_PASSWORD123'
    -H, --hashed, --hashed-password      Indicate that the provided password is already hashed. Default: false
    -s, --sudo, --with-sudo              Grant sudo privileges to the new user. Default: false
    -r, --runtimes                       Comma-separated list of runtimes to install ('conda', 'nvm', 'rust', 'go'). Default: 'conda,nvm'.
    -h, --help                           Show help.

EXAMPLES:
    ${0} -u newuser -s -r all
    ${0} --primary-gid=11000 --username=newuser --password=MyPass123 --with-sudo --runtimes=all
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
		-H | --hashed | --hashed-password)
			IS_HASHED=true
			shift;;
		-s | --sudo | --with-sudo)
			WITH_SUDO=true
			shift;;
		-r | --runtimes)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			RUNTIMES="${2}"
			shift 2;;
		-r=* | --runtimes=*)
			RUNTIMES="${1#*=}"
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
_fetch()
{
	if [ -z "${1:-}" ]; then
		echo "[ERROR]: URL is empty!" >&2
		exit 1
	fi

	curl -H 'Cache-Control: no-cache' -fsSL "${1}";
}

main()
{
	echo ""
	echo "[INFO]: Setting up user account..."

	if [ -z "${PRIMARY_GID}" ]; then
		echo "[ERROR]: PRIMARY_GID is empty!" >&2
		exit 1
	fi

	if ! [[ "${PRIMARY_GID}" =~ ^[0-9]+$ ]] || [ "${PRIMARY_GID}" -lt 1000 ]; then
		echo "[ERROR]: PRIMARY_GID '${PRIMARY_GID}' is invalid, must be a number and >= 1000!" >&2
		exit 1
	fi

	if [ -z "${USERNAME}" ]; then
		echo "[ERROR]: USERNAME is empty!" >&2
		exit 1
	fi

	if ! [[ "${USERNAME}" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]] || [ "${USERNAME}" = "root" ]; then
		echo "[ERROR]: USERNAME '${USERNAME}' is invalid, must be alphanumeric and not 'root'!" >&2
		exit 1
	fi

	if [ -z "${SCRIPT_BASE_URL}" ]; then
		echo "[ERROR]: SCRIPT_BASE_URL is empty!" >&2
		exit 1
	fi


	if ! getent group "${PRIMARY_GID}" >/dev/null 2>&1; then
		_fetch "${SCRIPT_BASE_URL}/account/unix/linux/create-group.sh" | \
			bash -s -- -g="${PRIMARY_GID}" || {
				echo "[ERROR]: Failed to create group with GID '${PRIMARY_GID}'!" >&2
				exit 2
			}
	fi

	local _user_created=false
	if ! id "${USERNAME}" >/dev/null 2>&1; then

		local _arg_sudo=""
		if [ "${WITH_SUDO}" = true ]; then
			_arg_sudo="-s"
		fi
		_fetch "${SCRIPT_BASE_URL}/account/unix/linux/create-user.sh" | \
			bash -s -- -g="${PRIMARY_GID}" -n="${USERNAME}" ${_arg_sudo} || {
				echo "[ERROR]: Failed to create user '${USERNAME}'!" >&2
				exit 2
			}

		_user_created=true
	fi

	if [ "${_user_created}" = true ] || [ -n "${PASSWORD}" ]; then
		if [ -z "${PASSWORD}" ]; then
			PASSWORD="${USERNAME}_PASSWORD123"
			IS_HASHED=false
		fi

		local _arg_hashed=""
		if [ "${IS_HASHED}" = true ]; then
			_arg_hashed="-H"
		fi
		_fetch "${SCRIPT_BASE_URL}/account/unix/linux/change-password.sh" | \
			bash -s -- -u="${USERNAME}" -p="${PASSWORD}" ${_arg_hashed} || {
				echo "[ERROR]: Failed to set password for user '${USERNAME}'!" >&2
				exit 2
			}
	fi

	if [ "$(id -g "${USERNAME}")" != "${PRIMARY_GID}" ]; then
		_fetch "${SCRIPT_BASE_URL}/account/unix/linux/change-user-pgroup.sh" | \
			bash -s -- -g="${PRIMARY_GID}" -u="${USERNAME}" || {
				echo "[ERROR]: Failed to change primary group for user '${USERNAME}'!" >&2
				exit 2
			}
	fi

	if getent group docker >/dev/null 2>&1 && ! id -nG "${USERNAME}" | grep -wq docker; then
		_fetch "${SCRIPT_BASE_URL}/account/unix/linux/add-user-group.sh" | \
			bash -s -- -g=docker -u="${USERNAME}" || {
				echo "[ERROR]: Failed to add user '${USERNAME}' to 'docker' group!" >&2
				exit 2
			}
	fi

	${_SUDO} su - "${USERNAME}" -c "curl -H 'Cache-Control: no-cache' -fsSL ${SCRIPT_BASE_URL}/setup/unix/setup-user-env.sh | \
		bash -s -- -r=${RUNTIMES}" || {
			echo "[ERROR]: Failed to setup user environment for '${USERNAME}'!" >&2
			exit 2
		}

	${_SUDO} chmod -c 755 "/home/${USERNAME}" || exit 2

	echo "[OK]: Successfully setup user account."
	echo ""
}

main
## --- Main --- ##
