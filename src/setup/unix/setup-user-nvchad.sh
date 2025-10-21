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

for _cmd in git nvim; do
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
FORCE_REMOVE=${FORCE_REMOVE:-false}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -f, --force, --force-remove    Force remove existing NvChad configuration. Default: false
    -h, --help                     Show help.

EXAMPLES:
    ${0} --force
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-f | --force | --force-remove)
			FORCE_REMOVE=true
			shift;;
		-h | --help)
			_usage_help
			exit 0;;
		*)
			echo "[ERROR]: Failed to parse argument -> ${1}!" >&2
			_usage_help
			exit 1;;
	esac
done
## --- Menu arguments --- ##


## --- Main --- ##
main()
{
	echo ""
	echo "[INFO]: Setting up 'NvChad'..."

	if [ -d "${HOME}/.config/nvim" ] && [ "${FORCE_REMOVE}" = true ]; then
		echo "[INFO]: Removing existing 'nvim' configuration..."
		rm -rf ~/.config/nvim
		rm -rf ~/.local/state/nvim
		rm -rf ~/.local/share/nvim
		rm -rf ~/.cache/nvim
		echo "[OK]: Done."
	fi

	if [ ! -d "${HOME}/.config/nvim" ]; then
		echo "[INFO]: Cloning 'NvChad'..."
		git clone https://github.com/NvChad/starter "${HOME}/.config/nvim" || exit 2
		rm -rf "${HOME}/.config/nvim/.git" || exit 2
		echo "[OK]: Done."

		echo "[INFO]: Installing 'NvChad' plugins and updating parsers..."
		nvim --headless "+Lazy! sync" "+MasonUpdate" "+TSUpdateSync" +qa || {
			echo "[WARN]: Failed to install 'NvChad' plugins or update parsers, skipping!" >&2
			exit 0
		}

		# if [ -f "${HOME}/.config/nvim/lua/chadrc.lua" ]; then
		# 	if [ "${_OS}" = "Linux" ]; then
		# 		sed -i 's/theme = "onedark"/theme = "oceanic-next"/g' "${HOME}/.config/nvim/lua/chadrc.lua"
		# 	else
		# 		sed -i '' 's/theme = "onedark"/theme = "oceanic-next"/g' "${HOME}/.config/nvim/lua/chadrc.lua"
		# 	fi
		# fi

		echo "[OK]: Done."
	else
		echo "[WARN]: 'nvim' configuration already exists, skipping!"
	fi

	echo "[OK]: Successfully setup 'NvChad'."
	echo ""
}

main
## --- Main --- ##
