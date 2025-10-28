#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
cd "${_SCRIPT_DIR}" || exit 2


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

_IS_OLD_VERSION_OS=false
#shellcheck disable=SC1091
. /etc/os-release
_OS_DISTRO="${ID,,}"
case "${_OS_DISTRO}" in
	ubuntu | debian | kali)
		_OS_VERSION=$(echo "${VERSION_ID}" | tr -d '"')
		if [ "${_OS_DISTRO}" = "ubuntu" ] && [ "${_OS_VERSION%%.*}" -lt 22 ]; then
			_IS_OLD_VERSION_OS=true
		fi;;
	*) echo "[ERROR]: Unsupported Linux distro '${_OS_DISTRO}', only Ubuntu/Debian are supported!" >&2; exit 1;;
esac

_ARCH="$(uname -m)"
case "${_ARCH}" in
	x86_64 | aarch64 | arm64) : ;;
	*)
		echo "[ERROR]: Unsupported CPU architecture '${_ARCH}', only 'x86_64', 'arm64' and 'aarch64' are supported!" >&2
		exit 1;;
esac

for _cmd in curl getent; do
	if ! command -v "${_cmd}" >/dev/null 2>&1; then
		echo "[ERROR]: Not found '${_cmd}' command, please install it first!" >&2
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
TZ_NAME=${TZ_NAME:-}
NEW_HOSTNAME=${NEW_HOSTNAME:-}
PRIMARY_GID=${PRIMARY_GID:-11000}
UPGRADE_APT_PACKAGES=${UPGRADE_APT_PACKAGES:-false}
SETUP_USER=${SETUP_USER:-true}
RUNTIMES=${RUNTIMES:-conda,nvm}
RESTART_AFTER=${RESTART_AFTER:-true}
SCRIPT_BASE_URL="${SCRIPT_BASE_URL:-https://github.com/humblebeeai/script-common/raw/main/src}"
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -t, --tz, --timezone [TIMEZONE]        Set the system timezone (e.g., 'UTC'). Default: <system-default>
    -n, --hostname [HOSTNAME]              Set the system hostname. Default: <current-hostname>
    -g, --gid, --primary-gid [GID]         Specify the primary GID to set for the users. Default 11000
    -u, --upgrade, --enable-apt-upgrade    Upgrade APT packages during setup. Default: false
    -U, --disable-user-setup               Disable user setup process. Default: false
    -r, --runtimes                         Comma-separated list of runtimes to install ('conda', 'nvm', 'rust', 'go'). Default: 'conda,nvm'.
    -R, --disable-restart                  Disable automatic system restart after setup. Default: false
    -h, --help                             Show help.

EXAMPLES:
    ${0} --upgrade --all
    ${0} -u -a -t="Asia/Seoul" -n="my-server"
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
		-g | --gid | --primary-gid)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			PRIMARY_GID="${2}"
			shift 2;;
		-g=* | --gid=* | --primary-gid=*)
			PRIMARY_GID="${1#*=}"
			shift;;
		-u | --upgrade | --enable-apt-upgrade)
			UPGRADE_APT_PACKAGES=true
			shift;;
		-U | --disable-user-setup)
			SETUP_USER=false
			shift;;
		-r | --runtimes)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			RUNTIMES="${2}"
			shift 2;;
		-r=* | --runtimes=*)
			RUNTIMES="${1#*=}"
			shift;;
		-R | --disable-restart)
			RESTART_AFTER=false
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
	echo "[INFO]: Setting up Ubuntu/Debian..."

	_fetch "${SCRIPT_BASE_URL}/setup/unix/linux/ubuntu/pre-setup-ubuntu.sh" | \
		bash -s -- -t="${TZ_NAME}" -n="${NEW_HOSTNAME}" || {
			echo "[ERROR]: Failed to setup timezone and locales!" >&2
			exit 2
		}

	local _arg_upgrade=""
	if [ "${UPGRADE_APT_PACKAGES}" = true ]; then
		_arg_upgrade="-s -- -u"
	fi
	#shellcheck disable=SC2086
	_fetch "${SCRIPT_BASE_URL}/setup/unix/linux/ubuntu/install-essentials.sh" | \
		bash ${_arg_upgrade} || {
			echo "[ERROR]: Failed to install essential packages!" >&2
			exit 2
		}

	_fetch "${SCRIPT_BASE_URL}/setup/unix/linux/ubuntu/install-recommend.sh" | \
		bash || {
			echo "[ERROR]: Failed to install development tools!" >&2
			exit 2
		}

	if [ "${_IS_OLD_VERSION_OS}" = false ] && [ "${_OS_DISTRO}" != "kali" ]; then
		_fetch "${SCRIPT_BASE_URL}/setup/unix/linux/setup-docker.sh" | \
			bash || {
				echo "[ERROR]: Failed to setup Docker!" >&2
				exit 2
			}
	else
		echo "[WARN]: OS version does not support Docker installation script, skipping!" >&2
		echo "[WARN]: If you need to use Docker, install it manually: https://docs.docker.com/engine/install/ubuntu" >&2
	fi

	if ! getent group "${PRIMARY_GID}" >/dev/null 2>&1; then
		_fetch "${SCRIPT_BASE_URL}/account/unix/linux/create-group.sh" | \
			bash -s -- -g="${PRIMARY_GID}" || {
				echo "[ERROR]: Failed to create new group!" >&2
				exit 2
			}
	fi

	_fetch "${SCRIPT_BASE_URL}/account/unix/linux/change-user-pgroup.sh" | \
		bash -s -- -a -g="${PRIMARY_GID}" || {
			echo "[ERROR]: Failed to change primary group!" >&2
			exit 2
		}

	if [ "${SETUP_USER}" = true ]; then
		_fetch "${SCRIPT_BASE_URL}/setup/unix/linux/setup-user.sh" | \
			bash -s -- -g="${PRIMARY_GID}" -r="${RUNTIMES}" || {
				echo "[ERROR]: Failed to setup current user!" >&2
				exit 2
			}
	fi

	echo "[INFO]: Setting up for root user..."
	_fetch "${SCRIPT_BASE_URL}/setup/unix/setup-user-ohmyzsh.sh" | ${_SUDO} bash || {
		echo "[ERROR]: Failed to install 'oh-my-zsh' for root user!" >&2
		exit 2
	}

	_fetch "${SCRIPT_BASE_URL}/setup/unix/setup-user-configs.sh" | ${_SUDO} bash || {
		echo "[ERROR]: Failed to setup configs for root user!" >&2
		exit 2
	}

	_fetch "${SCRIPT_BASE_URL}/setup/unix/setup-user-nvchad.sh" | ${_SUDO} bash || {
		echo "[ERROR]: Failed to setup 'NvChad' for root user!" >&2
		exit 2
	}
	echo "[OK]: Done."


	if [ "${RESTART_AFTER}" = true ]; then
		echo "[INFO]: Rebooting server after 3 seconds..."
		sleep 3
		${_SUDO} shutdown -r now || {
			echo "[ERROR]: Failed to restart server!" >&2
			exit 2
		}
	else
		echo "[WARN]: Please logout and login again to apply user-level changes!"
		echo "[WARN]: You must restart server later to apply system-level changes!"
	fi
	echo "[OK]: Successfully setup Ubuntu/Debian!"
	echo ""
}

main
## --- Main --- ##
