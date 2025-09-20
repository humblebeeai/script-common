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
if [ "${_OS}" != "Linux" ] && [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}'!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
# Essential Go settings:
GO_VERSION=${GO_VERSION:-"1.22.3"}  # Go version to install
GO_INSTALL_DIR=${GO_INSTALL_DIR:-"${HOME}/workspaces/runtimes/go"}  # Go installation directory
## --- Variables --- ##


## --- Main --- ##
get_go_tarball_url()
{
	local _os=""
	local _arch=""

	if [ "${_OS}" = "Linux" ]; then
		_os="linux"
	elif [ "${_OS}" = "Darwin" ]; then
		_os="darwin"
	fi

	_arch="amd64"

	echo "https://go.dev/dl/go${GO_VERSION}.${_os}-${_arch}.tar.gz"
}

main()
{
	echo "[INFO]: Setting up 'Go'..."

	# Check if Go is already installed in the target directory
	if [ -x "${GO_INSTALL_DIR}/bin/go" ]; then
		echo "[INFO]: Go is already installed at ${GO_INSTALL_DIR}"
		"${GO_INSTALL_DIR}/bin/go" version
		echo -e "[OK]: Done.\n"
		return 0
	fi

	# Download Go tarball
	_tarball_url="$(get_go_tarball_url)"
	_tarball_file="/tmp/go${GO_VERSION}.tar.gz"

	echo "[INFO]: Downloading Go ${GO_VERSION} from ${_tarball_url}..."
	wget "${_tarball_url}" -O "${_tarball_file}" || exit 2
	echo -e "[OK]: Downloaded.\n"

	# Remove any previous Go installation in the target directory
	if [ -d "${GO_INSTALL_DIR}" ]; then
		echo "[INFO]: Removing previous Go installation at ${GO_INSTALL_DIR}..."
		rm -rf "${GO_INSTALL_DIR}" || exit 2
	fi

	   echo "[INFO]: Extracting Go to ${GO_INSTALL_DIR}..."
	   mkdir -p "${GO_INSTALL_DIR%/*}" || exit 2
	   tar -C "${GO_INSTALL_DIR%/*}" -xzf "${_tarball_file}" || exit 2
	   # Only move if source and target differ
	   if [ "${GO_INSTALL_DIR%/}" != "${GO_INSTALL_DIR%/*}/go" ]; then
		   mv "${GO_INSTALL_DIR%/*}/go" "${GO_INSTALL_DIR}" || exit 2
	   fi
	   echo -e "[OK]: Installed.\n"

	echo "[INFO]: Cleaning up..."
	rm -f "${_tarball_file}"
	echo -e "[OK]: Done.\n"

	   echo -e "[OK]: 'Go' setup completed successfully!"
	   echo "[INFO]: To use Go, add the following to your shell profile (e.g., ~/.bashrc or ~/.zshrc):"
	   echo "    export PATH=\"${GO_INSTALL_DIR}/bin:\$PATH\""
	   echo "[INFO]: Installed at: ${GO_INSTALL_DIR}"
	   "${GO_INSTALL_DIR}/bin/go" version

	   # Optionally append to shell profile automatically
	   if [ -n "${SHELL:-}" ]; then
		   _profile=""
		   case "${SHELL}" in
			   */zsh) _profile="${HOME}/.zshrc" ;;
			   */bash) _profile="${HOME}/.bashrc" ;;
		   esac
		   if [ -n "${_profile}" ] && [ -w "${_profile}" ]; then
			   if ! grep -q "${GO_INSTALL_DIR}/bin" "${_profile}"; then
				   echo "export PATH=\"${GO_INSTALL_DIR}/bin:\$PATH\"" >> "${_profile}"
				   echo "[OK]: Added Go to PATH in ${_profile}"
				   echo "[INFO]: For the changes to take effect, run: source ${_profile}"
			   fi
		   fi
	   fi
}

main "${@:-}"
## --- Main --- ##