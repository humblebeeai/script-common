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
_TMUX_CONFIGS=$(cat <<'EOF'
set -g default-terminal "screen-256color"
setw -g mouse on
EOF
)
## --- Variables --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Setting up user extra configs..."

	if command -v tmux >/dev/null 2>&1 && [ ! -f "${HOME}/.tmux.conf" ]; then
		echo "${_TMUX_CONFIGS}" > "${HOME}/.tmux.conf" || exit 2
	fi

	if command -v nano >/dev/null 2>&1 && [ ! -f "${HOME}/.nanorc" ]; then
		if [ "${_OS}" = "Darwin" ] && [ -d "/opt/homebrew/Cellar/nano" ]; then
			echo "include \"/opt/homebrew/Cellar/nano/*/share/nano/*.nanorc\"" > "${HOME}/.nanorc" || exit 2
		elif [ "${_OS}" = "Linux" ] && [ -d "/usr/share/nano" ]; then
			echo "include \"/usr/share/nano/*.nanorc\"" > "${HOME}/.nanorc" || exit 2
		fi
	fi

	if command -v ssh-keygen >/dev/null 2>&1 && \
		[ "$(id -u)" -ne 0 ] && \
		[ ! -f "${HOME}/.ssh/id_rsa" ] && \
		[ ! -f "${HOME}/.ssh/id_rsa.pub" ]; then
		ssh-keygen -t rsa -b 4096 -f "${HOME}/.ssh/id_rsa" -N "" || exit 2
	fi

	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
