#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# cd "${_SCRIPT_DIR}" || exit 2


if ! command -v apt-get >/dev/null 2>&1 && ! command -v brew >/dev/null 2>&1; then
	echo "[ERROR]: Neither 'apt-get' nor 'brew' found! Only Ubuntu/Debian and macOS are supported."
	exit 1
fi


# Loading .env file:
if [ -r .env ]; then
	# shellcheck disable=SC1091
	. .env
fi

_OS="$(uname)"
_OS_DISTRO=""
if [ "${_OS}" = "Linux" ]; then
	_OS_DISTRO=""
	if [ -r /etc/os-release ]; then
		# shellcheck disable=SC1091
		_OS_DISTRO="$(. /etc/os-release && echo "${ID}")"
		_OS_DISTRO="$(echo "${_OS_DISTRO}" | tr '[:upper:]' '[:lower:]')"

		if [ "${_OS_DISTRO}" != "ubuntu" ] && [ "${_OS_DISTRO}" != "debian" ]; then
			echo "[ERROR]: Unsupported Linux distro '${_OS_DISTRO}', only 'Ubuntu' and 'Debian' are supported!"
			exit 1
		fi
	else
		echo "[ERROR]: Unable to determine Linux distro!"
		exit 1
	fi
elif [ "${_OS}" = "Darwin" ]; then
	_OS_DISTRO="macos"
else
	echo "[ERROR]: Unsupported OS '${_OS}'!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
# No configurable variables - categories are passed as command-line arguments
## --- Variables --- ##


## --- Main --- ##
get_package_manager()
{
	if [ "${_OS}" = "Darwin" ]; then
		echo "brew"
	else
		echo "apt-get"
	fi
}

install_packages()
{
	local _category="${1}"
	local _packages="${2}"
	local _pkg_mgr
	_pkg_mgr="$(get_package_manager)"

	echo "[INFO]: Installing ${_category} packages..."

	if [ "${_pkg_mgr}" = "apt-get" ]; then
		# Install packages (no update here since base handles it, or individual categories don't need frequent updates)
		# shellcheck disable=SC2086
		sudo apt-get install -y ${_packages} || exit 2
	elif [ "${_pkg_mgr}" = "brew" ]; then
		# Install packages
		# shellcheck disable=SC2086
		brew install ${_packages} || exit 2
	fi

	echo -e "[OK]: ${_category} packages installed.\n"
}

install_base_packages()
{
	local _pkg_mgr
	_pkg_mgr="$(get_package_manager)"

	# Update package manager first
	echo "[INFO]: Updating package manager..."
	if [ "${_pkg_mgr}" = "apt-get" ]; then
		sudo apt-get update -qq || exit 2
	elif [ "${_pkg_mgr}" = "brew" ]; then
		brew update || exit 2
	fi
	echo -e "[OK]: Package manager updated.\n"

	if [ "${_OS}" = "Darwin" ]; then
		_packages="curl wget git vim htop rsync screen tmux ncdu"
	else
		_packages="curl wget git vim htop rsync screen tmux ncdu build-essential"
	fi

	install_packages "Base System" "${_packages}"
}

install_monitoring_packages()
{
	if [ "${_OS}" = "Darwin" ]; then
		_packages="lsof strace dstat pv moreutils"
	else
		_packages="lsof strace iotop iftop bmon dstat sysstat pv moreutils"
	fi

	install_packages "Monitoring & Performance" "${_packages}"
}

install_networking_packages()
{
	if [ "${_OS}" = "Darwin" ]; then
		_packages="bind nmap mtr socat tcpdump whois"
	else
		_packages="dnsutils nmap mtr-tiny traceroute socat tcpdump whois"
	fi

	install_packages "Networking & Diagnostics" "${_packages}"
}

install_compression_packages()
{
	if [ "${_OS}" = "Darwin" ]; then
		_packages="zip unzip p7zip xz pigz"
	else
		_packages="zip unzip p7zip-full xz-utils pigz"
	fi

	install_packages "Compression & Archiving" "${_packages}"
}

install_development_packages()
{
	if [ "${_OS}" = "Darwin" ]; then
		_packages="cmake pkg-config gnupg openssl"
	else
		_packages="cmake pkg-config gpg openssl"
	fi

	install_packages "Development Tools" "${_packages}"
}

install_file_utils_packages()
{
	if [ "${_OS}" = "Darwin" ]; then
		_packages="tree fd ripgrep jq yq"
	else
		_packages="tree fd-find ripgrep jq yq"
	fi

	install_packages "File & Search Utilities" "${_packages}"
}

install_productivity_packages()
{
	_packages="fzf bat eza tldr"

	install_packages "CLI Productivity & UX" "${_packages}"
}

is_valid_category()
{
	local _category="${1}"
	case "${_category}" in
		base|monitoring|networking|compression|development|file-utils|productivity)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

install_category()
{
	local _category="${1}"

	case "${_category}" in
		base)
			install_base_packages
			;;
		monitoring)
			install_monitoring_packages
			;;
		networking)
			install_networking_packages
			;;
		compression)
			install_compression_packages
			;;
		development)
			install_development_packages
			;;
		file-utils)
			install_file_utils_packages
			;;
		productivity)
			install_productivity_packages
			;;
		*)
			echo "[ERROR]: Unknown category '${_category}'"
			echo "[INFO]: Available categories: base, monitoring, networking, compression, development, file-utils, productivity"
			exit 2
			;;
	esac
}

main()
{
	echo "[INFO]: Setting up 'Essential System Binaries'..."
	echo "[INFO]: OS: ${_OS} (${_OS_DISTRO})"

	# Parse command-line arguments for categories to install
	local _categories_to_install=()

	if [ $# -eq 0 ]; then
		# No arguments provided, use default
		_categories_to_install=("base")
		echo "[INFO]: No categories specified, installing default: base"
	else
		# Validate all provided categories first, skipping empty arguments
		for _arg in "${@}"; do
			# Skip empty arguments
			if [ -z "${_arg}" ]; then
				continue
			fi
			if ! is_valid_category "${_arg}"; then
				echo "[ERROR]: Invalid category '${_arg}'"
				echo "[INFO]: Available categories: base, monitoring, networking, compression, development, file-utils, productivity"
				exit 2
			fi
		done

		# All categories are valid, add them to install list (skip empty args)
		for _arg in "${@}"; do
			if [ -n "${_arg}" ]; then
				_categories_to_install+=("${_arg}")
			fi
		done

		# Check if we have any valid categories after filtering
		if [ ${#_categories_to_install[@]} -eq 0 ]; then
			echo "[INFO]: No valid categories provided, installing default: base"
			_categories_to_install=("base")
		else
			echo "[INFO]: Installing categories: ${_categories_to_install[*]}"
		fi
	fi

	# Install each requested category
	for _category in "${_categories_to_install[@]}"; do
		install_category "${_category}"
	done

	echo -e "[OK]: 'Essential System Binaries' setup completed successfully!"
	echo "[INFO]: Installed categories: ${_categories_to_install[*]}"
	echo "[INFO]: Available categories: base, monitoring, networking, compression, development, file-utils, productivity"
}

main "${@:-}"
## --- Main --- ##
