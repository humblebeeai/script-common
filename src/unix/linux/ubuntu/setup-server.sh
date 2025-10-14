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

if ! command -v wget >/dev/null 2>&1; then
	echo "[ERROR]: 'wget' not found or not installed!"
	exit 1
fi


_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
fi
## --- Base --- ##



## --- Main --- ##
main()
{
	echo "[INFO]: Setting up server..."

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/ubuntu/setup-tz-locales.sh | \
		bash || {
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

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/create-group.sh | \
		bash || {
			echo "[ERROR]: Failed to create group!"
			exit 2
		}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/refs/heads/main/src/unix/linux/change-primary-group.sh | \
		bash -s -- -a || {
			echo "[ERROR]: Failed to change primary group!"
			exit 2
		}

	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
