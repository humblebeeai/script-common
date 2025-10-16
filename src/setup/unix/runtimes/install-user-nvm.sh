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
NODE_VERSION=${NODE_VERSION:-}
## --- Variables --- ##


## --- Main --- ##
_setup_shellrc()
{
	if ! grep -q "NVM_DIR/nvm.sh" "${HOME}/.bashrc"; then
		echo "export NVM_DIR=\"${NVM_DIR}\"" >> "${HOME}/.bashrc" || exit 2
		echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"" >> "${HOME}/.bashrc" || exit 2
		echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"" >> "${HOME}/.bashrc" || exit 2
		echo "" >> "${HOME}/.bashrc" || exit 2
	fi

	if [ -f "${HOME}/.zshrc" ] && ! grep -q "export NVM_DIR=" "${HOME}/.zshrc"; then
		if grep -q "nvm" "${HOME}/.zshrc"; then
			if [ "${_OS}" = "Darwin" ]; then
				sed -i '' "/^plugins=(git/i\\
export NVM_DIR=\"${NVM_DIR}\"
" "${HOME}/.zshrc" || exit 2
			else
				sed -i "/^plugins=(git/i export NVM_DIR=\"${NVM_DIR}\"" "${HOME}/.zshrc" || exit 2
			fi
		else
			echo "export NVM_DIR=\"${NVM_DIR}\"" >> "${HOME}/.zshrc" || exit 2
			echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"" >> "${HOME}/.zshrc" || exit 2
		fi
		echo "" >> "${HOME}/.zshrc" || exit 2
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
					NVM_DIR="${_input#*=}"
					shift;;
				-n=* | --node-version=*)
					NODE_VERSION="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -i=*, --install-dir=* | -n=*, --node-version=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -z "${NVM_DIR}" ]; then
		echo "[ERROR]: NVM_DIR variable is empty!"
		exit 2
	fi

	if [ -d "${NVM_DIR}" ] && [ -r "${NVM_DIR}/nvm.sh" ]; then
		echo "[INFO]: NVM is already installed in '${NVM_DIR}'."
		_setup_shellrc || exit 2
		exit 0
	fi

	echo "[INFO]: Installing NVM to '${NVM_DIR}'..."
	mkdir -vp "${NVM_DIR}" || exit 2
	export NVM_DIR="${NVM_DIR}" || exit 2
	local _nvm_version
	_nvm_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep "tag_name" | cut -d\" -f4) || exit 2
	export NVM_VERSION="${_nvm_version}" || exit 2
	curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash || exit 2

	_setup_shellrc || exit 2
	# shellcheck disable=SC1091
	source "${NVM_DIR}/nvm.sh" || exit 2

	nvm --version || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing Node.js..."
	local _arg_node_version="${NODE_VERSION}"
	if [ -z "${_arg_node_version}" ]; then
		_arg_node_version="--lts"
	fi
	nvm install --latest-npm --alias=default "${_arg_node_version}" || exit 2
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
