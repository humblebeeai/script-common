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
if [ "${_OS}" != "Linux" ] && [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' and 'macOS' are supported!"
	exit 1
fi

if ! command -v git >/dev/null 2>&1; then
	echo "[ERROR]: 'git' not found or not installed!"
	exit 1
fi

if ! command -v nvim >/dev/null 2>&1; then
	echo "[ERROR]: 'nvim' not found or not installed!"
	exit 1
fi

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!"
	exit 2
fi
## --- Base --- ##


## --- Variables --- ##
FORCE_REMOVE=${FORCE_REMOVE:-false}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-f | --force | --force-remove)
					FORCE_REMOVE=true
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -f | --force | --force-remove"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -d "${HOME}/.config/nvim" ] && [ "${FORCE_REMOVE}" = true ]; then
		echo "[INFO]: Removing existing 'nvim' configuration..."
		rm -rf ~/.config/nvim
		rm -rf ~/.local/state/nvim
		rm -rf ~/.local/share/nvim
		rm -rf ~/.cache/nvim
		echo -e "[OK]: Done.\n"
	fi

	if [ ! -d "${HOME}/.config/nvim" ]; then
		echo "[INFO]: Setting up 'NvChad'..."
		git clone https://github.com/NvChad/starter "${HOME}/.config/nvim" || exit 2
		rm -rf "${HOME}/.config/nvim/.git" || exit 2
		nvim --headless "+Lazy! sync" "+MasonUpdate" "+TSUpdateSync" +qa || exit 2

		if [ -f "${HOME}/.config/nvim/lua/chadrc.lua" ]; then
			if [ "${_OS}" = "Linux" ]; then
				sed -i 's/theme = "onedark"/theme = "oceanic-next"/g' "${HOME}/.config/nvim/lua/chadrc.lua"
			else
				sed -i '' 's/theme = "onedark"/theme = "oceanic-next"/g' "${HOME}/.config/nvim/lua/chadrc.lua"
			fi
		fi

		echo -e "[OK]: Done.\n"
	else
		echo "[WARN]: 'nvim' configuration already exists, skipping..."
	fi
}


main "${@:-}"
## --- Main --- ##
