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
NVM_INSTALL_DIR=${NVM_INSTALL_DIR:-"${HOME}/workspaces/runtimes/.nvm"}  # NVM installation directory
NVM_VERSION=${NVM_VERSION:-"v0.39.0"}              # NVM version to install (with 'v' prefix)
NODE_VERSION=${NODE_VERSION:-""}                    # Node.js version to install (leave empty to skip)
## --- Variables --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Setting up 'NVM'..."

	# Ensure NVM_VERSION has 'v' prefix
	if [[ ! "${NVM_VERSION}" =~ ^v ]]; then
		NVM_VERSION="v${NVM_VERSION}"
	fi


       # Check if NVM is already installed
       if [ -s "${NVM_INSTALL_DIR}/nvm.sh" ]; then
	       echo "[INFO]: NVM is already installed at ${NVM_INSTALL_DIR}"
	       echo "[INFO]: To update NVM, run: NVM_DIR=\"${NVM_INSTALL_DIR}\" curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash"
	       echo -e "[OK]: Done.\n"
       else
	       # Download and install NVM to custom directory
	       echo "[INFO]: Downloading and installing NVM ${NVM_VERSION} to ${NVM_INSTALL_DIR}..."
	       export NVM_DIR="${NVM_INSTALL_DIR}"
	       mkdir -p "${NVM_INSTALL_DIR}" || exit 2
	       curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash || exit 2
	       echo -e "[OK]: Done.\n"
       fi


       # Install Node.js if specified
       if [ -n "${NODE_VERSION}" ]; then
	       echo "[INFO]: Installing Node.js ${NODE_VERSION}..."

	       # Source NVM script
	       export NVM_DIR="${NVM_INSTALL_DIR}"
	       # shellcheck disable=SC1091
	       [ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"

	       nvm install "${NODE_VERSION}" || exit 2
	       nvm use "${NODE_VERSION}" || exit 2
	       echo -e "[OK]: Done.\n"
       fi

       echo -e "[OK]: 'NVM' setup completed successfully!"
       echo "[INFO]: Restart your terminal or run 'source ~/.bashrc' (or ~/.zshrc) to use NVM."
       if [ -n "${NODE_VERSION}" ]; then
	       echo "[INFO]: Node.js ${NODE_VERSION} installed and set as default."
       fi
       echo "[INFO]: NVM installed at: ${NVM_INSTALL_DIR}"
}

main "${@:-}"
## --- Main --- ##
