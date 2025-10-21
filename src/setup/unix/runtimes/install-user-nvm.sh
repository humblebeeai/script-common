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
NVM_DIR="${NVM_DIR:-${HOME}/workspaces/runtimes/.nvm}"
NODE_VERSION=${NODE_VERSION:-}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -d, --install-dir [PATH]             Specify the installation directory for NVM. Default: '~/workspaces/runtimes/nvm'
    -n, --node-version [NODE_VERSION]    Specify the Node.js version to install. Default: <latest-LTS>
    -h, --help                           Show help.

EXAMPLES:
    ${0} --install-dir ./workspaces/runtimes/nvm --node-version 22.20.0
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-d | --install-dir)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			NVM_DIR="${2}"
			shift 2;;
		-d=* | --install-dir=*)
			NVM_DIR="${1#*=}"
			shift;;
		-n | --node-version)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			NODE_VERSION="${2}"
			shift 2;;
		-n=* | --node-version=*)
			NODE_VERSION="${1#*=}"
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
	if ! grep -Fq "NVM_DIR/nvm.sh" "${HOME}/.bashrc"; then
		echo "export NVM_DIR=\"${NVM_DIR}\"" >> "${HOME}/.bashrc" || exit 2
		echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"" >> "${HOME}/.bashrc" || exit 2
		echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"" >> "${HOME}/.bashrc" || exit 2
		echo -e "\n" >> "${HOME}/.bashrc" || exit 2
	fi

	if [ -f "${HOME}/.zshrc" ] && ! grep -q "export NVM_DIR=" "${HOME}/.zshrc"; then
		if grep -Fq "nvm" "${HOME}/.zshrc"; then
			if [ ! -f "${HOME}/.zshenv" ] || ! grep -q "export NVM_DIR=" "${HOME}/.zshenv"; then
				echo "export NVM_DIR=\"${NVM_DIR}\"" >> "${HOME}/.zshenv" || exit 2
				echo "" >> "${HOME}/.zshenv" || exit 2
				echo "" >> "${HOME}/.zshrc" || exit 2
			fi
		else
			echo "export NVM_DIR=\"${NVM_DIR}\"" >> "${HOME}/.zshrc" || exit 2
			echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"" >> "${HOME}/.zshrc" || exit 2
			echo -e "\n" >> "${HOME}/.zshrc" || exit 2
		fi
	fi
}

main()
{
	echo ""
	echo "[INFO]: Installing NVM runtime..."

	if [ -z "${NVM_DIR}" ]; then
		echo "[ERROR]: NVM_DIR variable is empty!" >&2
		exit 2
	fi


	if [ -d "${NVM_DIR}" ] && [ -r "${NVM_DIR}/nvm.sh" ]; then
		_setup_shell || exit 2
		echo "[WARN]: NVM is already installed in '${NVM_DIR}', skipping!"
		exit 0
	fi

	echo "[INFO]: Preparing installation..."
	rm -rf "${NVM_DIR}" || exit 2
	mkdir -pv "${NVM_DIR}" || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Downloading and installing NVM..."
	export NVM_DIR="${NVM_DIR}" || exit 2
	local _nvm_tag_version
	_nvm_tag_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep "tag_name" | cut -d\" -f4) || exit 2
	curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${_nvm_tag_version}/install.sh" | bash || exit 2

	_setup_shell || exit 2
	echo -e "\n" >> "${HOME}/.bashrc" || exit 2

	# shellcheck disable=SC1091
	. "${NVM_DIR}/nvm.sh" || exit 2

	nvm --version || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Installing Node.js..."
	local _arg_node_version="${NODE_VERSION}"
	if [ -z "${_arg_node_version}" ]; then
		_arg_node_version="--lts"
	fi

	local _retry_count=3
	local _retry_delay=1
	local _i=1

	while true; do
		set +e
		nvm install --latest-npm --alias=default "${_arg_node_version}"
		status=$?
		set -e

		if [ ${status} -eq 0 ]; then
			break
		elif [ "${_i}" -ge "${_retry_count}" ]; then
			echo "[ERROR]: Node.js installation failed after ${_retry_count} attempts!" >&2
			exit 2
		fi

		echo "[WARN]: Node.js installation failed, retrying ${_i}/${_retry_count} after ${_retry_delay}s..." >&2
		sleep "${_retry_delay}"
		_i=$((_i + 1))
	done

	nvm use default || exit 2
	nvm cache clear || exit 2

	node -v || exit 2
	npm -v || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Installing pm2 process manager..."
	npm install -g pm2 || exit 2
	pm2 install pm2-logrotate || exit 2

	npm cache clean --force || exit 2
	pm2 -v || exit 2
	echo "[OK]: Done."

	echo "[OK]: Successfully installed NVM runtime."
	echo ""
}

main
## --- Main --- ##
