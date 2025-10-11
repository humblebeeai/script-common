#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
_PROJECT_DIR="$(cd "${_SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
cd "${_PROJECT_DIR}" || exit 2


# Loading .env file (if exists):
if [ -f ".env" ]; then
	# shellcheck disable=SC1091
	source .env
fi


if ! command -v brew >/dev/null 2>&1; then
	echo "[WARN]: Homebrew could not be found, installing it first..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 2
	echo -e "[OK]: Done.\n"
fi
## --- Base --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Installing basic packages..."
	brew update || exit 2
	brew upgrade || exit 2
	brew install \
		coreutils \
		make \
		cmake \
		wget \
		curl \
		git \
		git-lfs \
		rsync \
		unzip \
		zip \
		vim \
		nano \
		jq \
		yq \
		htop \
		ncdu \
		bash \
		duf || exit 2

	brew cleanup --prune=all || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
