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

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
_CUSTOM_CONFIGS=$(cat <<'EOF'

### CUSTOM CONFIGS ###

umask 0002
EOF
)

_LESS_COLOR_ENV=$(cat <<'EOF'
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'
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

_BAT_ALIAS="alias bat='bat --theme=ansi'"

_NEOVIM_ALIAS=$(cat <<'EOF'
alias vi='nvim'
alias vim='nvim'
EOF
)

_TMUX_CONFIGS=$(cat <<'EOF'
set -g default-terminal "screen-256color"
setw -g mouse on
EOF
)
## --- Variables --- ##


## --- Main --- ##
main()
{
	echo ""
	echo "[INFO]: Setting up user configs..."

	echo "[INFO]: Setting up 'bash'..."
	if [ ! -f "${HOME}/.bashrc" ]; then
		echo "[WARN]: Not found '.bashrc' file in user home directory, restoring default or creating new one..."
		if [ -f "/etc/skel/.bashrc" ]; then
			echo "[INFO]: Restoring default '.bashrc' file from '/etc/skel/.bashrc'..."
			/bin/cp -v "/etc/skel/.bashrc" "${HOME}/.bashrc" || exit 2
		else
			touch "${HOME}/.bashrc" || exit 2
		fi
		echo "[OK]: Done."
	elif [ ! -f "${HOME}/.bashrc.bak" ]; then
		echo "[INFO]: Backing up existing '.bashrc' file..."
		cp -v "${HOME}/.bashrc" "${HOME}/.bashrc.bak" || exit 2
		echo "[OK]: Done."
	fi

	if ! grep -q '### CUSTOM CONFIGS ###' "${HOME}/.bashrc"; then
		echo "[INFO]: Updating '.bashrc' file..."
		echo "" >> "${HOME}/.bashrc" || exit 2
		echo "${_CUSTOM_CONFIGS}" >> "${HOME}/.bashrc" || exit 2
		echo "" >> "${HOME}/.bashrc" || exit 2
		echo "${_LESS_COLOR_ENV}" >> "${HOME}/.bashrc" || exit 2
		echo "" >> "${HOME}/.bashrc" || exit 2

		if [ "${_OS}" = "Linux" ]; then
			echo "${_LINUX_LS_ALIAS}" >> "${HOME}/.bashrc" || exit 2
			echo "" >> "${HOME}/.bashrc" || exit 2
			if command -v tree >/dev/null 2>&1; then
				echo "${_LINUX_TREE_ALIAS}" >> "${HOME}/.bashrc" || exit 2
				echo "" >> "${HOME}/.bashrc" || exit 2
			fi
		elif [ "${_OS}" = "Darwin" ]; then
			if command -v gls >/dev/null 2>&1; then
				echo "${_MACOS_GLS_ALIAS}" >> "${HOME}/.bashrc" || exit 2
			else
				echo "${_MACOS_LS_ALIAS}" >> "${HOME}/.bashrc" || exit 2
			fi
			echo "" >> "${HOME}/.bashrc" || exit 2

			if command -v tree >/dev/null 2>&1; then
				echo "${_MACOS_TREE_ALIAS}" >> "${HOME}/.bashrc" || exit 2
				echo "" >> "${HOME}/.bashrc" || exit 2
			fi
		fi

		if command -v bat >/dev/null 2>&1; then
			echo "${_BAT_ALIAS}" >> "${HOME}/.bashrc" || exit 2
			echo "" >> "${HOME}/.bashrc" || exit 2
		fi

		if command -v nvim >/dev/null 2>&1; then
			echo "${_NEOVIM_ALIAS}" >> "${HOME}/.bashrc" || exit 2
			echo "" >> "${HOME}/.bashrc" || exit 2
		fi
		echo "[OK]: Done."
	else
		echo "[WARN]: Already setup '.bashrc' file, skipping!"
	fi
	echo "[OK]: Done."
	echo ""

	if command -v zsh >/dev/null 2>&1; then
		echo "[INFO]: Setting up 'zsh'..."
		if [ ! -f "${HOME}/.zshrc" ]; then
			echo "[WARN]: Not found '.zshrc' file in user home directory, restoring default or creating new one..."
			if [ -f "${ZSH:-${HOME}/.oh-my-zsh}/templates/zshrc.zsh-template" ]; then
				echo "[INFO]: Restoring default '.zshrc' file from Oh My Zsh template..."
				cp -v "${ZSH:-${HOME}/.oh-my-zsh}/templates/zshrc.zsh-template" "${HOME}/.zshrc" || exit 2
			elif [ -f "/etc/zsh/zshrc" ]; then
				echo "[INFO]: Restoring default '.zshrc' file from '/etc/zsh/zshrc'..."
				cp -v "/etc/zsh/zshrc" "${HOME}/.zshrc" || exit 2
			elif [ -f "/etc/zshrc" ]; then
				echo "[INFO]: Restoring default '.zshrc' file from '/etc/zshrc'..."
				cp -v "/etc/zshrc" "${HOME}/.zshrc" || exit 2
			else
				touch "${HOME}/.zshrc" || exit 2
			fi
			echo "[OK]: Done."
		elif [ ! -f "${HOME}/.zshrc.bak" ]; then
			echo "[INFO]: Backing up existing '.zshrc' file..."
			cp -v "${HOME}/.zshrc" "${HOME}/.zshrc.bak" || exit 2
			echo "[OK]: Done."
		fi

		if ! grep -q '### CUSTOM CONFIGS ###' "${HOME}/.zshrc"; then
			echo "[INFO]: Updating '.zshrc' file..."
			echo "${_CUSTOM_CONFIGS}" >> "${HOME}/.zshrc" || exit
			echo "" >> "${HOME}/.zshrc" || exit 2
			echo "${_LESS_COLOR_ENV}" >> "${HOME}/.zshrc" || exit 2
			echo "" >> "${HOME}/.zshrc" || exit 2

			if command -v lsd >/dev/null 2>&1 && [ "$(id -u)" -ne 0 ]; then
				echo "${_LSD_ALIAS}" >> "${HOME}/.zshrc" || exit 2
				echo "" >> "${HOME}/.zshrc" || exit 2
			else
				if [ "${_OS}" = "Linux" ]; then
					echo "${_LINUX_LS_ALIAS}" >> "${HOME}/.zshrc" || exit 2
					echo "" >> "${HOME}/.zshrc" || exit 2
					if command -v tree >/dev/null 2>&1; then
						echo "${_LINUX_TREE_ALIAS}" >> "${HOME}/.zshrc" || exit 2
						echo "" >> "${HOME}/.zshrc" || exit 2
					fi
				elif [ "${_OS}" = "Darwin" ]; then
					if command -v gls >/dev/null 2>&1; then
						echo "${_MACOS_GLS_ALIAS}" >> "${HOME}/.zshrc" || exit 2
					else
						echo "${_MACOS_LS_ALIAS}" >> "${HOME}/.zshrc" || exit 2
					fi
					echo "" >> "${HOME}/.zshrc" || exit 2

					if command -v tree >/dev/null 2>&1; then
						echo "${_MACOS_TREE_ALIAS}" >> "${HOME}/.zshrc" || exit 2
						echo "" >> "${HOME}/.zshrc" || exit 2
					fi
				fi
			fi

			if command -v bat >/dev/null 2>&1; then
				echo "${_BAT_ALIAS}" >> "${HOME}/.zshrc" || exit 2
				echo "" >> "${HOME}/.zshrc" || exit 2
			fi

			if command -v nvim >/dev/null 2>&1; then
				echo "${_NEOVIM_ALIAS}" >> "${HOME}/.zshrc" || exit 2
				echo "" >> "${HOME}/.zshrc" || exit 2
			fi
			echo "[OK]: Done."
		else
			echo "[WARN]: Already setup '.zshrc' file, skipping!"
		fi
		echo "[OK]: Done."
	else
		echo "[WARN]: Not found 'zsh', skipping!"
	fi

	if command -v tmux >/dev/null 2>&1 && [ ! -f "${HOME}/.tmux.conf" ]; then
		echo "${_TMUX_CONFIGS}" > "${HOME}/.tmux.conf" || exit 2
		echo "" >> "${HOME}/.tmux.conf" || exit 2
	fi

	if command -v nano >/dev/null 2>&1 && [ ! -f "${HOME}/.nanorc" ]; then
		if [ "${_OS}" = "Darwin" ] && [ -d "/opt/homebrew/Cellar/nano" ]; then
			echo "include \"/opt/homebrew/Cellar/nano/*/share/nano/*.nanorc\"" > "${HOME}/.nanorc" || exit 2
			echo "" >> "${HOME}/.nanorc" || exit 2
		elif [ "${_OS}" = "Linux" ] && [ -d "/usr/share/nano" ]; then
			echo "include \"/usr/share/nano/*.nanorc\"" > "${HOME}/.nanorc" || exit 2
			echo "" >> "${HOME}/.nanorc" || exit 2
		fi
	fi

	if [ "$(id -u)" -ne 0 ]; then
		mkdir -pv "${HOME}/.ssh" || exit 2
		chmod -c 700 "${HOME}/.ssh" || exit 2

		if command -v ssh-keygen >/dev/null 2>&1 && \
			[ ! -f "${HOME}/.ssh/id_rsa" ] && \
			[ ! -f "${HOME}/.ssh/id_rsa.pub" ]; then
			ssh-keygen -t rsa -b 4096 -f "${HOME}/.ssh/id_rsa" -N "" || exit 2
		fi
	fi

	echo "[OK]: Successfully setup user configs."
	echo ""
}

main
## --- Main --- ##
