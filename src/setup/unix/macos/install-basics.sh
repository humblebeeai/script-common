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
if [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'macOS' is supported!"
	exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
	echo "[WARN]: Not found 'brew' command, installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 2
	echo -e "[OK]: Done.\n"
fi
## --- Base --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Updating Homebrew and upgrading existing packages..."
	brew update || exit 2
	brew upgrade || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing basic packages..."
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
		tmux \
		jq \
		htop \
		ncdu \
		tree \
		less \
		ripgrep \
		watch \
		watchman \
		fzf \
		yq \
		fd \
		lsd \
		bat \
		duf \
		xh \
		httpie \
		neovim \
		fastfetch \
		btop \
		gh \
		bash || exit 2

	brew tap natesales/repo https://github.com/natesales/repo || exit 2
	brew install q || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Cleaning up..."
	brew cleanup --prune=all || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
