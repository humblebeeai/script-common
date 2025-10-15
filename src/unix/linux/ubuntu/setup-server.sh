#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
cd "${_SCRIPT_DIR}" || exit 2


# Loading .env file (if exists):
if [ -f ".env" ]; then
	# shellcheck disable=SC1091
	source .env
fi


_OS="$(uname)"
_OS_DISTRO=""
if [ "${_OS}" = "Linux" ]; then
	if [ -r /etc/os-release ]; then
		# shellcheck disable=SC1091
		_OS_DISTRO="$(source /etc/os-release && echo "${ID}")"
		_OS_DISTRO="$(echo "${_OS_DISTRO}" | tr '[:upper:]' '[:lower:]')"

		if [ "${_OS_DISTRO}" != "ubuntu" ] && [ "${_OS_DISTRO}" != "debian" ]; then
			echo "[ERROR]: Unsupported Linux distro '${_OS_DISTRO}', only 'Ubuntu' and 'Debian' are supported!"
			exit 1
		fi
	else
		echo "[ERROR]: Unable to determine Linux distro!"
		exit 1
	fi
else
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' is supported!"
	exit 1
fi

if [ "$(uname -m)" != "x86_64" ] && [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "arm64" ]; then
	echo "[ERROR]: Unsupported CPU architecture '$(uname -m)', only 'x86_64', 'arm64' and 'aarch64' are supported!"
	exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' not found or not installed!"
	exit 1
fi


_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
fi
## --- Base --- ##


## --- Variables --- ##
TZ_NAME=${TZ_NAME:-Asia/Seoul}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-t=* | --tz=* | --timezone=*)
					TZ_NAME="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -t=*, --tz=*, --timezone=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	echo "[INFO]: Setting up server..."

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/ubuntu/setup-tz-locales.sh | \
		bash -s -- -t="${TZ_NAME}" || {
			echo "[ERROR]: Failed to setup timezone and locales!"
			exit 2
		}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/ubuntu/install-basics.sh | \
		bash || {
			echo "[ERROR]: Failed to install basic packages!"
			exit 2
		}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/ubuntu/install-dev-tools.sh | \
		bash || {
			echo "[ERROR]: Failed to install development tools!"
			exit 2
		}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/setup-docker.sh | \
		bash || {
			echo "[ERROR]: Failed to setup Docker!"
			exit 2
		}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/change-primary-group.sh | \
		bash -s -- -a || {
			echo "[ERROR]: Failed to change primary group!"
			exit 2
		}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/setup-user.sh | \
		bash || {
			echo "[ERROR]: Failed to setup current user!"
			exit 2
		}

	echo "[INFO]: Restarting server after 3 seconds..."
	sleep 3
	${_SUDO} shutdown -r now || {
		echo "[ERROR]: Failed to restart server!"
		exit 2
	}

	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
