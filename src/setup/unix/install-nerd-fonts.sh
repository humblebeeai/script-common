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

	for _cmd in curl fc-cache; do
		if ! command -v "${_cmd}" >/dev/null 2>&1; then
			echo "[ERROR]: Not found '${_cmd}' command, please install it first!" >&2
			exit 1
		fi
	done
else
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
	echo "[INFO]: Creating font directories..."
	if [ ! -d "${HOME}/.fonts" ]; then
		mkdir -vp "${HOME}/.fonts" || exit 2
	fi
	cd "${HOME}/.fonts" || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Downloading Ubuntu Mono Nerd Font..."
	rm -vf UbuntuMonoNerdFont-*.ttf || true
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/UbuntuMono/Regular/UbuntuMonoNerdFont-Regular.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/UbuntuMono/Bold/UbuntuMonoNerdFont-Bold.ttf || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Downloading Ubuntu Nerd Font..."
	rm -vf UbuntuNerdFont-*.ttf || true
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Ubuntu/Regular/UbuntuNerdFont-Regular.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Ubuntu/Medium/UbuntuNerdFont-Medium.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Ubuntu/Bold/UbuntuNerdFont-Bold.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Ubuntu/Light/UbuntuNerdFont-Light.ttf || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Downloading Roboto Mono Nerd Font..."
	rm -vf RobotoMonoNerdFont-*.ttf || true
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/RobotoMono/Bold/RobotoMonoNerdFont-Bold.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/RobotoMono/Light/RobotoMonoNerdFont-Light.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/RobotoMono/Medium/RobotoMonoNerdFont-Medium.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/RobotoMono/Regular/RobotoMonoNerdFont-Regular.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/RobotoMono/SemiBold/RobotoMonoNerdFont-SemiBold.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/RobotoMono/Thin/RobotoMonoNerdFont-Thin.ttf || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Downloading Terminess Nerd Font..."
	rm -vf TerminessNerdFont-*.ttf || true
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Terminus/TerminessNerdFont-Bold.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Terminus/TerminessNerdFont-Regular.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Terminus/TerminessNerdFontMono-Bold.ttf || exit 2
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/Terminus/TerminessNerdFontMono-Regular.ttf || exit 2
	echo "[OK]: Done."

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
