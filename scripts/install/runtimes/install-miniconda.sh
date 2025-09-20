#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# cd "${_SCRIPT_DIR}" || exit 2


if ! command -v wget >/dev/null 2>&1; then
	echo "[ERROR]: 'wget' not found or not installed!"
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
# Essential Miniconda settings:
MINICONDA_INSTALL_DIR=${MINICONDA_INSTALL_DIR:-"${HOME}/workspaces/runtimes/miniconda3"}  # Installation directory
MINICONDA_AUTO_ACTIVATE=${MINICONDA_AUTO_ACTIVATE:-"no"}         # Auto-activate base environment (yes/no)
MINICONDA_CREATE_ENV=${MINICONDA_CREATE_ENV:-"yes"}              # Create custom environment (yes/no)
MINICONDA_PYTHON_VERSION=${MINICONDA_PYTHON_VERSION:-"3.11"}    # Python version for custom environment
## --- Variables --- ##


## --- Main --- ##
get_miniconda_installer_url()
{
	local _installer_name=""

	if [ "${_OS}" = "Linux" ]; then
		_installer_name="Miniconda3-latest-Linux-x86_64.sh"
	elif [ "${_OS}" = "Darwin" ]; then
		_installer_name="Miniconda3-latest-MacOSX-x86_64.sh"
	fi

	echo "https://repo.anaconda.com/miniconda/${_installer_name}"
}

get_env_name()
{
	local _python_version="${1}"
	# Extract major and minor version numbers and create env name
	local _major_minor
	_major_minor=$(echo "${_python_version}" | sed 's/\.//g' | cut -c1-3)
	echo "py${_major_minor}"
}

main()
{
	echo "[INFO]: Setting up 'Miniconda'..."

	# Check if Miniconda is already installed
	if [ -d "${MINICONDA_INSTALL_DIR}" ] && [ -f "${MINICONDA_INSTALL_DIR}/bin/conda" ]; then
		echo "[INFO]: Miniconda is already installed at ${MINICONDA_INSTALL_DIR}"
		echo "[INFO]: Updating existing installation..."
		"${MINICONDA_INSTALL_DIR}/bin/conda" update -n base -c defaults conda -y || exit 2
		echo -e "[OK]: Done.\n"
	else
		# Download and install Miniconda
		_installer_url="$(get_miniconda_installer_url)"
		_installer_file="/tmp/miniconda-installer.sh"

		echo "[INFO]: Downloading Miniconda installer..."
		wget "${_installer_url}" -O "${_installer_file}" || exit 2

		echo "[INFO]: Installing Miniconda to ${MINICONDA_INSTALL_DIR}..."
		bash "${_installer_file}" -b -p "${MINICONDA_INSTALL_DIR}" || exit 2
		rm -f "${_installer_file}"
		echo -e "[OK]: Done.\n"

		# Initialize conda for shell (always enabled for new installations)
		echo "[INFO]: Initializing conda for shell..."
		if [ "${_OS}" = "Darwin" ]; then
			# On macOS, prioritize zsh initialization as it's the default shell
			if command -v zsh >/dev/null 2>&1; then
				"${MINICONDA_INSTALL_DIR}/bin/conda" init zsh || exit 2
			fi
			"${MINICONDA_INSTALL_DIR}/bin/conda" init bash || exit 2
		else
			# On Linux, initialize bash first, then zsh if available
			"${MINICONDA_INSTALL_DIR}/bin/conda" init bash || exit 2
			if command -v zsh >/dev/null 2>&1; then
				"${MINICONDA_INSTALL_DIR}/bin/conda" init zsh || exit 2
			fi
		fi
		echo -e "[OK]: Done.\n"
	fi

	# Configure auto-activate base environment
	echo "[INFO]: Configuring conda settings..."
	if [ "${MINICONDA_AUTO_ACTIVATE}" = "no" ]; then
		"${MINICONDA_INSTALL_DIR}/bin/conda" config --set auto_activate false || exit 2
	else
		"${MINICONDA_INSTALL_DIR}/bin/conda" config --set auto_activate true || exit 2
	fi

	# Add conda-forge channel (commonly used) - only if not already present
	if ! "${MINICONDA_INSTALL_DIR}/bin/conda" config --show channels | grep -q "^  - conda-forge$"; then
		"${MINICONDA_INSTALL_DIR}/bin/conda" config --add channels conda-forge || exit 2
	fi
	echo -e "[OK]: Done.\n"

	# Create custom environment if requested
	if [ "${MINICONDA_CREATE_ENV}" = "yes" ]; then
		_env_name="$(get_env_name "${MINICONDA_PYTHON_VERSION}")"
		echo "[INFO]: Creating conda environment '${_env_name}' with Python ${MINICONDA_PYTHON_VERSION}..."

		# Accept conda terms of service for required channels
		echo "[INFO]: Accepting conda terms of service..."
		"${MINICONDA_INSTALL_DIR}/bin/conda" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main || exit 2
		"${MINICONDA_INSTALL_DIR}/bin/conda" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r || exit 2
		echo -e "[OK]: Done.\n"

		"${MINICONDA_INSTALL_DIR}/bin/conda" create -n "${_env_name}" python="${MINICONDA_PYTHON_VERSION}" -y || exit 2
		echo -e "[OK]: Done.\n"

		# Configure auto-activation of custom environment
		echo "[INFO]: Configuring auto-activation of '${_env_name}' environment..."
		if [ ! -f "${HOME}/.bashrc" ] || ! grep -q "conda activate ${_env_name}" "${HOME}/.bashrc"; then
			echo "conda activate ${_env_name}" >> "${HOME}/.bashrc" || exit 2
		fi
		if command -v zsh >/dev/null 2>&1 && [ -f "${HOME}/.zshrc" ]; then
			if ! grep -q "conda activate ${_env_name}" "${HOME}/.zshrc"; then
				echo "conda activate ${_env_name}" >> "${HOME}/.zshrc" || exit 2
			fi
		fi
		echo -e "[OK]: Done.\n"
	fi

	echo -e "[OK]: 'Miniconda' setup completed successfully!"
	echo "[INFO]: Restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc) to use conda."
	if [ "${MINICONDA_CREATE_ENV}" = "yes" ]; then
		_env_name="$(get_env_name "${MINICONDA_PYTHON_VERSION}")"
		echo "[INFO]: Custom environment '${_env_name}' created and configured for auto-activation."
	fi
	echo "[INFO]: Installed at: ${MINICONDA_INSTALL_DIR}"
}

main "${@:-}"
## --- Main --- ##
