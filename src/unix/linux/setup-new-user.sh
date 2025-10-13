#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
cd "${_SCRIPT_DIR}" || exit 2


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

if ! command -v getent >/dev/null 2>&1; then
	echo "[ERROR]: 'getent' command not found or not installed!"
	exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' command not found or not installed!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
PRIMARY_GID=${PRIMARY_GID:-11000}
USERNAME=${USERNAME:-}
PASSWORD=${PASSWORD:-}
WITH_SUDO=${WITH_SUDO:-false}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-g=* | --gid=* | --primary-gid=*)
					PRIMARY_GID="${_input#*=}"
					shift;;
				-u=* | --user=* | --username=*)
					USERNAME="${_input#*=}"
					shift;;
				-p=* | --pass=* | --password=*)
					PASSWORD="${_input#*=}"
					shift;;
				-s | --sudo | --with-sudo)
					WITH_SUDO=true
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -g=*, --gid=*, --primary-gid=* | -u=*, --user=*, --username=* | -p=*, --pass=*, --password=* | -s, --sudo, --with-sudo"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -z "${PRIMARY_GID}" ]; then
		echo "[ERROR]: Primary GID is empty!"
		exit 1
	fi

	if ! [[ "${PRIMARY_GID}" =~ ^[0-9]+$ ]] || [ "${PRIMARY_GID}" -lt 1000 ]; then
		echo "[ERROR]: Primary GID '${PRIMARY_GID}' is invalid, must be a number and >= 1000!"
		exit 1
	fi

	if [ -z "${USERNAME}" ]; then
		echo "[ERROR]: Username is empty!"
		exit 1
	fi

	if ! [[ "${USERNAME}" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]] || [ "${USERNAME}" = "root" ]; then
		echo "[ERROR]: Username '${USERNAME}' is invalid, must be alphanumeric and not 'root'!"
		exit 1
	fi

	if ! id "${USERNAME}" >/dev/null 2>&1; then
		if ! getent group "${PRIMARY_GID}" >/dev/null 2>&1; then
			curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/create-group.sh | \
				bash -s -- -g="${PRIMARY_GID}" || {
					echo "[ERROR]: Failed to create group with GID '${PRIMARY_GID}'!"
					exit 1
				}
		fi

		_arg_sudo=""
		if [ "${WITH_SUDO}" = true ]; then
			_arg_sudo="-s"
		fi

		curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/create-user.sh | \
			bash -s -- -g="${PRIMARY_GID}" -u="${USERNAME}" ${_arg_sudo} || {
				echo "[ERROR]: Failed to create user '${USERNAME}'!"
				exit 1
			}

		_arg_is_plain="-i"
		if [ -z "${PASSWORD}" ]; then
			PASSWORD="\$6\$u2FNPRPID32cWjCo\$TrEzf1ox9iRK9cqGEYCICnlZ04Z0S0AsFE2SYfvcifJDzMHM5TE0LHverClhN0ZbBHPW5LJZGsplGnPzlYwMg0"
			_arg_is_plain=""
		fi
		curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/change-password.sh | \
			bash -s -- -u="${USERNAME}" -p="${PASSWORD}" ${_arg_is_plain} || {
				echo "[ERROR]: Failed to set password for user '${USERNAME}'!"
				exit 1
			}
	fi

	${_SUDO} su - "${USERNAME}" -c "curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/create-workspaces.sh | bash" || {
		echo "[ERROR]: Failed to create workspaces for user '${USERNAME}'!"
		exit 1
	}

	${_SUDO} su - "${USERNAME}" -c "curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/install-ohmyzsh.sh | bash" || {
		echo "[ERROR]: Failed to install oh-my-zsh for user '${USERNAME}'!"
		exit 1
	}
}

main "${@:-}"
## --- Main --- ##
