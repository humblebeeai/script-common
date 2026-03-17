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
	*) echo "[ERROR]: Unsupported OS '${_OS}', only 'Ubuntu/Debian' and 'macOS' are supported!" >&2; exit 1;;
esac

if [ "${_OS}" == "Linux" ]; then
	if [ ! -r /etc/os-release ]; then
		echo "[ERROR]: Unable to determine Linux distro (missing /etc/os-release)!" >&2
		exit 1
	fi

	#shellcheck disable=SC1091
	. /etc/os-release
	_OS_DISTRO="${ID,,}"
	case "${_OS_DISTRO}" in
		ubuntu | debian | kali) : ;;
		*) echo "[ERROR]: Unsupported Linux distro '${_OS_DISTRO}', only Ubuntu/Debian are supported!" >&2; exit 1;;
	esac

	for _cmd in curl tar fc-cache; do
		if ! command -v "${_cmd}" >/dev/null 2>&1; then
			echo "[ERROR]: Not found '${_cmd}' command, please install it first!" >&2
			exit 1
		fi
	done
else
	if ! command -v brew >/dev/null 2>&1; then
		if [ -x /opt/homebrew/bin/brew ]; then
			eval "$(/opt/homebrew/bin/brew shellenv)" || exit 2
		elif [ -x /usr/local/bin/brew ]; then
			eval "$(/usr/local/bin/brew shellenv)" || exit 2
		fi
	fi

	if ! command -v brew >/dev/null 2>&1; then
		echo "[ERROR]: 'brew' is required on macOS, please install Homebrew first!" >&2
		exit 1
	fi
fi

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!" >&2
	exit 1
fi
## --- Base --- ##


## --- Main --- ##
_install_on_linux()
{
	local _font_dir="${HOME}/.local/share/fonts"
	local _fonts=(
		"Ubuntu"
		"UbuntuMono"
		"RobotoMono"
		"Terminus"
	)

	echo "[INFO]: Creating font directory..."
	mkdir -pv "${_font_dir}" || exit 2
	cd "${_font_dir}" || exit 2
	echo "[OK]: Done."

	for _font in "${_fonts[@]}"; do
		echo "[INFO]: Installing ${_font} Nerd Font..."
		rm -rfv "${_font}"* || true
		local _archive="${_font}.tar.xz"
		local _url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${_archive}"
		curl -fSLO --progress-bar "${_url}" || {
			echo "[WARN]: Failed to download ${_font}, skipping!" >&2
			continue
		}

		tar -xvf "${_archive}" || {
			echo "[WARN]: Failed to extract ${_font}, skipping!" >&2
			rm -rfv "${_archive}"
			continue
		}
		rm -rfv "${_archive}"
		echo "[OK]: ${_font} installed."
	done

	echo "[INFO]: Updating font cache..."
	fc-cache -f -v || exit 2
	echo "[OK]: Done."
}

_install_on_macos()
{
	echo "[INFO]: Installing Ubuntu Mono Nerd Font..."
	brew install font-ubuntu-mono-nerd-font || {
		echo "[WARN]: Failed to install 'Ubuntu Mono Nerd Font', skipping!" >&2
	}
	echo "[OK]: Done."

	echo "[INFO]: Installing Ubuntu Nerd Font..."
	brew install font-ubuntu-nerd-font || {
		echo "[WARN]: Failed to install 'Ubuntu Nerd Font', skipping!" >&2
	}
	echo "[OK]: Done."

	echo "[INFO]: Installing Roboto Mono Nerd Font..."
	brew install font-roboto-mono-nerd-font || {
		echo "[WARN]: Failed to install 'Roboto Mono Nerd Font', skipping!" >&2
	}
	echo "[OK]: Done."

	echo "[INFO]: Installing Terminess Nerd Font..."
	brew install font-terminess-ttf-nerd-font || {
		echo "[WARN]: Failed to install 'Terminess Nerd Font', skipping!" >&2
	}
	echo "[OK]: Done."
}

main()
{
	echo "[INFO]: Installing Nerd Fonts..."
	if [ "${_OS}" == "Linux" ]; then
		_install_on_linux
	else
		_install_on_macos
	fi
	echo "[OK]: Successfully installed Nerd Fonts."
}

main
## --- Main --- ##
