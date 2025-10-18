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
_INSTALL_NVIDIA_CONTAINER=false
if [ "${_OS}" = "Linux" ]; then
	if [ -r /etc/os-release ]; then
		# shellcheck disable=SC1091
		_OS_DISTRO="$(source /etc/os-release && echo "${ID}")"
		_OS_DISTRO="$(echo "${_OS_DISTRO}" | tr '[:upper:]' '[:lower:]')"

		if [ "${_OS_DISTRO}" = "ubuntu" ] || [ "${_OS_DISTRO}" = "debian" ]; then
			if command -v nvidia-smi >/dev/null 2>&1; then
				_INSTALL_NVIDIA_CONTAINER=true
			fi
		fi
	fi
else
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' is supported!"
	exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
	echo "[ERROR]: 'curl' command not found or not installed!"
	exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
	echo "[ERROR]: 'jq' command not found or not installed!"
	exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
	echo "[ERROR]: 'rsync' command not found or not installed!"
	exit 1
fi


_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
fi
## --- Base --- ##


## --- Variables --- ##
DOCKER_DATA_DIR=${DOCKER_DATA_DIR:-}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-d=* | --data-dir=*)
					DOCKER_DATA_DIR="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -d=*, --data-dir=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	echo "[INFO]: Setting up docker..."

	if ! command -v docker >/dev/null 2>&1; then
		echo "[INFO]: Installing docker..."
		curl -fsSL https://get.docker.com -o get-docker.sh || exit 2
		${_SUDO} sh get-docker.sh || exit 2
		rm -vrf get-docker.sh || exit 2
		echo -e "[OK]: Done.\n"
	fi

	echo "[INFO]: Creating 'docker' group and adding user to it..."
	${_SUDO} groupadd docker || true
	if [ "$(id -u)" -ne 0 ]; then
		${_SUDO} usermod -aG docker "$(id -un)" || exit 2
	fi
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Enabling docker services..."
	sudo systemctl enable docker.service || exit 2
	sudo systemctl enable containerd.service || exit 2
	echo -e "[OK]: Done.\n"

	if [ "${_INSTALL_NVIDIA_CONTAINER}" = true ]; then
		curl -H 'Cache-Control: no-cache' -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/ubuntu/setup-nvidia-container.sh | \
			bash || {
				echo "[ERROR]: Failed to setup NVIDIA container toolkit!"
				exit 2
			}
	fi

	local _docker_config_path="/etc/docker/daemon.json"
	local _log_opts_json='{"log-opts": {"max-size": "10m", "max-file": "10"}}'
	local _is_config_updated=false
	if [ ! -f "${_docker_config_path}" ]; then
		echo "[INFO]: Creating docker config file with log rotation settings..."
		echo "${_log_opts_json}" | jq '.' | ${_SUDO} tee "${_docker_config_path}" > /dev/null || exit 2
		_is_config_updated=true
	else
		if ! grep -q '"log-opts"' "${_docker_config_path}"; then
			echo "[INFO]: Adding log rotation settings to docker config..."
			${_SUDO} cp -v "${_docker_config_path}" "${_docker_config_path}.bak" || exit 2
			${_SUDO} jq ". + ${_log_opts_json}" "${_docker_config_path}.bak" | \
				${_SUDO} tee "${_docker_config_path}" > /dev/null || exit 2
			${_SUDO} rm -vf "${_docker_config_path}.bak" || exit 2
			_is_config_updated=true
		else
			echo "[WARN]: 'log-opts' already exists in '${_docker_config_path}', skipping...!"
		fi
	fi

	if [ "${_is_config_updated}" = true ]; then
		${_SUDO} systemctl restart docker || exit 2
		echo -e "[OK]: Done.\n"
	fi

	if [ -n "${DOCKER_DATA_DIR}" ]; then
		local _old_docker_data_dir="/var/lib/docker"
		if grep -q '"data-root"' "${_docker_config_path}"; then
			_old_docker_data_dir="$(jq -r '.["data-root"]' "${_docker_config_path}")"
		fi

		if [ "${_old_docker_data_dir}" != "${DOCKER_DATA_DIR}" ]; then
			echo "[INFO]: Changing docker data directory to '${DOCKER_DATA_DIR}'..."
			echo "[INFO]: Stopping docker service..."
			${_SUDO} systemctl stop docker || exit 2
			echo -e "[OK]: Done.\n"

			echo "[INFO]: Copying old docker data from '${_old_docker_data_dir}' to '${DOCKER_DATA_DIR}'..."
			${_SUDO} rm -rf "${DOCKER_DATA_DIR}" || exit 2
			${_SUDO} mkdir -vp "${DOCKER_DATA_DIR}" || exit 2
			${_SUDO} rsync -a "${_old_docker_data_dir}/" "${DOCKER_DATA_DIR}" || exit 2
			echo -e "[OK]: Done.\n"

			echo "[INFO]: Backing up old docker data directory from '${_old_docker_data_dir}' to '${_old_docker_data_dir}.bak'..."
			${_SUDO} rm -rf "${_old_docker_data_dir}.bak" || exit 2
			${_SUDO} mv -f "${_old_docker_data_dir}" "${_old_docker_data_dir}.bak" || exit 2
			echo -e "[OK]: Done.\n"

			echo "[INFO]: Updating 'data-root' in docker config..."
			${_SUDO} cp -v "${_docker_config_path}" "${_docker_config_path}.bak" || exit 2
			if grep -q '"data-root"' "${_docker_config_path}"; then
				${_SUDO} jq '.["data-root"] = "'"${DOCKER_DATA_DIR}"'"' "${_docker_config_path}.bak" | \
					${_SUDO} tee "${_docker_config_path}" > /dev/null || exit 2
			else
				${_SUDO} jq '. + { "data-root": "'"${DOCKER_DATA_DIR}"'" }' "${_docker_config_path}.bak" | \
					${_SUDO} tee "${_docker_config_path}" > /dev/null || exit 2
			fi
			${_SUDO} rm -vf "${_docker_config_path}.bak" || exit 2
			echo -e "[OK]: Done.\n"

			echo "[INFO]: Starting docker service..."
			${_SUDO} systemctl start docker || exit 2
			echo -e "[OK]: Done.\n"

			echo "[INFO]: Removing backup files..."
			${_SUDO} rm -rf "${_old_docker_data_dir}.bak" || exit 2
			echo -e "[OK]: Done.\n"

			echo -e "[OK]: Done.\n"
		fi
	fi

	${_SUDO} docker info || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
