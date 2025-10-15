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
NVM_DIR=${NVM_DIR:-"${HOME}/workspaces/runtimes/.nvm"}
## --- Variables --- ##


## --- Main --- ##
main()
{
	if [ -d "${NVM_DIR}" ]; then
		echo "[INFO]: NVM is already installed in '${NVM_DIR}', skipping..."
		exit 0
	fi

	echo "[INFO]: Installing NVM to '${NVM_DIR}'..."
	mkdir -vp "${NVM_DIR}" || exit 2
	export NVM_DIR="${NVM_DIR}" || exit 2
	local _nvm_version
	_nvm_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep "tag_name" | cut -d\" -f4) || exit 2
	export NVM_VERSION="${_nvm_version}" || exit 2
	curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash || exit 2

	# shellcheck disable=SC1091
	source "${NVM_DIR}/nvm.sh" || exit 2
	# if [ -f "${HOME}/.zshrc" ]; then
	# fi

	nvm --version || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing Node.js..."
	nvm install --latest-npm --alias=default 22.20.0 || exit 2
	nvm use default || exit 2
	nvm cache clear || exit 2

	node -v || exit 2
	npm -v || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing pm2 process manager..."
	npm install -g pm2 || exit 2
	pm2 install pm2-logrotate || exit 2

	npm cache clean --force || exit 2
	pm2 -v || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
