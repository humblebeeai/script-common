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

if ! command -v systemctl >/dev/null 2>&1; then
	echo "[ERROR]: 'systemctl' command not found or not installed!"
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
		DRY_RUN=1 ${_SUDO} sh get-docker.sh || exit 2
		rm -vrf get-docker.sh || exit 2
		echo -e "[OK]: Done.\n"
	fi

	echo "[INFO]: Creating 'docker' group and adding user to it..."
	${_SUDO} groupadd docker || true
	if [ -n "${_SUDO}" ]; then
		${_SUDO} usermod -aG docker "$(id -un)" || exit 2
	fi
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Enabling docker services..."
	sudo systemctl enable docker.service || exit 2
	sudo systemctl enable containerd.service || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Updating docker log rotation settings..."
	local _docker_config_path="/etc/docker/daemon.json"
	local _log_opts_json='{ "log-opts": { "max-size": "10m", "max-file": "10" } }'
	if [ -f "${_docker_config_path}" ]; then
		if ! grep -q '"log-opts"' "${_docker_config_path}"; then
			${_SUDO} cp -v "${_docker_config_path}" "${_docker_config_path}.bak" || exit 2
			${_SUDO} jq ". + ${_log_opts_json}" "${_docker_config_path}.bak" | ${_SUDO} tee "${_docker_config_path}" > /dev/null || exit 2
			${_SUDO} rm -vf "${_docker_config_path}.bak" || exit 2
		else
			echo "[WARN]: 'log-opts' already exists in '${_docker_config_path}', skipping...!"
		fi
	else
		echo "${_log_opts_json}" | jq '.' | ${_SUDO} tee "${_docker_config_path}" > /dev/null || exit 2
	fi
	${_SUDO} systemctl restart docker.service || exit 2
	echo -e "[OK]: Done.\n"

	if [ -n "${DOCKER_DATA_DIR}" ]; then
		echo "[INFO]: Changing docker data directory to '${DOCKER_DATA_DIR}'..."
		${_SUDO} systemctl stop docker.service docker.socket containerd.service || exit 2
		${_SUDO} mkdir -vp "${DOCKER_DATA_DIR}" || exit 2
		${_SUDO} cp -v "${_docker_config_path}" "${_docker_config_path}.bak" || exit 2

		local _old_docker_data_dir="/var/lib/docker"
		if grep -q '"data-root"' "${_docker_config_path}"; then
			_old_docker_data_dir="$(jq -r '.["data-root"]' "${_docker_config_path}")"
		fi

		if [ "${_old_docker_data_dir}" != "${DOCKER_DATA_DIR}" ]; then
			echo "[INFO]: Copying old docker data from '${_old_docker_data_dir}' to '${DOCKER_DATA_DIR}'..."
			${_SUDO} rsync -a "${_old_docker_data_dir}/" "${DOCKER_DATA_DIR}" || exit 2
			echo -e "[OK]: Done.\n"

			echo "[INFO]: Backing up old docker data directory..."
			${_SUDO} mv -f "${_old_docker_data_dir}" "${_old_docker_data_dir}.bak" || exit 2
			echo -e "[OK]: Done.\n"

			echo "[INFO]: Updating docker config file '${_docker_config_path}'..."
			if grep -q '"data-root"' "${_docker_config_path}"; then
				${_SUDO} jq '.["data-root"] = "'"${DOCKER_DATA_DIR}"'"' "${_docker_config_path}.bak" | ${_SUDO} tee "${_docker_config_path}" > /dev/null || exit 2
			else
				${_SUDO} jq '. + { "data-root": "'"${DOCKER_DATA_DIR}"'" }' "${_docker_config_path}.bak" | ${_SUDO} tee "${_docker_config_path}" > /dev/null || exit 2
			fi
			echo -e "[OK]: Done.\n"
		fi

		echo "[INFO]: Restarting docker services..."
		${_SUDO} systemctl start containerd.service docker.socket docker.service || exit 2
		echo -e "[OK]: Done.\n"

		echo "[INFO]: Removing backup files..."
		${_SUDO} rm -vf "${_docker_config_path}.bak" || exit 2
		${_SUDO} rm -rf "${_old_docker_data_dir}.bak" || exit 2
		echo -e "[OK]: Done.\n"

		echo -e "[OK]: Done.\n"
	fi

	${_SUDO} docker info || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
