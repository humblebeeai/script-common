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
	echo "[ERROR]: Not found 'apt-get' command, please check your system configs or 'PATH' environment variable!" >&2
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
TZ_NAME=${TZ_NAME:-}
NEW_HOSTNAME=${NEW_HOSTNAME:-}

_USER_UMASK=$(cat <<'EOF'

if [ "$(id -u)" -ge 1000 ]; then
	umask 002
fi
EOF
)
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -t, --tz, --timezone [TIMEZONE]        Set the system timezone (e.g., 'UTC'). Default: <system-default>
    -n, --hostname [HOSTNAME]              Set the system hostname. Default: <current-hostname>
    -h, --help                             Show help.

EXAMPLES:
    ${0} --tz="UTC" --hostname="my-server"
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-t | --tz | --timezone)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			TZ_NAME="${2}"
			shift 2;;
		-t=* | --tz=* | --timezone=*)
			TZ_NAME="${1#*=}"
			shift;;
		-n | --hostname)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			NEW_HOSTNAME="${2}"
			shift 2;;
		-n=* | --hostname=*)
			NEW_HOSTNAME="${1#*=}"
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
	echo "[INFO]: Running pre-setup for Ubuntu/Debian..."

	echo "[INFO]: Disabling automatic updates and upgrades..."
	if [ ! -d "/etc/apt/apt.conf.d" ]; then
		${_SUDO} mkdir -vp "/etc/apt/apt.conf.d" || exit 2
	fi
	echo 'APT::Periodic::Update-Package-Lists "0";' | ${_SUDO} tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null || exit 2
	echo 'APT::Periodic::Unattended-Upgrade "0";' | ${_SUDO} tee -a /etc/apt/apt.conf.d/20auto-upgrades >/dev/null || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Installing important base packages..."
	${_SUDO} apt-get update || true

	local _retry_count=3
	local _retry_delay=3
	local _i=1
	while ! ${_SUDO} DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get install -y debconf systemd locales tzdata; do
		if [ "${_i}" -ge "${_retry_count}" ]; then
			echo "[ERROR]: Package installation failed after ${_retry_count} attempts!" >&2
			exit 2
		fi

		echo "[WARN]: Package installation failed, retrying ${_i}/${_retry_count} after ${_retry_delay} seconds..." >&2
		sleep ${_retry_delay}
		_i=$((_i + 1))
	done
	echo "[OK]: Done."

	if [ -n "${NEW_HOSTNAME}" ]; then
		echo "[INFO]: Setting up hostname..."
		${_SUDO} hostnamectl set-hostname "${NEW_HOSTNAME}" || exit 2
		${_SUDO} sed -i "s/127.0.1.1.*/127.0.1.1 ${NEW_HOSTNAME}/" /etc/hosts || exit 2
		echo "[OK]: Done."
	fi

	if [ -n "${TZ_NAME}" ]; then
		echo "[INFO]: Setting up timezone to '${TZ_NAME}'..."
		if [ ! -e "/usr/share/zoneinfo/${TZ_NAME}" ]; then
			echo "[ERROR] Timezone '${TZ_NAME}' not found in '/usr/share/zoneinfo/*'!" >&2
			exit 1
		fi

		${_SUDO} timedatectl set-timezone "${TZ_NAME}" || exit 2
		${_SUDO} timedatectl set-ntp on || exit 2
		${_SUDO} dpkg-reconfigure -f noninteractive tzdata || exit 2

		timedatectl || exit 2
		echo "[OK]: Done."
	fi

	echo "[INFO]: Setting up locales..."
	${_SUDO} sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen || exit 2
	${_SUDO} sed -i -e 's/# en_AU.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/' /etc/locale.gen || exit 2
	${_SUDO} sed -i -e 's/# ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen || exit 2

	${_SUDO} dpkg-reconfigure -f noninteractive locales || exit 2
	${_SUDO} update-locale LANG=en_US.UTF-8 LC_ALL=en_AU.UTF-8 || exit 2

	locale || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Setting up user umask for non-root users..."
	if [ -f "/etc/profile" ] && ! grep -Fq "umask" /etc/profile; then
		echo "${_USER_UMASK}" | ${_SUDO} tee -a /etc/profile >/dev/null || exit 2
	fi

	if [ -f "/etc/bash.bashrc" ] && ! grep -Fq "umask" /etc/bash.bashrc; then
		echo "${_USER_UMASK}" | ${_SUDO} tee -a /etc/bash.bashrc >/dev/null || exit 2
	fi
	echo "[OK]: Done."

	echo "[OK]: Successfully run pre-setup for Ubuntu/Debian."
	echo ""
}

main
## --- Main --- ##
