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

if ! command -v apt >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'apt' command, please install 'apt' package manager!"
	exit 1
fi


_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
fi
## --- Base --- ##


## --- Variables --- ##
ADD_BAD_PROXY_FIX=${ADD_BAD_PROXY_FIX:-true}
CLEAN_CACHE=${CLEAN_CACHE:-true}
DO_APT_UPGRADE=${DO_APT_UPGRADE:-false}
## --- Variables --- ##


## --- Main --- ##
_install_packages()
{
	echo "[INFO]: Updating package lists..."
	${_SUDO} apt-get update --fix-missing -o Acquire::Retries=3 -o Acquire::CompressionTypes::Order::=gz || true
	echo -e "[OK]: Done.\n"

	if [ "${DO_APT_UPGRADE}" = true ]; then
		echo "[INFO]: Upgrading packages..."
		${_SUDO} apt-get upgrade -y -o Acquire::Retries=3 || true
		echo -e "[OK]: Done.\n"
	fi

	echo "[INFO]: Installing essential packages..."
	if ! ${_SUDO} apt-get install -y -o Acquire::Retries=5 \
		sudo \
		ca-certificates \
		systemd \
		apt-utils \
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
		git \
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
		ripgrep \
		watch \
		watchman \
		fzf \
		httpie \
		zsh; then
		echo "[WARN]: 'apt-get install' command failed!"
		return 2
	fi

	${_SUDO} apt-get install -y btop || true
	echo -e "[OK]: Done.\n"
}


main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-b | --disable-bad-proxy-fix)
					ADD_BAD_PROXY_FIX=false
					shift;;
				-c | --disable-clean-cache)
					CLEAN_CACHE=false
					shift;;
				-u | --upgrade | --enable-apt-upgrade)
					DO_APT_UPGRADE=true
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -b, --disable-bad-proxy-fix | -c, --disable-clean-cache | -u, --upgrade, --enable-apt-upgrade"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##

	if [ "${ADD_BAD_PROXY_FIX}" = true ]; then
		echo "Acquire::http::Pipeline-Depth 0;" | ${_SUDO} tee /etc/apt/apt.conf.d/99fixbadproxy >/dev/null || exit 2
		echo "Acquire::http::No-Cache true;" | ${_SUDO} tee -a /etc/apt/apt.conf.d/99fixbadproxy >/dev/null || exit 2
		echo "Acquire::BrokenProxy    true;" | ${_SUDO} tee -a /etc/apt/apt.conf.d/99fixbadproxy >/dev/null || exit 2
	fi

	if [ "${CLEAN_CACHE}" = true ]; then
		echo "[INFO]: Removing and cleaning up apt cache..."
		${_SUDO} apt-get clean || exit 2
		${_SUDO} rm -vrf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* || exit 2
		echo -e "[OK]: Done.\n"
	fi

	local _retry_count=3
	local _retry_delay=3
	local _i=1
	while ! _install_packages; do
		if [ "${_i}" -eq "${_retry_count}" ]; then
			echo "[ERROR]: Package installation failed after ${_retry_count} attempts!"
			exit 2
		fi

		echo "[WARN]: Package installation failed, retrying ${_i}/${_retry_count} after ${_retry_delay} seconds..."
		sleep ${_retry_delay}
		_i=$((_i + 1))
	done

	echo "[INFO]: Autoremoving unused packages..."
	${_SUDO} apt-get autoremove -y || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
