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
if [ "${_OS}" != "Linux" ] && [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' and 'macOS' are supported!"
	exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' not found or not installed!"
	exit 1
fi

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!"
	exit 2
fi
## --- Base --- ##


## --- Variables --- ##
RUST_DIR=${RUST_DIR:-"${HOME}/workspaces/runtimes/rust"}
CARGO_HOME="${RUST_DIR}/.cargo"
RUSTUP_HOME="${RUST_DIR}/.rustup"
## --- Variables --- ##


## --- Main --- ##
_setup_shellrc()
{
	if ! grep -q "export CARGO_HOME=" "${HOME}/.bashrc"; then
		echo "export CARGO_HOME=\"${CARGO_HOME}\"" >> "${HOME}/.bashrc" || exit 2
		echo "export RUSTUP_HOME=\"${RUSTUP_HOME}\"" >> "${HOME}/.bashrc" || exit 2
		echo "source \"\${CARGO_HOME}/env\"" >> "${HOME}/.bashrc" || exit 2
		echo -e "\n" >> "${HOME}/.bashrc" || exit 2
	fi

	if [ -f "${HOME}/.zshrc" ] && ! grep -q "export CARGO_HOME=" "${HOME}/.zshrc"; then
		echo "export CARGO_HOME=\"${CARGO_HOME}\"" >> "${HOME}/.zshrc" || exit 2
		echo "export RUSTUP_HOME=\"${RUSTUP_HOME}\"" >> "${HOME}/.zshrc" || exit 2
		echo "source \"\${CARGO_HOME}/env\"" >> "${HOME}/.zshrc" || exit 2
		echo -e "\n" >> "${HOME}/.zshrc" || exit 2
	fi
}

main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-i=* | --install-dir=*)
					RUST_DIR="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -i=*, --install-dir=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -z "${RUST_DIR}" ]; then
		echo "[ERROR]: RUST_DIR variable is empty!"
		exit 2
	fi

	CARGO_HOME="${RUST_DIR}/.cargo"
	RUSTUP_HOME="${RUST_DIR}/.rustup"
	if [ -d "${CARGO_HOME}" ] && [ -x "${CARGO_HOME}/bin/rustup" ]; then
		echo "[INFO]: Rust is already installed in '${RUST_DIR}'."
		_setup_shellrc || exit 2
		exit 0
	fi

	echo "[INFO]: Installing Rust in '${RUST_DIR}'..."
	export CARGO_HOME="${CARGO_HOME}"
	export RUSTUP_HOME="${RUSTUP_HOME}"
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
		--default-toolchain stable \
		--profile default \
		--no-modify-path \
		-y || exit 2

	_setup_shellrc || exit 2
	#shellcheck disable=SC1091
	source "${CARGO_HOME}/env" || exit 2

	rustup -V || exit 2
	cargo -V || exit 2
	rustc -V || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
