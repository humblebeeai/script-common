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

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!"
	exit 2
fi
## --- Base --- ##


## --- Variables --- ##
WORKSPACES_DIR=${WORKSPACES_DIR:-"${HOME}/workspaces"}
WORKSPACES_SUBDIRS=${WORKSPACES_SUBDIRS:-"runtimes projects services datasets models storage archives education"}
SERVICES_SUBDIRS=${SERVICES_SUBDIRS:-"prod staging test qa docs"}
PROJECTS_SUBDIRS=${PROJECTS_SUBDIRS:-"shared my tmp"}
SYMLINK_WORKSPACES_DIR=${SYMLINK_WORKSPACES_DIR:-}
## --- Variables --- ##


## --- Main --- ##
main()
{
	## --- Menu arguments --- ##
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-w=* | --workspaces-dir=*)
					WORKSPACES_DIR="${_input#*=}"
					shift;;
				-l=* | --symlink-workspaces-dir=*)
					SYMLINK_WORKSPACES_DIR="${_input#*=}"
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -w=*, --workspaces-dir=* | -l=*, --symlink-workspaces-dir=*"
					exit 1;;
			esac
		done
	fi
	## --- Menu arguments --- ##

	echo "[INFO]: Creating workspaces '${WORKSPACES_DIR}' directory structure..."
	if [ -n "${SYMLINK_WORKSPACES_DIR}" ]; then
		mkdir -vp "${SYMLINK_WORKSPACES_DIR}" || exit 2
	fi

	if [ ! -d "${WORKSPACES_DIR}" ]; then
		if [ -n "${SYMLINK_WORKSPACES_DIR}" ]; then
			ln -sv "${SYMLINK_WORKSPACES_DIR}" "${WORKSPACES_DIR}" || exit 2
		else
			mkdir -vp "${WORKSPACES_DIR}" || exit 2
		fi
	fi

	local _subdir
	for _subdir in ${WORKSPACES_SUBDIRS}; do
		local _full_path="${WORKSPACES_DIR}/${_subdir}"
		if [ ! -d "${_full_path}" ]; then
			mkdir -vp "${_full_path}" || exit 2
		fi

		if [ "${_subdir}" = "services" ]; then
			echo "[INFO]: Creating services subdirectories in '${_full_path}'..."
			local _service_subdir
			for _service_subdir in ${SERVICES_SUBDIRS}; do
				local _service_full_path="${_full_path}/${_service_subdir}"
				if [ ! -d "${_service_full_path}" ]; then
					mkdir -vp "${_service_full_path}" || exit 2
				fi
			done
			echo -e "[OK]: Done.\n"
		elif [ "${_subdir}" = "projects" ]; then
			echo "[INFO]: Creating projects subdirectories in '${_full_path}'..."
			local _project_subdir
			for _project_subdir in ${PROJECTS_SUBDIRS}; do
				local _project_full_path="${_full_path}/${_project_subdir}"
				if [ ! -d "${_project_full_path}" ]; then
					mkdir -vp "${_project_full_path}" || exit 2
				fi
			done
			echo -e "[OK]: Done.\n"
		fi
	done
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
