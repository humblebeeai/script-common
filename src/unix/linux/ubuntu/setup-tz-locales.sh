#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
# cd "${_SCRIPT_DIR}" || exit 2


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

if ! command -v dpkg-reconfigure >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'dpkg-reconfigure' command, please install 'dpkg' package!"
	exit 1
fi

if ! command -v update-locale >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'update-locale' command, please install 'locales' package!"
	exit 1
fi

if ! command -v timedatectl >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'timedatectl' command, please install 'tzdata' package!"
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

	if [ -z "${TZ_NAME}" ]; then
		echo "[ERROR]: Timezone name is empty!"
		exit 1
	fi

	if ! timedatectl list-timezones | grep -qx "${TZ_NAME}"; then
		echo "[ERROR] Not found timezone '${TZ_NAME}' in the tzdata!"
		exit 1
	fi


	echo "[INFO]: Setting up timezone to '${TZ_NAME}'..."
	${_SUDO} timedatectl set-timezone "${TZ_NAME}" || exit 2
	${_SUDO} timedatectl set-ntp on || exit 2

	${_SUDO} dpkg-reconfigure -f noninteractive tzdata || exit 2

	timedatectl || exit 2
	date || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Setting up locales..."
	${_SUDO} sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen || exit 2
	${_SUDO} sed -i -e 's/# en_AU.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/' /etc/locale.gen || exit 2
	${_SUDO} sed -i -e 's/# ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen || exit 2

	${_SUDO} dpkg-reconfigure -f noninteractive locales || exit 2
	${_SUDO} update-locale LANG=en_US.UTF-8 LC_ALL=en_AU.UTF-8 || exit 2

	locale || exit 2
	echo -e "[OK]: Done.\n"

}


main "${@:-}"
## --- Main --- ##
