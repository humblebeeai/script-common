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
if [ "${_OS}" != "Linux" ] && [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' and 'macOS' are supported!"
	exit 1
fi

if ! command -v wget >/dev/null 2>&1; then
	echo "[ERROR]: 'wget' not found or not installed!"
	exit 1
fi

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!"
	exit 2
fi
## --- Base --- ##


## --- Variables --- ##
MINICONDA_DIR=${MINICONDA_DIR:-"${HOME}/workspaces/runtimes/miniconda3"}
PYTHON_VERSION=${PYTHON_VERSION:-3.10}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-i=* | --install-dir=*)
					MINICONDA_DIR="${_input#*=}"
					shift;;
				-p=* | --python-version=*)
					PYTHON_VERSION="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -i=*, --install-dir=* | -p=*, --python-version=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##


	if [ -z "${MINICONDA_DIR}" ]; then
		echo "[ERROR]: MINICONDA_DIR variable is empty!"
		exit 2
	fi

	if [ -z "${PYTHON_VERSION}" ]; then
		echo "[ERROR]: PYTHON_VERSION variable is empty!"
		exit 2
	fi

	if [ -d "${MINICONDA_DIR}" ] && [ -f "${MINICONDA_DIR}/bin/conda" ]; then
		echo "[INFO]: Miniconda is already installed in '${MINICONDA_DIR}'."

		if ! grep -q ">>> conda initialize >>>" "${HOME}/.bashrc"; then
			#shellcheck disable=SC1091
			source "${MINICONDA_DIR}/bin/activate" || exit 2
			conda init bash || exit 2
		fi

		if ! grep -q ">>> conda initialize >>>" "${HOME}/.zshrc"; then
			#shellcheck disable=SC1091
			source "${MINICONDA_DIR}/bin/activate" || exit 2
			conda init zsh || exit 2
		fi
		exit 0
	fi

	echo "[INFO]: Downloading Miniconda installer..."
	mkdir -pv "${MINICONDA_DIR}" || exit 2
	local _miniconda_filename
	_miniconda_filename="Miniconda3-latest-Linux-$(uname -m).sh"
	if [ "${_OS}" = "Darwin" ]; then
		_miniconda_filename="Miniconda3-latest-MacOSX-$(uname -m).sh"
	fi
	wget https://repo.anaconda.com/miniconda/"${_miniconda_filename}" -O miniconda.sh || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Installing Miniconda to '${MINICONDA_DIR}'..."
	bash miniconda.sh -bu -p "${MINICONDA_DIR}" || exit 2
	rm -vrf miniconda.sh || exit 2
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Setting up Miniconda..."
	#shellcheck disable=SC1091
	source "${MINICONDA_DIR}/bin/activate" || exit 2
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
	echo -e "[OK]: Done.\n"

	echo "[INFO]: Creating python environment..."
	local _conda_env
	_conda_env="py${PYTHON_VERSION//./}"
	conda create -y -n "${_conda_env}" python="${PYTHON_VERSION}" pip || exit 2
	conda clean -av || exit 2
	conda activate "${_conda_env}" || exit 2

	echo "conda activate ${_conda_env}" >> "${HOME}/.bashrc" || exit 2
	echo "" >> "${HOME}/.bashrc" || exit 2
	if [ -f "${HOME}/.zshrc" ]; then
		echo "conda activate ${_conda_env}" >> "${HOME}/.zshrc" || exit 2
		echo "" >> "${HOME}/.zshrc" || exit 2
	fi

	pip install -U pip || exit 2
	pip cache purge || exit 2

	python -V || exit 2
	pip -V || exit 2
	uv -V || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
