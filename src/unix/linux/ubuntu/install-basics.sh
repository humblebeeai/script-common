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
	_OS_DISTRO=""
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


_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
fi
## --- Base --- ##


## --- Variables --- ##
APT_UPGRADE=${APT_UPGRADE:-true}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-u | --disable-upgrade)
					APT_UPGRADE=false
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -u | --disable-upgrade"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	echo "[INFO]: Removing and cleaning up apt cache..."
	${_SUDO} apt clean || exit 2
	${_SUDO} rm -vrf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Updating package lists..."
	${_SUDO} apt update --fix-missing -o Acquire::CompressionTypes::Order::=gz || exit 2
	echo -e "[OK]: Done.\n"

	if [ "${APT_UPGRADE}" = true ]; then
		echo "[INFO]: Upgrading packages..."
		${_SUDO} apt upgrade -y || exit 2
		echo -e "[OK]: Done.\n"
	fi

	echo "[INFO]: Installing basic packages..."
	${_SUDO} apt install -y \
		sudo \
		adduser \
		ca-certificates \
		build-essential \
		cmake \
		tzdata \
		locales \
		iputils-ping \
		net-tools \
		iproute2 \
		wget \
		curl \
		ssh \
		git-lfs \
		rsync \
		unzip \
		zip \
		tmux \
		vim \
		nano \
		jq \
		htop \
		ncdu \
		pydf \
		tree \
		less \
		watch \
		watchman \
		bash \
		zsh || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Autoremoving unused packages..."
	${_SUDO} apt autoremove -y || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
