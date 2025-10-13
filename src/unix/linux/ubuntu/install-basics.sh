#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
# cd "${_SCRIPT_DIR}" || exit 2

pwd

echo "${_SCRIPT_DIR}"


# Loading .env file (if exists):
if [ -f ".env" ]; then
	# shellcheck disable=SC1091
	source .env
fi


_OS="$(uname)"
_OS_DISTRO=""
_SUDO="sudo"
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

	if [ "$(id -u)" -eq 0 ]; then
		_SUDO=""
	fi
else
	echo "[ERROR]: Unsupported OS '${_OS}'!"
	exit 1
fi
## --- Base --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Updating package lists and upgrading existing packages..."
	${_SUDO} apt update --fix-missing -o Acquire::CompressionTypes::Order::=gz || exit 2
	${_SUDO} apt upgrade -y || exit 2
	echo -e "[OK]: Done.\n"

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
		bash \
		zsh || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Cleaning up..."
	${_SUDO} apt autoremove -y || exit 2
	${_SUDO} apt clean || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
