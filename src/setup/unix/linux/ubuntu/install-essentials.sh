#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
# _SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
# cd "${_SCRIPT_DIR}" || exit 2


# shellcheck disable=SC1091
[ -f .env ] && . .env


_OS="$(uname)"
if [ "${_OS}" != "Linux" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only Linux is supported!" >&2
	exit 1
fi

if [ ! -r /etc/os-release ]; then
	echo "[ERROR]: Unable to determine Linux distro (missing /etc/os-release)!" >&2
	exit 1
fi

#shellcheck disable=SC1091
. /etc/os-release
_OS_DISTRO="${ID,,}"
case "${_OS_DISTRO}" in
	ubuntu | debian | kali) : ;;
	*) echo "[ERROR]: Unsupported Linux distro '${_OS_DISTRO}', only Ubuntu/Debian are supported!" >&2; exit 1;;
esac

if ! command -v apt-get >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'apt-get' command, please install 'apt' package manager!" >&2
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
ADD_BAD_PROXY_FIX=${ADD_BAD_PROXY_FIX:-true}
CLEAN_CACHE=${CLEAN_CACHE:-true}
UPGRADE_APT_PACKAGES=${UPGRADE_APT_PACKAGES:-false}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -b, --disable-bad-proxy-fix            Do not add bad proxy fix config for apt. Default: true
    -c, --disable-clean-cache              Do not clean apt cache before installation. Default: true
    -u, --upgrade, --enable-apt-upgrade    Enable apt package upgrade before installation. Default: false
    -h, --help                             Show help.

EXAMPLES:
    ${0} -u
    ${0} --disable-bad-proxy-fix --disable-clean-cache
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-b | --disable-bad-proxy-fix)
			ADD_BAD_PROXY_FIX=false
			shift;;
		-c | --disable-clean-cache)
			CLEAN_CACHE=false
			shift;;
		-u | --upgrade | --enable-apt-upgrade)
			UPGRADE_APT_PACKAGES=true
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
_install_packages()
{
	echo "[INFO]: Updating package lists..."
	${_SUDO} apt-get update --fix-missing -o Acquire::Retries=3 -o Acquire::CompressionTypes::Order::=gz || true
	echo "[OK]: Done."

	if [ "${UPGRADE_APT_PACKAGES}" = true ]; then
		echo "[INFO]: Upgrading packages..."
		${_SUDO} DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get upgrade -y \
			-o Dpkg::Options::="--force-confdef" \
			-o Dpkg::Options::="--force-confold" \
			-o Acquire::Retries=3 || true
		echo "[OK]: Done."
	fi

	echo "[INFO]: Installing essential packages..."
	if ! ${_SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y \
		-o Acquire::Retries=5 \
		-o Dpkg::Options::="--force-confdef" \
		-o Dpkg::Options::="--force-confold" \
		sudo \
		ca-certificates \
		systemd \
		apt-utils \
		adduser \
		passwd \
		build-essential \
		cmake \
		gpg \
		tzdata \
		locales \
		iputils-ping \
		net-tools \
		iproute2 \
		wget \
		curl \
		ssh \
		git \
		rsync \
		tmux \
		vim \
		nano \
		jq \
		tree \
		ripgrep \
		zsh; then
		echo "[WARN]: 'apt-get install' command failed!" >&2
		return 2
	fi
	echo "[OK]: Done."

	echo "[INFO]: Installing additional packages..."
	${_SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y \
		-o Acquire::Retries=3 \
		-o Dpkg::Options::="--force-confdef" \
		-o Dpkg::Options::="--force-confold" \
		less \
		watch \
		unzip \
		zip \
		git-lfs \
		htop \
		ncdu \
		pydf \
		fzf \
		httpie || true

	${_SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
		-o Dpkg::Options::="--force-confdef" \
		-o Dpkg::Options::="--force-confold" \
		btop || true
	echo "[OK]: Done."
}

main()
{
	echo ""
	echo "[INFO]: Installing essential packages for Ubuntu/Debian..."

	if [ "${ADD_BAD_PROXY_FIX}" = true ]; then
		echo "Acquire::http::Pipeline-Depth 0;" | ${_SUDO} tee /etc/apt/apt.conf.d/99fixbadproxy >/dev/null || exit 2
		echo "Acquire::http::No-Cache true;" | ${_SUDO} tee -a /etc/apt/apt.conf.d/99fixbadproxy >/dev/null || exit 2
		echo "Acquire::BrokenProxy    true;" | ${_SUDO} tee -a /etc/apt/apt.conf.d/99fixbadproxy >/dev/null || exit 2
	fi

	if [ "${CLEAN_CACHE}" = true ]; then
		echo "[INFO]: Removing and cleaning up apt cache..."
		${_SUDO} apt-get clean || exit 2
		${_SUDO} rm -rfv /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* || exit 2
		echo "[OK]: Done."
	fi

	local _retry_count=3
	local _retry_delay=3
	local _i=1
	while ! _install_packages; do
		if [ "${_i}" -ge "${_retry_count}" ]; then
			echo "[ERROR]: Package installation failed after ${_retry_count} attempts!" >&2
			exit 2
		fi

		echo "[WARN]: Package installation failed, retrying ${_i}/${_retry_count} after ${_retry_delay} seconds..." >&2
		sleep ${_retry_delay}
		_i=$((_i + 1))
	done

	echo "[INFO]: Autoremoving unused packages..."
	${_SUDO} apt-get autoremove -y || exit 2
	echo "[OK]: Done."

	echo "[OK]: Successfully installed essential packages for Ubuntu/Debian!"
	echo ""
}

main
## --- Main --- ##
