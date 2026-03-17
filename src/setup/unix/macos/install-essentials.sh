#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
# _SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
# cd "${_SCRIPT_DIR}" || exit 2


# shellcheck disable=SC1091
[ -f .env ] && . .env


_OS="$(uname)"
if [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'macOS' is supported!"
	exit 1
fi

if [ -x /opt/homebrew/bin/brew ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)" || exit 2
elif [ -x /usr/local/bin/brew ]; then
	eval "$(/usr/local/bin/brew shellenv)" || exit 2
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' command not found or not installed!" >&2
	exit 1
fi

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!" >&2
	exit 1
fi
## --- Base --- ##


## --- Main --- ##
main()
{
	echo ""
	echo "[INFO]: Installing essential packages and Homebrew on macOS..."

	if ! command -v brew >/dev/null 2>&1; then
		echo "[INFO]: Not found 'brew' command, installing Homebrew..."
		if ! command -v sudo >/dev/null 2>&1; then
			echo "[ERROR]: Not found 'sudo' command, which is required to install Homebrew on macOS!" >&2
			exit 1
		fi

		echo "[INFO]: Homebrew installation requires 'sudo' privileges, please enter your password if prompted..."
		sudo echo "[INFO]: If you see this message, 'sudo' privileges are working correctly." || exit 2
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 2
		if [ -x /opt/homebrew/bin/brew ]; then
			# shellcheck disable=SC2016
			echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> "${HOME}/.zprofile" || exit 2
			# shellcheck disable=SC2016
			echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.bashrc" || exit 2
			eval "$(/opt/homebrew/bin/brew shellenv)" || exit 2
		elif [ -x /usr/local/bin/brew ]; then
			# shellcheck disable=SC2016
			echo 'eval "$(/usr/local/bin/brew shellenv zsh)"' >> "${HOME}/.zprofile" || exit 2
			# shellcheck disable=SC2016
			echo 'eval "$(/usr/local/bin/brew shellenv)"' >> "${HOME}/.bashrc" || exit 2
			eval "$(/usr/local/bin/brew shellenv)" || exit 2
		fi
		echo "[OK]: Done."
	fi

	echo "[INFO]: Updating Homebrew and upgrading existing packages..."
	brew update || exit 2
	brew upgrade || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Installing essential packages..."
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
		fzf \
		yq \
		fd \
		lsd \
		bat \
		duf \
		witr \
		tlrc \
		xh \
		httpie \
		neovim \
		fastfetch \
		btop \
		gh \
		bash || exit 2

	brew tap natesales/repo https://github.com/natesales/repo || exit 2
	brew install q || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Cleaning up..."
	brew cleanup --prune=all || exit 2
	echo "[OK]: Done."

	echo "[OK]: Successfully installed essential packages and Homebrew on macOS."
	echo ""
}

main
## --- Main --- ##
