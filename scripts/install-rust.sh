#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# cd "${_SCRIPT_DIR}" || exit 2


if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' not found or not installed!"
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
# Essential Rust settings:
RUST_INSTALL_DIR=${RUST_INSTALL_DIR:-"${HOME}/workspaces/runtimes/.cargo"}  # Rust/Cargo installation directory
RUST_TOOLCHAIN=${RUST_TOOLCHAIN:-"stable"}             # Rust toolchain (stable/beta/nightly)
RUST_PROFILE=${RUST_PROFILE:-"default"}               # Install profile (minimal/default/complete)
## --- Variables --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Setting up 'Rust'..."

	# Check if Rust is already installed
	if [ -x "${RUST_INSTALL_DIR}/bin/rustc" ]; then
		echo "[INFO]: Rust is already installed at ${RUST_INSTALL_DIR}"
		"${RUST_INSTALL_DIR}/bin/rustc" --version
		echo -e "[OK]: Done.\n"
		return 0
	fi

	# Download and install Rust via rustup
	echo "[INFO]: Downloading and installing Rust ${RUST_TOOLCHAIN} (${RUST_PROFILE} profile)..."
	
	# Set environment variables for rustup installation
	export CARGO_HOME="${RUST_INSTALL_DIR}"
	export RUSTUP_HOME="${RUST_INSTALL_DIR}/rustup"
	
	# Download and run rustup installer
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
		--default-toolchain "${RUST_TOOLCHAIN}" \
		--profile "${RUST_PROFILE}" \
		--no-modify-path \
		-y || exit 2
	echo -e "[OK]: Installed.\n"

	echo -e "[OK]: 'Rust' setup completed successfully!"
	echo "[INFO]: To use Rust, add the following to your shell profile (e.g., ~/.bashrc or ~/.zshrc):"
	echo "    export PATH=\"${RUST_INSTALL_DIR}/bin:\$PATH\""
	echo "[INFO]: Installed at: ${RUST_INSTALL_DIR}"
	"${RUST_INSTALL_DIR}/bin/rustc" --version
	"${RUST_INSTALL_DIR}/bin/cargo" --version

	# Optionally append to shell profile automatically
	if [ -n "${SHELL:-}" ]; then
		_profile=""
		case "${SHELL}" in
			*/zsh) _profile="${HOME}/.zshrc" ;;
			*/bash) _profile="${HOME}/.bashrc" ;;
		esac
		if [ -n "${_profile}" ] && [ -w "${_profile}" ]; then
			if ! grep -q "${RUST_INSTALL_DIR}/bin" "${_profile}"; then
				echo "export PATH=\"${RUST_INSTALL_DIR}/bin:\$PATH\"" >> "${_profile}"
				echo "[OK]: Added Rust to PATH in ${_profile}"
				echo "[INFO]: Run 'source ${_profile}' or restart your terminal to use Rust immediately."
			fi
		fi
	fi
}

main "${@:-}"
## --- Main --- ##