#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
# _SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
# cd "${_SCRIPT_DIR}" || exit 2


# shellcheck disable=SC1091
[ -f .env ] && . .env


_OS="$(uname)"
if [ "${_OS}" != "Linux" ] && [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' and 'macOS' are supported!" >&2
	exit 1
fi

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
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
	echo "[INFO]: Post-setup for user..."

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

	echo "[OK]: Successfully completed post-setup for user."
	echo ""
}

main
## --- Main --- ##
