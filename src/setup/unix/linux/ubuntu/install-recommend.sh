#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
# _SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
# cd "${_SCRIPT_DIR}" || exit 2


# shellcheck disable=SC1091
[ -f .env ] && . .env


_OS="$(uname)"
if [ "${_OS}" != "Linux" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only Linux is supported!" >&2
	exit 1
fi

if [ ! -r /etc/os-release ]; then
	echo "[ERROR]: Unable to determine Linux distro (missing /etc/os-release)!" >&2
	exit 1
fi

_IS_OLD_VERSION_OS=false
#shellcheck disable=SC1091
. /etc/os-release
_OS_DISTRO="${ID,,}"
case "${_OS_DISTRO}" in
	ubuntu | debian)
		_OS_VERSION=$(echo "${VERSION_ID}" | tr -d '"')
		if [ "${_OS_DISTRO}" = "ubuntu" ] && [ "${_OS_VERSION%%.*}" -lt 22 ]; then
			_IS_OLD_VERSION_OS=true
		fi;;
	*) echo "[ERROR]: Unsupported Linux distro '${_OS_DISTRO}', only Ubuntu/Debian are supported!" >&2; exit 1;;
esac

_ARCH_UNAME="$(uname -m)"
case "${_ARCH_UNAME}" in
	x86_64 | aarch64 | arm64) : ;;
	*)
		echo "[ERROR]: Unsupported CPU architecture '${_ARCH_UNAME}', only 'x86_64', 'arm64' and 'aarch64' are supported!" >&2
		exit 1;;
esac

if ! command -v dpkg >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'dpkg' command, please check your .bashrc, system configs or 'PATH' environment variable!"
	exit 1
fi

for _cmd in curl wget tar; do
	if ! command -v "${_cmd}" >/dev/null 2>&1; then
		echo "[ERROR]: Not found '${_cmd}' command, please install it first!" >&2
		exit 1
	fi
done


_ARCH_DPKG="$(dpkg --print-architecture)"
_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
elif ! command -v sudo >/dev/null 2>&1; then
	echo "[ERROR]: 'sudo' is required when not running as root!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
INSTALL_EXTRAS=${INSTALL_EXTRAS:-false}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -e, --extras, --install-extras    Install extra packages. Default: false
    -h, --help                        Show help.

EXAMPLES:
    ${0} --extras
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-e | --extras | --install-extras)
			INSTALL_EXTRAS=true
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
	echo "[INFO]: Installing recommended packages..."

	echo "[INFO]: Installing 'lsd'..."
	local _lsd_version
	_lsd_version=$(curl -s https://api.github.com/repos/lsd-rs/lsd/releases/latest | grep "tag_name" | cut -d\" -f4 | sed 's/^v//')
	rm -fv "lsd_${_lsd_version}_${_ARCH_DPKG}.deb" || exit 2
	wget "https://github.com/lsd-rs/lsd/releases/download/v${_lsd_version}/lsd_${_lsd_version}_${_ARCH_DPKG}.deb" || exit 2
	${_SUDO} DEBIAN_FRONTEND=noninteractive dpkg -i "lsd_${_lsd_version}_${_ARCH_DPKG}.deb" || exit 2
	rm -fv "lsd_${_lsd_version}_${_ARCH_DPKG}.deb" || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Installing 'duf'..."
	local _duf_version
	_duf_version=$(curl -s https://api.github.com/repos/muesli/duf/releases/latest | grep "tag_name" | cut -d\" -f4 | sed 's/^v//')
	rm -fv "duf_${_duf_version}_linux_${_ARCH_DPKG}.deb" || exit 2
	wget "https://github.com/muesli/duf/releases/download/v${_duf_version}/duf_${_duf_version}_linux_${_ARCH_DPKG}.deb" || exit 2
	${_SUDO} DEBIAN_FRONTEND=noninteractive dpkg -i "duf_${_duf_version}_linux_${_ARCH_DPKG}.deb" || exit 2
	rm -fv "duf_${_duf_version}_linux_${_ARCH_DPKG}.deb" || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Installing 'q'..."
	local _q_version
	_q_version=$(curl -s https://api.github.com/repos/natesales/q/releases/latest | grep "tag_name" | cut -d\" -f4 | sed 's/^v//')
	rm -fv "q_${_q_version}_linux_${_ARCH_DPKG}.deb" || exit 2
	wget "https://github.com/natesales/q/releases/download/v${_q_version}/q_${_q_version}_linux_${_ARCH_DPKG}.deb" || exit 2
	${_SUDO} DEBIAN_FRONTEND=noninteractive dpkg -i "q_${_q_version}_linux_${_ARCH_DPKG}.deb" || exit 2
	rm -fv "q_${_q_version}_linux_${_ARCH_DPKG}.deb" || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Installing 'bat'..."
	local _bat_version
	_bat_version=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep "tag_name" | cut -d\" -f4 | sed 's/^v//')
	rm -fv "bat_${_bat_version}_${_ARCH_DPKG}.deb" || exit 2
	wget "https://github.com/sharkdp/bat/releases/download/v${_bat_version}/bat_${_bat_version}_${_ARCH_DPKG}.deb" || exit 2
	${_SUDO} DEBIAN_FRONTEND=noninteractive dpkg -i "bat_${_bat_version}_${_ARCH_DPKG}.deb" || exit 2
	rm -fv "bat_${_bat_version}_${_ARCH_DPKG}.deb" || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Installing 'fd'..."
	local _fd_version
	_fd_version=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep "tag_name" | cut -d\" -f4 | sed 's/^v//')
	rm -fv "fd_${_fd_version}_${_ARCH_DPKG}.deb" || exit 2
	wget "https://github.com/sharkdp/fd/releases/download/v${_fd_version}/fd_${_fd_version}_${_ARCH_DPKG}.deb" || exit 2
	${_SUDO} DEBIAN_FRONTEND=noninteractive dpkg -i "fd_${_fd_version}_${_ARCH_DPKG}.deb" || exit 2
	rm -fv "fd_${_fd_version}_${_ARCH_DPKG}.deb" || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Installing 'yq'..."
	${_SUDO} rm -fv /usr/local/bin/yq || exit 2
	${_SUDO} wget "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${_ARCH_DPKG}" -O /usr/local/bin/yq || exit 2
	${_SUDO} chmod +x /usr/local/bin/yq || exit 2
	echo "[OK]: Done."

	if [ "${_IS_OLD_VERSION_OS}" = false ]; then
		echo "[INFO]: Installing 'neovim'..."
		local _arch
		_arch="${_ARCH_UNAME}"
		if [ "${_arch}" = "aarch64" ]; then
			_arch="arm64"
		fi
		rm -fv "nvim-linux-${_arch}.tar.gz" || exit 2
		wget "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${_arch}.tar.gz" || exit 2
		${_SUDO} rm -rf "/opt/nvim-linux-${_arch}" || exit 2
		${_SUDO} tar -C /opt -xzf "nvim-linux-${_arch}.tar.gz" || exit 2
		${_SUDO} ln -sf "/opt/nvim-linux-${_arch}/bin/nvim" /usr/local/bin/nvim || exit 2
		rm -fv "nvim-linux-${_arch}.tar.gz"
		echo "[OK]: Done."
	else
		echo "[WARN]: OS version is too old to install latest 'neovim', skipping!" >&2
		echo "[WARN]: If you need to use latest 'neovim', build it from source and install it manually: https://github.com/neovim/neovim" >&2
	fi

	echo "[INFO]: Installing 'gh' (GitHub CLI)..."
	local _tmp_file
	# shellcheck disable=SC2086
	${_SUDO} mkdir -pv -m 755 /etc/apt/keyrings && \
		_tmp_file="$(mktemp)" && \
		wget -nv -O "${_tmp_file}" https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
		cat "${_tmp_file}" | ${_SUDO} tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
		${_SUDO} chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
		${_SUDO} mkdir -p -m 755 /etc/apt/sources.list.d && \
		echo "deb [arch=${_ARCH_DPKG} signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
			${_SUDO} tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
		${_SUDO} apt-get update && \
		${_SUDO} DEBIAN_FRONTEND=noninteractive apt-get install gh -y && \
		rm -fv "${_tmp_file}" || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Installing 'Tailscale'..."
	sleep 1
	curl -fsSL https://tailscale.com/install.sh | ${_SUDO} DEBIAN_FRONTEND=noninteractive sh || exit 2
	echo "[OK]: Done."

	if [ "${_IS_OLD_VERSION_OS}" = false ]; then
		echo "[INFO]: Installing 'fastfetch'..."
		_arch="${_ARCH_DPKG}"
		if [ "${_arch}" = "arm64" ]; then
			_arch="aarch64"
		fi
		local _fastfetch_version
		_fastfetch_version=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep "tag_name" | cut -d\" -f4 | sed 's/^v//')
		rm -fv "fastfetch-linux-${_arch}.deb" || exit 2
		wget "https://github.com/fastfetch-cli/fastfetch/releases/download/${_fastfetch_version}/fastfetch-linux-${_arch}.deb" || exit 2
		${_SUDO} DEBIAN_FRONTEND=noninteractive dpkg -i "fastfetch-linux-${_arch}.deb" || exit 2
		rm -fv "fastfetch-linux-${_arch}.deb" || exit 2
		echo "[OK]: Done."
	else
		echo "[WARN]: OS version is too old to install 'fastfetch', skipping!" >&2
		echo "[WARN]: If you need to use 'fastfetch', build it from source and install it manually: https://github.com/fastfetch-cli/fastfetch" >&2
	fi

	if [ "${_ARCH_DPKG}" = "amd64" ]; then
		echo "[INFO]: Installing 'xh'..."
		local _xh_version
		_xh_version=$(curl -s https://api.github.com/repos/ducaale/xh/releases/latest | grep "tag_name" | cut -d\" -f4 | sed 's/^v//')
		rm -fv "xh_${_xh_version}_${_ARCH_DPKG}.deb" || exit 2
		wget "https://github.com/ducaale/xh/releases/download/v${_xh_version}/xh_${_xh_version}_${_ARCH_DPKG}.deb" || exit 2
		${_SUDO} DEBIAN_FRONTEND=noninteractive dpkg -i "xh_${_xh_version}_${_ARCH_DPKG}.deb" || exit 2
		rm -fv "xh_${_xh_version}_${_ARCH_DPKG}.deb" || exit 2
		echo "[OK]: Done."
	else
		echo "[WARN]: Skipping 'xh' installation on non-amd64 architecture!"
	fi

	if [ "${INSTALL_EXTRAS}" = true ]; then
		echo "[INFO]: Installing 'ZeroTier One'..."
		curl -s https://install.zerotier.com | ${_SUDO} DEBIAN_FRONTEND=noninteractive bash || exit 2
		echo "[OK]: Done."
	fi

	echo "[OK]: Successfully installed recommended packages."
	echo ""
}

main
## --- Main --- ##
