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
	_OS_DISTRO=""
	if [ -r /etc/os-release ]; then
		# shellcheck disable=SC1091
		_OS_DISTRO="$(source /etc/os-release && echo "${ID}")"
		_OS_DISTRO="$(echo "${_OS_DISTRO}" | tr '[:upper:]' '[:lower:]')"

		if [ "${_OS_DISTRO}" != "ubuntu" ] && [ "${_OS_DISTRO}" != "debian" ]; then
			echo "[ERROR]: Unsupported Linux distro '${_OS_DISTRO}', only 'Ubuntu' and 'Debian' are supported!"
			exit 1
		fi
	else
		echo "[ERROR]: Unable to determine Linux distro!"
		exit 1
	fi
else
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' is supported!"
	exit 1
fi

if [ "$(uname -m)" != "x86_64" ] && [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "arm64" ]; then
	echo "[ERROR]: Unsupported CPU architecture '$(uname -m)', only 'x86_64', 'arm64' and 'aarch64' are supported!"
	exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' not found or not installed!"
	exit 1
fi

if ! command -v wget >/dev/null 2>&1; then
	echo "[ERROR]: 'wget' not found or not installed!"
	exit 1
fi


_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
fi
## --- Base --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Installing development tools..."

	echo "[INFO]: Installing 'lsd'..."
	local _lsd_version
	_lsd_version=$(curl -s https://api.github.com/repos/lsd-rs/lsd/releases/latest | grep "tag_name" | cut -d\" -f4 | sed 's/^v//')
	wget "https://github.com/lsd-rs/lsd/releases/download/v${_lsd_version}/lsd_${_lsd_version}_$(dpkg --print-architecture).deb" || exit 2
	${_SUDO} dpkg -i "lsd_${_lsd_version}_$(dpkg --print-architecture).deb" || exit 2
	rm -vf "lsd_${_lsd_version}_$(dpkg --print-architecture).deb" || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing 'duf'..."
	local _duf_version
	_duf_version=$(curl -s https://api.github.com/repos/muesli/duf/releases/latest | grep "tag_name" | cut -d\" -f4 | sed 's/^v//')
	wget "https://github.com/muesli/duf/releases/download/v${_duf_version}/duf_${_duf_version}_linux_$(dpkg --print-architecture).deb" || exit 2
	${_SUDO} dpkg -i "duf_${_duf_version}_linux_$(dpkg --print-architecture).deb" || exit 2
	rm -vf "duf_${_duf_version}_linux_$(dpkg --print-architecture).deb" || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing 'bat'..."
	local _bat_version
	_bat_version=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep "tag_name" | cut -d\" -f4 | sed 's/^v//')
	wget "https://github.com/sharkdp/bat/releases/download/v${_bat_version}/bat_${_bat_version}_$(dpkg --print-architecture).deb" || exit 2
	${_SUDO} dpkg -i "bat_${_bat_version}_$(dpkg --print-architecture).deb" || exit 2
	rm -vf "bat_${_bat_version}_$(dpkg --print-architecture).deb" || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing 'fd'..."
	local _fd_version
	_fd_version=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep "tag_name" | cut -d\" -f4 | sed 's/^v//')
	wget "https://github.com/sharkdp/fd/releases/download/v${_fd_version}/fd_${_fd_version}_$(dpkg --print-architecture).deb" || exit 2
	${_SUDO} dpkg -i "fd_${_fd_version}_$(dpkg --print-architecture).deb" || exit 2
	rm -vf "fd_${_fd_version}_$(dpkg --print-architecture).deb" || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing 'yq'..."
	${_SUDO} rm -vf /usr/local/bin/yq || true
	${_SUDO} wget "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(dpkg --print-architecture)" -O /usr/local/bin/yq || exit 2
	${_SUDO} chmod +x /usr/local/bin/yq || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing 'neovim'..."
	local _nvim_arch="x86_64"
	if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
		_nvim_arch="arm64"
	fi
	wget "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${_nvim_arch}.tar.gz" || exit 2
	${_SUDO} rm -rf "/opt/nvim-linux-${_nvim_arch}" || true
	${_SUDO} tar -C /opt -xzf "nvim-linux-${_nvim_arch}.tar.gz" || exit 2
	${_SUDO} ln -sf "/opt/nvim-linux-${_nvim_arch}/bin/nvim" /usr/local/bin/nvim || exit 2
	rm -vf "nvim-linux-${_nvim_arch}.tar.gz"
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing 'gh' (GitHub CLI)..."
	local _out
	# shellcheck disable=SC2086
	${_SUDO} mkdir -p -m 755 /etc/apt/keyrings && \
		_out=$(mktemp) && \
		wget -nv -O$_out https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
		cat $_out | ${_SUDO} tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
		${_SUDO} chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
		${_SUDO} mkdir -p -m 755 /etc/apt/sources.list.d && \
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
			${_SUDO} tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
		${_SUDO} apt-get update && \
		${_SUDO} apt-get install gh -y
	echo -e "[OK]: Done.\n"

	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
