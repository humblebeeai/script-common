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
TZ_NAME=${TZ_NAME:-}
NEW_HOSTNAME=${NEW_HOSTNAME:-}
DO_APT_UPGRADE=${DO_APT_UPGRADE:-false}
DO_USER_SETUP=${DO_USER_SETUP:-true}
ALL_RUNTIMES=${ALL_RUNTIMES:-false}
DO_REBOOT=${DO_REBOOT:-true}
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
				-n=* | --hostname=*)
					NEW_HOSTNAME="${_input#*=}"
					shift;;
				-u | --upgrade | --enable-apt-upgrade)
					DO_APT_UPGRADE=true
					shift;;
				-d | --disable-user-setup)
					DO_USER_SETUP=false
					shift;;
				-a | --install-all-runtimes)
					ALL_RUNTIMES=true
					shift;;
				-r | --disable-reboot)
					DO_REBOOT=false
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -t=*, --tz=*, --timezone=* | -n=*, --hostname=* | -u, --upgrade, --enable-apt-upgrade | -d, --disable-user-setup | -a, --install-all-runtimes | -r, --disable-reboot"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	echo "[INFO]: Setting up Ubuntu/Debian..."
	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/ubuntu/pre-setup-ubuntu.sh | \
		bash -s -- -t="${TZ_NAME}" -n="${NEW_HOSTNAME}" || {
			echo "[ERROR]: Failed to setup timezone and locales!"
			exit 2
		}

	local _arg_upgrade=""
	if [ "${DO_APT_UPGRADE}" = true ]; then
		_arg_upgrade="-s -- -u"
	fi
	#shellcheck disable=SC2086
	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/ubuntu/install-essentials.sh | \
		bash ${_arg_upgrade} || {
			echo "[ERROR]: Failed to install basic packages!"
			exit 2
		}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/ubuntu/install-recommend.sh | \
		bash || {
			echo "[ERROR]: Failed to install development tools!"
			exit 2
		}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/setup-docker.sh | \
		bash || {
			echo "[ERROR]: Failed to setup Docker!"
			exit 2
		}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/account/unix/linux/change-user-pgroup.sh | \
		bash -s -- -a || {
			echo "[ERROR]: Failed to change primary group!"
			exit 2
		}

	if [ "${DO_USER_SETUP}" = true ]; then
		local _arg_all_runtimes=""
		if [ "${ALL_RUNTIMES}" = true ]; then
			_arg_all_runtimes="-s -- -a"
		fi
		#shellcheck disable=SC2086
		curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/setup-user.sh | \
			bash ${_arg_all_runtimes} || {
				echo "[ERROR]: Failed to setup current user!"
				exit 2
			}
	fi

	echo "[INFO]: Setting up for root user..."
	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/setup-user-ohmyzsh.sh | ${_SUDO} bash || {
		echo "[ERROR]: Failed to install 'oh-my-zsh' for root user!"
		exit 2
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/setup-user-shell.sh | ${_SUDO} bash || {
		echo "[ERROR]: Failed to setup shells for root user!"
		exit 2
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/setup-user-nvchad.sh | ${_SUDO} bash || {
		echo "[ERROR]: Failed to setup 'NvChad' for root user!"
		exit 2
	}

	curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/post-setup-user.sh | ${_SUDO} bash || {
		echo "[ERROR]: Failed to setup extra configs for root user!"
		exit 2
	}
	echo -e "[OK]: Done.\n"


	if [ "${DO_REBOOT}" = true ]; then
		echo "[INFO]: Rebooting server after 3 seconds..."
		sleep 3
		${_SUDO} shutdown -r now || {
			echo "[ERROR]: Failed to reboot server!"
			exit 2
		}
	else
		echo "[WARN]: Please logout or exit from the current session and login or enter again to apply user-related changes!"
		echo "[WARN]: You must reboot the server later to apply all system-related changes!"
	fi
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
