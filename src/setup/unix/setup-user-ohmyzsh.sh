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

for _cmd in curl git zsh; do
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
RUNZSH=${RUNZSH:-no}
CHSH=${CHSH:-no}
## --- Variables --- ##


## --- Main --- ##
_update_zshrc()
{
	if [ -z "${1:-}" ]; then
		echo "[ERROR]: No sed expression provided for updating '.zshrc' file!" >&2
		exit 2
	fi

	if [ "${_OS}" = "Linux" ]; then
		sed -i "${1}" "${HOME}/.zshrc" || exit 2
	else
		sed -i '' "${1}" "${HOME}/.zshrc" || exit 2
	fi
}

main()
{
	echo ""
	echo "[INFO]: Setting up 'Oh My Zsh'..."

	## Backup existing '.zshrc' file:
	if [ -f "${HOME}/.zshrc" ] && [ ! -f "${HOME}/.zshrc.bak" ]; then
		echo "[INFO]: Backing up existing '.zshrc' file..."
		cp -v "${HOME}/.zshrc" "${HOME}/.zshrc".bak || exit 2
		echo "[OK]: Done."
	fi

	## Setting up 'Oh My Zsh':
	if [ ! -d "${ZSH:-${HOME}/.oh-my-zsh}" ]; then
		echo "[INFO]: Installing 'Oh My Zsh'..."
		RUNZSH=${RUNZSH} CHSH=${CHSH} sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || exit 2
		echo "[OK]: Done."
	fi

	if [ ! -f "${HOME}/.zshrc" ]; then
		echo "[INFO]: Creating default '.zshrc' file..."
		cp -v "${ZSH:-${HOME}/.oh-my-zsh}/templates/zshrc.zsh-template" "${HOME}/.zshrc" || exit 2
		echo "[OK]: Done."
	fi


	_update_zshrc 's/# DISABLE_MAGIC_FUNCTIONS="true"/DISABLE_MAGIC_FUNCTIONS="true"/' || exit 2

	if ! grep -q 'ZSH_DISABLE_COMPFIX=' "${HOME}/.zshrc"; then
		if [ "${_OS}" = "Linux" ]; then
			sed -i '/^[#[:space:]]*DISABLE_MAGIC_FUNCTIONS.*/a ZSH_DISABLE_COMPFIX="true"' "${HOME}/.zshrc" || exit 2
		else
			sed -i '' '/^[#[:space:]]*DISABLE_MAGIC_FUNCTIONS.*/a\
ZSH_DISABLE_COMPFIX="true"
' "${HOME}/.zshrc" || exit 2
		fi
	else
		_update_zshrc 's/^ZSH_DISABLE_COMPFIX=.*/ZSH_DISABLE_COMPFIX="true"/' || exit 2
	fi


	## Setting up 'zsh-autosuggestions' plugin:
	if [ ! -d "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
		echo "[INFO]: Cloning 'zsh-autosuggestions' plugin..."
		git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" || exit 2
		echo "[OK]: Done."
	fi

	if ! grep -q 'zsh-autosuggestions' "${HOME}/.zshrc"; then
		echo "[INFO]: Adding 'zsh-autosuggestions' plugin to '.zshrc' file..."
		_update_zshrc 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions)/' || exit 2
		echo "[OK]: Done."
	fi


	## Setting up 'zsh-syntax-highlighting' plugin:
	if [ ! -d "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
		echo "[INFO]: Cloning 'zsh-syntax-highlighting' plugin..."
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" || exit 2
		echo "[OK]: Done."
	fi

	if ! grep -q 'zsh-syntax-highlighting' "${HOME}/.zshrc"; then
		echo "[INFO]: Adding 'zsh-syntax-highlighting' plugin to '.zshrc' file..."
		_update_zshrc 's/^plugins=(\(.*\))/plugins=(\1 zsh-syntax-highlighting)/' || exit 2
		echo "[OK]: Done."
	fi


	## Adding other recommended plugins:
	local _plugins="docker docker-compose"
	local _plugin
	echo "[INFO]: Adding '${_plugins}' plugins to '.zshrc' file (if not present)..."
	for _plugin in ${_plugins}; do
		if ! grep -Eq "^plugins=.*\b${_plugin}\b" "${HOME}/.zshrc"; then
			_update_zshrc "/^plugins=/ s/)/ ${_plugin})/" || exit 2
		fi
	done

	if [ "$(id -u)" -ne 0 ]; then
		local _plugins="python pip nvm node npm"
		local _plugin
		echo "[INFO]: Adding '${_plugins}' plugins to '.zshrc' file (if not present)..."
		for _plugin in ${_plugins}; do
			if ! grep -Eq "^plugins=.*\b${_plugin}\b" "${HOME}/.zshrc"; then
				_update_zshrc "/^plugins=/ s/)/ ${_plugin})/" || exit 2
			fi
		done
		echo "[OK]: Done."
	fi
	echo "[OK]: Done."


	## Setting up 'powerlevel10k' theme:
	if [ ! -d "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
		echo "[INFO]: Cloning 'powerlevel10k' theme..."
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k" || exit 2
		echo "[OK]: Done."
	fi

	if grep -q "ZSH_THEME=" "${HOME}/.zshrc"; then
		_update_zshrc 's/^ZSH_THEME="[^"]*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' || exit 2
	else
		echo "" >> "${HOME}/.zshrc" || exit 2
		echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "${HOME}/.zshrc" || exit 2
		echo "" >> "${HOME}/.zshrc" || exit 2
	fi

	local _p10k_theme="p10k-rainbow.zsh"
	if [ "$(id -u)" -eq 0 ]; then
		_p10k_theme="p10k-classic.zsh"
	fi

	if [ ! -f "${HOME}/.p10k.zsh" ]; then
		echo "[INFO]: Copying 'powerlevel10k's theme config to '${HOME}/.p10k.zsh'..."
		cp -v "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k/config/${_p10k_theme}" "${HOME}/.p10k.zsh" || exit 2
		echo "[OK]: Done."
	fi

	if ! grep -Fq "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" "${HOME}/.zshrc"; then
		echo "[INFO]: Adding 'powerlevel10k' theme source line to '.zshrc' file..."
		echo "" >> "${HOME}/.zshrc" || exit 2
		echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "${HOME}/.zshrc" || exit 2
		echo "" >> "${HOME}/.zshrc" || exit 2
		echo "[OK]: Done."
	fi

	echo "[OK]: Successfully set up 'Oh My Zsh'."
	echo ""
}

main
## --- Main --- ##
