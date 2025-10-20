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

if ! command -v wget >/dev/null 2>&1; then
	echo "[ERROR]: 'wget' not found or not installed!" >&2
	exit 1
fi

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
MINICONDA_DIR="${MINICONDA_DIR:-${HOME}/workspaces/runtimes/miniconda3}"
PYTHON_VERSION=${PYTHON_VERSION:-3.10}
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -d, --install-dir [PATH]                 Specify the installation directory for Miniconda. Default: '~/workspaces/runtimes/miniconda3'
    -p, --python-version [PYTHON_VERSION]    Specify the python version to install. Default: 3.10
    -h, --help                               Show help.

EXAMPLES:
    ${0} --install-dir ./workspaces/runtimes/miniconda3 --python-version 3.10
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-d | --install-dir)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			MINICONDA_DIR="${2}"
			shift 2;;
		-d=* | --install-dir=*)
			MINICONDA_DIR="${1#*=}"
			shift;;
		-p | --python-version)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			PYTHON_VERSION="${2}"
			shift 2;;
		-p=* | --python-version=*)
			PYTHON_VERSION="${1#*=}"
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
	echo "[INFO]: Installing Miniconda runtime..."

	if [ -z "${MINICONDA_DIR}" ]; then
		echo "[ERROR]: MINICONDA_DIR variable is empty!" >&2
		exit 2
	fi

	if [ -z "${PYTHON_VERSION}" ]; then
		echo "[ERROR]: PYTHON_VERSION variable is empty!" >&2
		exit 2
	fi


	if [ -d "${MINICONDA_DIR}" ] && [ -x "${MINICONDA_DIR}/bin/conda" ]; then
		if ! grep -Fq ">>> conda initialize >>>" "${HOME}/.bashrc"; then
			#shellcheck disable=SC1091
			. "${MINICONDA_DIR}/bin/activate" || exit 2
			conda init bash || exit 2
		fi

		if [ -f "${HOME}/.zshrc" ] && ! grep -Fq ">>> conda initialize >>>" "${HOME}/.zshrc"; then
			#shellcheck disable=SC1091
			. "${MINICONDA_DIR}/bin/activate" || exit 2
			conda init zsh || exit 2
		fi

		echo "[WARN]: Miniconda is already installed in '${MINICONDA_DIR}', skipping!"
		exit 0
	fi

	echo "[INFO]: Preparing installation..."
	rm -vf miniconda.sh || exit 2
	rm -rf "${MINICONDA_DIR}" || exit 2
	mkdir -pv "${MINICONDA_DIR}" || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Downloading Miniconda installer..."
	local _miniconda_filename
	_miniconda_filename="Miniconda3-latest-Linux-$(uname -m).sh"
	if [ "${_OS}" = "Darwin" ]; then
		_miniconda_filename="Miniconda3-latest-MacOSX-$(uname -m).sh"
	fi
	wget https://repo.anaconda.com/miniconda/"${_miniconda_filename}" -O miniconda.sh || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Installing Miniconda to '${MINICONDA_DIR}'..."
	bash miniconda.sh -bu -p "${MINICONDA_DIR}" || exit 2
	rm -vf miniconda.sh || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Setting up Miniconda..."
	#shellcheck disable=SC1091
	. "${MINICONDA_DIR}/bin/activate" || exit 2
	conda init bash || exit 2

	if command -v zsh >/dev/null 2>&1; then
		conda init zsh || exit 2
	fi

	conda tos accept --override-channels \
		-c https://repo.anaconda.com/pkgs/main \
		-c https://repo.anaconda.com/pkgs/r || exit 2

	conda config --append channels conda-forge || exit 2
	echo -e "\nplugins:\n  anaconda_telemetry: false" >> ~/.condarc || exit 2
	# conda config --set always_yes true || exit 2
	conda update -y -n base conda || exit 2
	conda -V || exit 2
	echo "[OK]: Done."

	echo "[INFO]: Creating python environment..."
	local _conda_env
	_conda_env="py${PYTHON_VERSION//./}"

	local _retry_count=3
	local _retry_delay=1
	local _i=1
	while ! conda create -y -n "${_conda_env}" python="${PYTHON_VERSION}" pip; do
		if [ "${_i}" -ge "${_retry_count}" ]; then
			echo "[ERROR]: Python environment creation failed after ${_retry_count} attempts!" >&2
			exit 2
		fi

		echo "[WARN]: Python environment creation failed, retrying ${_i}/${_retry_count} after ${_retry_delay} seconds..." >&2
		sleep ${_retry_delay}
		_i=$((_i + 1))
	done

	conda clean -av || exit 2
	conda activate "${_conda_env}" || exit 2

	if ! grep -Fq "conda activate ${_conda_env}" "${HOME}/.bashrc"; then
		echo "conda activate ${_conda_env}" >> "${HOME}/.bashrc" || exit 2
		echo "" >> "${HOME}/.bashrc" || exit 2
	fi

	if [ -f "${HOME}/.zshrc" ] && ! grep -Fq "conda activate ${_conda_env}" "${HOME}/.zshrc"; then
		echo "conda activate ${_conda_env}" >> "${HOME}/.zshrc" || exit 2
		echo "" >> "${HOME}/.zshrc" || exit 2
	fi

	pip install -U pip || exit 2
	pip cache purge || exit 2

	python -V || exit 2
	pip -V || exit 2
	echo "[OK]: Done."

	echo "[OK]: Successfully installed Miniconda runtime."
	echo ""
}

main
## --- Main --- ##
