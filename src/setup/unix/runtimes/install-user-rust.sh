#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
# _SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
# cd "${_SCRIPT_DIR}" || exit 2


# shellcheck disable=SC1091
[ -f .env ] && . .env


_OS="$(uname)"
case "${_OS}" in
	Linux | Darwin) : ;;
	*) echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' and 'macOS' are supported!" >&2; exit 1;;
esac

if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' not found or not installed!" >&2
	exit 1
fi

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
RUST_DIR="${RUST_DIR:-${HOME}/workspaces/runtimes/rust}"
CARGO_HOME="${RUST_DIR}/.cargo"
RUSTUP_HOME="${RUST_DIR}/.rustup"
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -d, --install-dir [PATH]    Specify the installation directory for Rust. Default: '~/workspaces/runtimes/rust'
    -h, --help                  Show help.

EXAMPLES:
    ${0} --install-dir ./workspaces/runtimes/rust
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-d | --install-dir)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			RUST_DIR="${2}"
			shift 2;;
		-d=* | --install-dir=*)
			RUST_DIR="${1#*=}"
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
_setup_shell()
{
	if ! grep -Fq "export CARGO_HOME=" "${HOME}/.bashrc"; then
		echo "export CARGO_HOME=\"${CARGO_HOME}\"" >> "${HOME}/.bashrc" || exit 2
		echo "export RUSTUP_HOME=\"${RUSTUP_HOME}\"" >> "${HOME}/.bashrc" || exit 2
		echo ". \"\${CARGO_HOME}/env\"" >> "${HOME}/.bashrc" || exit 2
		echo -e "\n" >> "${HOME}/.bashrc" || exit 2
	fi

	if [ -f "${HOME}/.zshrc" ] && ! grep -Fq "export CARGO_HOME=" "${HOME}/.zshrc"; then
		echo "export CARGO_HOME=\"${CARGO_HOME}\"" >> "${HOME}/.zshrc" || exit 2
		echo "export RUSTUP_HOME=\"${RUSTUP_HOME}\"" >> "${HOME}/.zshrc" || exit 2
		echo ". \"\${CARGO_HOME}/env\"" >> "${HOME}/.zshrc" || exit 2
		echo -e "\n" >> "${HOME}/.zshrc" || exit 2
	fi
}

main()
{
	echo ""
	echo "[INFO]: Installing Rust runtime..."

	if [ -z "${RUST_DIR}" ]; then
		echo "[ERROR]: RUST_DIR variable is empty!" >&2
		exit 1
	fi


	export CARGO_HOME="${RUST_DIR}/.cargo"
	export RUSTUP_HOME="${RUST_DIR}/.rustup"

	if [ -d "${CARGO_HOME}" ] && \
		[ -x "${CARGO_HOME}/bin/rustup" ] && \
		[ -x "${CARGO_HOME}/bin/cargo" ] && \
		[ -x "${CARGO_HOME}/bin/rustc" ]; then
		"${CARGO_HOME}/bin/rustup" -V || exit 2
		"${CARGO_HOME}/bin/cargo" -V || exit 2
		"${CARGO_HOME}/bin/rustc" -V || exit 2
		_setup_shell || exit 2
		echo "[WARN]: Rust is already installed in '${RUST_DIR}', skipping!"
		echo ""
		exit 0
	fi

	echo "[INFO]: Preparing installation..."
	rm -rf "${RUST_DIR}" || exit 2
	mkdir -pv "${RUST_DIR}" || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Downloading and installing Rust..."
	local _retry_count=3
	local _retry_delay=1
	local _i=1
	while ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
		--default-toolchain stable \
		--profile default \
		--no-modify-path -y; do

		if [ "${_i}" -ge "${_retry_count}" ]; then
			echo "[ERROR]: Rust installation failed after ${_retry_count} attempts!" >&2
			exit 2
		fi

		echo "[WARN]: Rust installation failed, retrying ${_i}/${_retry_count} after ${_retry_delay} seconds..." >&2
		sleep ${_retry_delay}
		_i=$((_i + 1))
	done

	_setup_shell || exit 2
	#shellcheck disable=SC1091
	. "${CARGO_HOME}/env" || exit 2

	rustup -V || exit 2
	cargo -V || exit 2
	rustc -V || exit 2
	echo "[OK]: Successfully installed Rust runtime."
	echo ""
}


main "${@:-}"
## --- Main --- ##
