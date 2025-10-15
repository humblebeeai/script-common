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
_OS_DISTRO=""
if [ "${_OS}" = "Linux" ]; then
	if [ -r /etc/os-release ]; then
		# shellcheck disable=SC1091
		_OS_DISTRO="$(source /etc/os-release && echo "${ID}")"
		_OS_DISTRO="$(echo "${_OS_DISTRO}" | tr '[:upper:]' '[:lower:]')"
	fi
elif [ "${_OS}" = "Darwin" ]; then
	_OS_DISTRO="macos"
else
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' and 'macOS' are supported!"
	exit 1
fi

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!"
	exit 2
fi
## --- Base --- ##


## --- Variables --- ##
_BASE_CONFIGS=$(cat <<'EOF'


### CUSTOM CONFIGS ###

export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

umask 0002


EOF
)

_LINUX_LS_ALIAS=$(cat <<'EOF'
alias ls='ls -aF --group-directories-first --color=auto'
alias l='ls'
alias ll='ls -alhF --group-directories-first --color=auto'

EOF
)

_LINUX_TREE_ALIAS=$(cat <<'EOF'
alias tree4='tree -alFC --dirsfirst -L 4'
alias tree2='tree -alFC --dirsfirst -L 2'
alias tree='tree -alFC --dirsfirst'

EOF
)

_MACOS_LS_ALIAS=$(cat <<'EOF'
alias ls='ls -aFG'
alias l='ls'
alias ll='ls -alhFG'

EOF
)

_MACOS_GLS_ALIAS=$(cat <<'EOF'
alias ls='gls -aF --group-directories-first --color=auto'
alias l='ls'
alias ll='gls -alhF --group-directories-first --color=auto'

EOF
)

_MACOS_TREE_ALIAS=$(cat <<'EOF'
alias tree4='tree -alFC --dirsfirst -L 4'
alias tree2='tree -alFC --dirsfirst -L 2'
alias tree='tree -alFC --dirsfirst'

EOF
)

_LSD_ALIAS=$(cat <<'EOF'
alias ls='lsd -aF --group-dirs first'
alias l='ls'
alias ll='lsd -alhF --group-dirs first'
alias tree4='lsd -aF --group-dirs first --tree --depth 4'
alias tree2='lsd -aF --group-dirs first --tree --depth 2'
alias tree='lsd -aF --group-dirs first --tree'

EOF
)

_BAT_ALIAS="\nalias bat='bat --theme=ansi'\n"

_NEOVIM_ALIAS=$(cat <<'EOF'
alias vi='nvim'
alias vim='nvim'

EOF
)
## --- Variables --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Setting up 'bash'..."
	if [ ! -f "${HOME}/.bashrc" ]; then
		echo "[INFO]: Not found '.bashrc' file in home directory, restoring default or creating new one..."
		if [ -f "/etc/skel/.bashrc" ]; then
			echo "[INFO]: Restoring default '.bashrc' file from /etc/skel/.bashrc..."
			/bin/cp -v "/etc/skel/.bashrc" "${HOME}/.bashrc" || exit 2
		else
			touch "${HOME}/.bashrc" || exit 2
		fi
		echo -e "[OK]: Done.\n"
	fi

	if ! grep -q '### CUSTOM CONFIGS ###' "${HOME}/.bashrc"; then
		echo "[INFO]: Updating '.bashrc' file..."
		echo "${_BASE_CONFIGS}" >> "${HOME}/.bashrc" || exit 2

		if [ "${_OS}" = "Linux" ]; then
			echo "${_LINUX_LS_ALIAS}" >> "${HOME}/.bashrc" || exit 2
			if command -v tree >/dev/null 2>&1; then
				echo "${_LINUX_TREE_ALIAS}" >> "${HOME}/.bashrc" || exit 2
			fi
		elif [ "${_OS}" = "Darwin" ]; then
			if command -v gls >/dev/null 2>&1; then
				echo "${_MACOS_GLS_ALIAS}" >> "${HOME}/.bashrc" || exit 2
			else
				echo "${_MACOS_LS_ALIAS}" >> "${HOME}/.bashrc" || exit 2
			fi

			if command -v tree >/dev/null 2>&1; then
				echo "${_MACOS_TREE_ALIAS}" >> "${HOME}/.bashrc" || exit 2
			fi
		fi

		if command -v bat >/dev/null 2>&1; then
			echo -e "${_BAT_ALIAS}" >> "${HOME}/.bashrc" || exit 2
		fi

		if command -v nvim >/dev/null 2>&1; then
			echo "${_NEOVIM_ALIAS}" >> "${HOME}/.bashrc" || exit 2
		fi
		echo -e "[OK]: Done.\n"
	else
		echo "[WARN]: Already setup '.bashrc' file, skipping...!"
	fi
	echo -e "[OK]: Done.\n"

	if command -v zsh >/dev/null 2>&1; then
		echo "[INFO]: Setting up 'zsh'..."
		if [ ! -f "${HOME}/.zshrc" ]; then
			echo "[INFO]: Not found '.zshrc' file in home directory, restoring default or creating new one..."
			if [ -f "${ZSH:-${HOME}/.oh-my-zsh}/templates/zshrc.zsh-template" ]; then
				cp -v "${ZSH:-${HOME}/.oh-my-zsh}/templates/zshrc.zsh-template" "${HOME}/.zshrc" || exit 2
			elif [ -f "/etc/zsh/zshrc" ]; then
				cp -v "/etc/zsh/zshrc" "${HOME}/.zshrc" || exit 2
			elif [ -f "/etc/zshrc" ]; then
				cp -v "/etc/zshrc" "${HOME}/.zshrc" || exit 2
			else
				touch "${HOME}/.zshrc" || exit 2
			fi
			echo -e "[OK]: Done.\n"
		fi

		if ! grep -q '### CUSTOM CONFIGS ###' "${HOME}/.zshrc"; then
			echo "[INFO]: Updating '.zshrc' file..."
			echo "${_BASE_CONFIGS}" >> "${HOME}/.zshrc" || exit

			if command -v lsd >/dev/null 2>&1; then
				echo "${_LSD_ALIAS}" >> "${HOME}/.zshrc" || exit 2
			else
				if [ "${_OS}" = "Linux" ]; then
					echo "${_LINUX_LS_ALIAS}" >> "${HOME}/.zshrc" || exit 2
					if command -v tree >/dev/null 2>&1; then
						echo "${_LINUX_TREE_ALIAS}" >> "${HOME}/.zshrc" || exit 2
					fi
				elif [ "${_OS}" = "Darwin" ]; then
					if command -v gls >/dev/null 2>&1; then
						echo "${_MACOS_GLS_ALIAS}" >> "${HOME}/.zshrc" || exit 2
					else
						echo "${_MACOS_LS_ALIAS}" >> "${HOME}/.zshrc" || exit 2
					fi

					if command -v tree >/dev/null 2>&1; then
						echo "${_MACOS_TREE_ALIAS}" >> "${HOME}/.zshrc" || exit 2
					fi
				fi
			fi

			if command -v bat >/dev/null 2>&1; then
				echo -e "${_BAT_ALIAS}" >> "${HOME}/.zshrc" || exit 2
			fi

			if command -v nvim >/dev/null 2>&1; then
				echo "${_NEOVIM_ALIAS}" >> "${HOME}/.zshrc" || exit 2
			fi
			echo -e "[OK]: Done.\n"
		else
			echo "[WARN]: Already setup '.zshrc' file, skipping...!"
		fi

		echo -e "[OK]: Done.\n"
	else
		echo "[WARN]: Not found 'zsh', skipping...!"
	fi
}


main "${@:-}"
## --- Main --- ##
