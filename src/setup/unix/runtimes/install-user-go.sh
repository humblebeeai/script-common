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
GO_DIR=${GO_DIR:-"${HOME}/workspaces/runtimes/go"}
GO_VERSION=${GO_VERSION:-"1.25.3"}
## --- Variables --- ##


## --- Main --- ##
_setup_shell()
{
	if ! grep -q "export PATH=\"${GO_DIR}/go/bin:" "${HOME}/.bashrc"; then
		echo -e "export PATH=\"${GO_DIR}/go/bin:\${PATH}\"\n" >> "${HOME}/.bashrc" || exit 2
	fi

	if [ -f "${HOME}/.zshrc" ] && ! grep -q "export PATH=\"${GO_DIR}/go/bin:" "${HOME}/.zshrc"; then
		echo -e "export PATH=\"${GO_DIR}/go/bin:\${PATH}\"\n" >> "${HOME}/.zshrc" || exit 2
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
					GO_DIR="${_input#*=}"
					shift;;
				-v=* | --go-version=*)
					GO_VERSION="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -i=*, --install-dir=* |  -v=*, --go-version=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -z "${GO_DIR}" ]; then
		echo "[ERROR]: GO_DIR variable is empty!"
		exit 1
	fi

	if [ -z "${GO_VERSION}" ]; then
		echo "[ERROR]: GO_VERSION variable is empty!"
		exit 1
	fi


	if [ -d "${GO_DIR}" ] && [ -x "${GO_DIR}/go/bin/go" ]; then
		echo "[INFO]: Go is already installed in '${GO_DIR}'."
		_setup_shell || exit 2
		exit 0
	fi

	echo "[INFO]: Installing Go in '${GO_DIR}'..."
	mkdir -vp "${GO_DIR}" || exit 2

	rm -vf go.tar.gz || exit 2
	rm -rf "${GO_DIR}/go" || exit 2
	rm -rf "${GO_DIR}/go-${GO_VERSION}" || exit 2

	local _os
	_os="$(uname | tr '[:upper:]' '[:lower:]')"
	local _arch
	_arch="$(uname -m)"
	if [ "${_arch}" = "x86_64" ]; then
		_arch="amd64"
	elif [ "${_arch}" = "aarch64" ] || [ "${_arch}" = "arm64" ]; then
		_arch="arm64"
	fi
	wget "https://go.dev/dl/go${GO_VERSION}.${_os}-${_arch}.tar.gz" -O go.tar.gz || exit 2
	tar -C "${GO_DIR}" -xzf go.tar.gz || exit 2
	rm -vf go.tar.gz || exit 2

	mv -vf "${GO_DIR}/go" "${GO_DIR}/go-${GO_VERSION}" || exit 2
	bash -c "cd '${GO_DIR}' && ln -vsf go-${GO_VERSION} go" || exit 2

	_setup_shell || exit 2
	PATH="${GO_DIR}/go/bin:${PATH}"
	go version || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
