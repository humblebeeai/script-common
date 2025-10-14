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

if ! command -v nvidia-smi >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'nvidia-smi' command, please install NVIDIA driver first!"
	exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'docker' command, please install Docker first!"
	exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
	echo "[ERROR]: 'jq' command not found or not installed!"
	exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' command not found or not installed!"
	exit 1
fi


_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
fi
## --- Base --- ##


## --- Variables --- ##
NVIDIA_CONTAINER_TOOLKIT_VERSION=${NVIDIA_CONTAINER_TOOLKIT_VERSION:-1.17.8-1}
## --- Variables --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Setting up NVIDIA container toolkit for docker..."

	if ! command -v nvidia-ctk >/dev/null 2>&1; then
		echo "[INFO]: Installing NVIDIA container toolkit..."
		curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
			${_SUDO} gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
			curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
				sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
				${_SUDO} tee /etc/apt/sources.list.d/nvidia-container-toolkit.list || exit 2

		${_SUDO} apt-get update || exit 2
		#shellcheck disable=SC2086
		${_SUDO} apt-get install -y \
			nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
			nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
			libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
			libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION} || exit 2

		echo -e "[OK]: Done.\n"
	fi

	local _is_config_updated=false
	local _docker_config_path="/etc/docker/daemon.json"
	if [ ! -f "${_docker_config_path}" ] || ! grep -q '"nvidia-container-runtime"' "${_docker_config_path}"; then
		echo "[INFO]: Configuring NVIDIA container runtime for docker..."
		${_SUDO} nvidia-ctk runtime configure --runtime=docker || exit 2
		_is_config_updated=true
		echo -e "[OK]: Done.\n"
	else
		echo "[WARN]: 'nvidia-container-runtime' already set in '${_docker_config_path}', skipping...!"
	fi

	local _runtime_json='{"default-runtime": "nvidia"}'
	if ! grep -q '"default-runtime"' "${_docker_config_path}"; then
		echo "[INFO]: Setting 'nvidia' as default runtime for docker..."
		${_SUDO} cp -v "${_docker_config_path}" "${_docker_config_path}.bak" || exit 2
		${_SUDO} jq ". + ${_runtime_json}" "${_docker_config_path}.bak" | \
			${_SUDO} tee "${_docker_config_path}" >/dev/null || exit 2

		${_SUDO} rm -vf "${_docker_config_path}.bak" || exit 2
		_is_config_updated=true
		echo -e "[OK]: Done.\n"
	else
		echo "[WARN]: 'default-runtime' already set in '${_docker_config_path}', skipping...!"
	fi

	if [ "${_is_config_updated}" = true ]; then
		echo "[INFO]: Restarting docker service..."
		${_SUDO} systemctl daemon-reload || exit 2
		${_SUDO} systemctl restart docker || exit 2
		echo -e "[OK]: Done.\n"
	fi

	echo "[INFO]: Testing NVIDIA container with docker..."
	${_SUDO} docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi || exit 2
	echo -e "[OK]: Done.\n"

	echo -e "[OK] Done.\n"
}


main "${@:-}"
## --- Main --- ##
