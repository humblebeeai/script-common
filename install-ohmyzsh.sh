#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# cd "${_SCRIPT_DIR}" || exit 2


# Loading .env file:
if [ -r .env ]; then
	# shellcheck disable=SC1091
	. .env
fi

_OS="$(uname)"
_OS_DISTRO=""
if [ "${_OS}" = "Linux" ]; then
	_OS_DISTRO=""
	if [ -r /etc/os-release ]; then
		# shellcheck disable=SC1091
		_OS_DISTRO="$(. /etc/os-release && echo "${ID}")"
		_OS_DISTRO="$(echo "${_OS_DISTRO}" | tr '[:upper:]' '[:lower:]')"

		if [ "${_OS_DISTRO}" != "ubuntu" ] && [ "${_OS_DISTRO}" != "debian" ]; then
			echo "[ERROR]: Unsupported Linux distro '${_OS_DISTRO}', only 'Ubuntu' and 'Debian' are supported!"
			exit 1
		fi
	else
		echo "[ERROR]: Unable to determine Linux distro!"
		exit 1
	fi
elif [ "${_OS}" = "Darwin" ]; then
	_OS_DISTRO="macos"
else
	echo "[ERROR]: Unsupported OS '${_OS}'!"
	exit 1
fi
## --- Base --- ##


## --- Main --- ##
update_zshrc()
{
	if [ -z "${1:-}" ]; then
		echo "[ERROR]: No sed expression provided for updating .zshrc!"
		exit 2
	fi

    if [ "${_OS}" = "Linux" ]; then
        sed -i "${1}" ~/.zshrc || exit 2
    else
        sed -i '' "${1}" ~/.zshrc || exit 2
    fi
}

main()
{
	echo "[INFO]: Settting up 'Oh My Zsh'..."

	## Installing 'zsh' and other dependencies:
	if [ "${_OS}" = "Linux" ]; then
		sudo apt-get update || exit 2
		sudo apt-get install -y zsh curl git || exit 2
	else
		if ! command -v brew >/dev/null 2>&1; then
			echo "[INFO]: 'Homebrew' is not installed, installing it now..."
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || exit 2
			echo -e "[OK]: Done.\n"
		fi
		brew update || exit 2
		brew install git || exit 2
	fi


	## Backup existing .zshrc file:
	if [ -r "${HOME}/.zshrc" ] && [ ! -r "${HOME}/.zshrc.bak" ]; then
		echo "[INFO]: Backing up existing .zshrc file..."
		cp -v ~/.zshrc ~/.zshrc.bak || exit 2
		echo -e "[OK]: Done.\n"
	fi

	## Setting up 'Oh My Zsh':
	if [ ! -d "${ZSH:-${HOME}/.oh-my-zsh}" ]; then
		echo "[INFO]: Installing 'Oh My Zsh'..."
		RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || exit 2
		echo -e "[OK]: Done.\n"
	fi

	if [ ! -r "${HOME}/.zshrc" ]; then
		echo "[INFO]: Creating default .zshrc file..."
		cp -v "${ZSH:-${HOME}/.oh-my-zsh}/templates/zshrc.zsh-template" "${HOME}/.zshrc" || exit 2
		echo -e "[OK]: Done.\n"
	fi

	update_zshrc 's/# DISABLE_MAGIC_FUNCTIONS="true"/DISABLE_MAGIC_FUNCTIONS="true"/' || exit 2
	if ! grep -q 'ZSH_DISABLE_COMPFIX=' ~/.zshrc; then
		echo -e '\nZSH_DISABLE_COMPFIX="true"\n' >> ~/.zshrc || exit 2
	else
		update_zshrc 's/^ZSH_DISABLE_COMPFIX=.*/ZSH_DISABLE_COMPFIX="true"/' || exit 2
	fi


	## Setting up 'zsh-autosuggestions' plugin:
	if [ ! -d "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
		echo "[INFO]: Cloning 'zsh-autosuggestions' plugin..."
		git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" || exit 2
		echo -e "[OK]: Done.\n"
	fi

	if ! grep -q 'zsh-autosuggestions' ~/.zshrc; then
		echo "[INFO]: Adding 'zsh-autosuggestions' plugin to .zshrc..."
		update_zshrc 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions)/' || exit 2
		echo -e "[OK]: Done.\n"
	fi


	## Setting up 'zsh-syntax-highlighting' plugin:
	if [ ! -d "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
		echo "[INFO]: Cloning 'zsh-syntax-highlighting' plugin..."
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" || exit 2
		echo -e "[OK]: Done.\n"
	fi

	if ! grep -q 'zsh-syntax-highlighting' ~/.zshrc; then
		echo "[INFO]: Adding 'zsh-syntax-highlighting' plugin to .zshrc..."
		update_zshrc 's/^plugins=(\(.*\))/plugins=(\1 zsh-syntax-highlighting)/' || exit 2
		echo -e "[OK]: Done.\n"
	fi


	## Adding other recommended plugins:
	_plugins="docker docker-compose python pip nvm node npm"
	for _plugin in ${_plugins}; do
		if ! grep -Eq "^plugins=.*\b${_plugin}\b" ~/.zshrc; then
			echo "[INFO]: Adding '${_plugin}' plugin to .zshrc..."
			update_zshrc "/^plugins=/ s/)/ ${_plugin})/" || exit 2
			echo -e "[OK]: Done.\n"
		fi
	done


	## Setting up 'powerlevel10k' theme:
	if [ ! -d "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
		echo "[INFO]: Cloning 'powerlevel10k' theme..."
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k" || exit 2
		echo -e "[OK]: Done.\n"
	fi

	if grep -q "ZSH_THEME=" "${HOME}/.zshrc"; then
		update_zshrc 's/^ZSH_THEME="[^"]*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' || exit 2
	else
		echo -e '\nZSH_THEME="powerlevel10k/powerlevel10k"\n' >> ~/.zshrc || exit 2
	fi

	if [ ! -r "${HOME}/.p10k.zsh" ]; then
		echo "[INFO]: Copying 'powerlevel10k's 'rainbow' theme config to ~/.p10k.zsh..."
		cp -v "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k/config/p10k-rainbow.zsh" ~/.p10k.zsh || exit 2
		echo -e "[OK]: Done.\n"
	fi

	if ! grep -q "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" "${HOME}/.zshrc"; then
		echo "[INFO]: Adding 'powerlevel10k' theme source line to .zshrc..."
		echo -e "\n[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh\n" >> ~/.zshrc || exit 2
		echo -e "[OK]: Done.\n"
	fi

	echo -e "[OK]: 'Oh My Zsh' setup completed successfully!\n"
}

main "${@:-}"
## --- Main --- ##
