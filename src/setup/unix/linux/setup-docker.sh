#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
cd "${_SCRIPT_DIR}" || exit 2


# shellcheck disable=SC1091
[ -f .env ] && . .env


_OS="$(uname)"
if [ "${_OS}" != "Linux" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only Linux is supported!" >&2
	exit 1
fi

_INSTALL_NVIDIA_CONTAINER=false
if [ -r /etc/os-release ]; then
	# shellcheck disable=SC1091
	. /etc/os-release
	_OS_DISTRO="${ID,,}"
	case "${_OS_DISTRO}" in
		ubuntu | debian)
			_OS_VERSION=$(echo "${VERSION_ID}" | tr -d '"')
			if [ "${_OS_DISTRO}" = "ubuntu" ] && [ "${_OS_VERSION%%.*}" -lt 22 ]; then
				echo "[ERROR]: Unsupported Ubuntu version '${_OS_VERSION}', only 22.04 or newer version is supported!" >&2
				echo "[WARN]: If you need to use older Ubuntu versions, you have to install manually: https://docs.docker.com/engine/install/ubuntu" >&2
				exit 1
			fi

			if command -v nvidia-smi >/dev/null 2>&1; then
				_INSTALL_NVIDIA_CONTAINER=true
			fi;;
		*) : ;;
	esac
fi

if [ -r /proc/version ] && grep -qi "microsoft" /proc/version; then
	echo "[ERROR]: WSL is not supported by this script, please install Docker Desktop for Windows instead!" >&2
	exit 1
fi

for _cmd in curl jq rsync; do
	if ! command -v "${_cmd}" >/dev/null 2>&1; then
		echo "[ERROR]: Not found '${_cmd}' command, please install it first!" >&2
		exit 1
	fi
done


_SUDO="sudo"
if [ "$(id -u)" -eq 0 ]; then
	_SUDO=""
elif ! command -v sudo >/dev/null 2>&1; then
	echo "[ERROR]: 'sudo' is required when not running as root!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
DOCKER_DATA_DIR="${DOCKER_DATA_DIR:-}"
SCRIPT_BASE_URL="${SCRIPT_BASE_URL:-https://github.com/humblebeeai/script-common/raw/main/src}"
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -d, --data, --data-dir [PATH]    Specify the docker data directory. Default: <system-default>
    -h, --help                       Show help.

EXAMPLES:
    ${0} -d /mnt/nas/docker/data
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-d | --data | --data-dir)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			DOCKER_DATA_DIR="${2}"
			shift 2;;
		-d=* | --data=* | --data-dir=*)
			DOCKER_DATA_DIR="${1#*=}"
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
	echo "[INFO]: Setting up docker..."

	if ! command -v docker >/dev/null 2>&1; then
		echo "[INFO]: Installing docker..."
		curl -fsSL https://get.docker.com -o get-docker.sh || exit 2
		${_SUDO} sh get-docker.sh || exit 2
		rm -rfv get-docker.sh || exit 2
		echo "[OK]: Done."
	fi

	echo "[INFO]: Creating 'docker' group and adding user to it..."
	${_SUDO} groupadd docker || true
	if [ "$(id -u)" -ne 0 ]; then
		${_SUDO} usermod -aG docker "$(id -un)" || exit 2
	fi
	echo "[OK]: Done."

	echo "[INFO]: Enabling docker services..."
	${_SUDO} systemctl enable docker.service || exit 2
	${_SUDO} systemctl enable containerd.service || exit 2
	echo "[OK]: Done."

	if [ "${_INSTALL_NVIDIA_CONTAINER}" = true ]; then
		curl -H 'Cache-Control: no-cache' -fsSL "${SCRIPT_BASE_URL}/setup/unix/linux/ubuntu/setup-nvidia-container.sh" | \
			bash || {
				echo "[ERROR]: Failed to setup NVIDIA container toolkit!" >&2
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
		echo "[OK]: Done."
	else
		if ! grep -Fq '"log-opts"' "${_docker_config_path}"; then
			echo "[INFO]: Adding log rotation settings to docker config..."
			${_SUDO} cp -v "${_docker_config_path}" "${_docker_config_path}.bak" || exit 2
			${_SUDO} jq ". + ${_log_opts_json}" "${_docker_config_path}.bak" | \
				${_SUDO} tee "${_docker_config_path}" > /dev/null || exit 2
			${_SUDO} rm -fv "${_docker_config_path}.bak" || exit 2
			_is_config_updated=true
			echo "[OK]: Done."
		else
			echo "[WARN]: 'log-opts' already exists in '${_docker_config_path}', skipping!"
		fi
	fi

	if [ "${_is_config_updated}" = true ]; then
		echo "[INFO]: Restarting docker service..."
		${_SUDO} systemctl restart docker || exit 2
		echo "[OK]: Done."
	fi

	if [ -n "${DOCKER_DATA_DIR}" ]; then
		if [ "${DOCKER_DATA_DIR}" = "/" ]; then
			echo "[ERROR]: DOCKER_DATA_DIR cannot be set to root '/'!" >&2
			exit 1
		fi

		local _old_docker_data_dir="/var/lib/docker"
		if grep -Fq '"data-root"' "${_docker_config_path}"; then
			_old_docker_data_dir="$(jq -r '.["data-root"]' "${_docker_config_path}")"
		fi

		if [ "${_old_docker_data_dir}" != "${DOCKER_DATA_DIR}" ]; then
			echo "[INFO]: Changing docker data directory to '${DOCKER_DATA_DIR}'..."

			echo "[INFO]: Stopping docker service..."
			${_SUDO} systemctl stop docker || exit 2
			echo "[OK]: Done."

			echo "[INFO]: Copying old docker data from '${_old_docker_data_dir}' to '${DOCKER_DATA_DIR}'..."
			${_SUDO} rm -rf "${DOCKER_DATA_DIR}" || exit 2
			${_SUDO} mkdir -pv "${DOCKER_DATA_DIR}" || exit 2
			${_SUDO} rsync -a "${_old_docker_data_dir}/" "${DOCKER_DATA_DIR}" || exit 2
			echo "[OK]: Done."

			echo "[INFO]: Backing up old docker data directory from '${_old_docker_data_dir}' to '${_old_docker_data_dir}.bak'..."
			${_SUDO} rm -rf "${_old_docker_data_dir}.bak" || exit 2
			${_SUDO} mv -f "${_old_docker_data_dir}" "${_old_docker_data_dir}.bak" || exit 2
			echo "[OK]: Done."

			echo "[INFO]: Updating 'data-root' in docker config..."
			${_SUDO} cp -v "${_docker_config_path}" "${_docker_config_path}.bak" || exit 2
			if grep -Fq '"data-root"' "${_docker_config_path}"; then
				${_SUDO} jq '.["data-root"] = "'"${DOCKER_DATA_DIR}"'"' "${_docker_config_path}.bak" | \
					${_SUDO} tee "${_docker_config_path}" > /dev/null || exit 2
			else
				${_SUDO} jq '. + { "data-root": "'"${DOCKER_DATA_DIR}"'" }' "${_docker_config_path}.bak" | \
					${_SUDO} tee "${_docker_config_path}" > /dev/null || exit 2
			fi
			${_SUDO} rm -fv "${_docker_config_path}.bak" || exit 2
			echo "[OK]: Done."

			echo "[INFO]: Starting docker service..."
			${_SUDO} systemctl start docker || exit 2
			echo "[OK]: Done."

			echo "[INFO]: Removing backup files..."
			${_SUDO} rm -rf "${_old_docker_data_dir}.bak" || exit 2
			echo "[OK]: Done."

			echo "[OK]: Done."
		fi
	fi

	${_SUDO} docker info || exit 2
	echo "[OK]: Successfully setup docker."
	echo ""
}

main
## --- Main --- ##
