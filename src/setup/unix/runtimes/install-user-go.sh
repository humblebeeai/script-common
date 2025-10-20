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

for _cmd in wget tar; do
	if ! command -v "${_cmd}" >/dev/null 2>&1; then
		echo "[ERROR]: Not found '${_cmd}' command, please install it first!" >&2
		exit 1
	fi
done

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
GO_DIR="${GO_DIR:-${HOME}/workspaces/runtimes/go}"
GO_VERSION=${GO_VERSION:-1.25.3}
FORCE_INSTALL=${FORCE_INSTALL:-false}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -d, --install-dir [PATH]         Specify the installation directory for Go. Default: '~/workspaces/runtimes/go'
    -g, --go-version [GO_VERSION]    Specify the Go version to install. Default: 1.25.3
    -f, --force                      Force installation even if different version is installed. Default: false
    -h, --help                       Show help.

EXAMPLES:
    ${0} --install-dir ./workspaces/runtimes/go --go-version 1.25.3
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-d | --install-dir)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			GO_DIR="${2}"
			shift 2;;
		-d=* | --install-dir=*)
			GO_DIR="${1#*=}"
			shift;;
		-g | --go-version)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			GO_VERSION="${2}"
			shift 2;;
		-g=* | --go-version=*)
			GO_VERSION="${1#*=}"
			shift;;
		-f | --force)
			FORCE_INSTALL=true
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
	if ! grep -Fq "export PATH=\"${GO_DIR}/go/bin:" "${HOME}/.bashrc"; then
		echo "export PATH=\"${GO_DIR}/go/bin:\${PATH}\"" >> "${HOME}/.bashrc" || exit 2
		echo "" >> "${HOME}/.bashrc" || exit 2
	fi

	if [ -f "${HOME}/.zshrc" ] && ! grep -Fq "export PATH=\"${GO_DIR}/go/bin:" "${HOME}/.zshrc"; then
		echo "export PATH=\"${GO_DIR}/go/bin:\${PATH}\"" >> "${HOME}/.zshrc" || exit 2
		echo "" >> "${HOME}/.zshrc" || exit 2
	fi
}

main()
{
	echo ""
	echo "[INFO]: Installing Go runtime..."

	if [ -z "${GO_DIR}" ]; then
		echo "[ERROR]: GO_DIR variable is empty!" >&2
		exit 1
	fi

	if [ -z "${GO_VERSION}" ]; then
		echo "[ERROR]: GO_VERSION variable is empty!" >&2
		exit 1
	fi


	if [ -d "${GO_DIR}" ] && [ -x "${GO_DIR}/go/bin/go" ]; then
		local _go_version
		_go_version="$("${GO_DIR}/go/bin/go" version | awk '{print $3}' | sed 's/go//')" || exit 2
		if [ "${_go_version}" = "${GO_VERSION}" ]; then
			_setup_shell || exit 2
			echo "[OK]: Go '${_go_version}' version is already installed in '${GO_DIR}', skipping!"
			echo ""
			exit 0
		elif [ "${FORCE_INSTALL}" = true ]; then
			echo "[WARN]: Different Go '${_go_version}' version is already installed in '${GO_DIR}', but proceeding due to force." >&2
		else
			echo "[ERROR]: Different Go '${_go_version}' version is already installed in '${GO_DIR}'!" >&2
			echo ""
			exit 1
		fi
	fi

	echo "[INFO]: Preparing installation..."
	rm -fv go.tar.gz || exit 2
	rm -rf "${GO_DIR}" || exit 2
	mkdir -pv "${GO_DIR}" || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Downloading Go tarball..."
	local _os
	_os="$(echo "${_OS}" | tr '[:upper:]' '[:lower:]')"
	local _arch
	case "$(uname -m)" in
		x86_64) _arch="amd64";;
		aarch64) _arch="arm64";;
		*) _arch="$(uname -m)";;
	esac
	wget "https://go.dev/dl/go${GO_VERSION}.${_os}-${_arch}.tar.gz" -O go.tar.gz || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Setting up Go..."
	tar -C "${GO_DIR}" -xzf go.tar.gz || exit 2
	rm -fv go.tar.gz || exit 2
	mv -fv "${GO_DIR}/go" "${GO_DIR}/go-${GO_VERSION}" || exit 2
	bash -c "cd '${GO_DIR}' && ln -snfv go-${GO_VERSION} go" || exit 2
	_setup_shell || exit 2
	echo "[OK]: Done."

	PATH="${GO_DIR}/go/bin:${PATH}"
	go version || exit 2

	echo "[OK]: Successfully installed Go runtime."
	echo ""
}

main
## --- Main --- ##
