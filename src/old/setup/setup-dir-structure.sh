#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
# cd "${_SCRIPT_DIR}" || exit 2


# Loading .env file:
if [ -r .env ]; then
	# shellcheck disable=SC1091
	. .env
fi

_OS="$(uname)"
if [ "${_OS}" != "Linux" ] && [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}'!"
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
# Essential workspace settings:
WORKSPACE_BASE_DIR=${WORKSPACE_BASE_DIR:-"${HOME}/workspaces"}  # Base workspace directory
WORKSPACE_SUBDIRS=${WORKSPACE_SUBDIRS:-"projects services runtimes archives datasets education models volumes"}  # Subdirectories to create
## --- Variables --- ##


## --- Main --- ##
create_workspace_structure()
{
	echo "[INFO]: Creating workspace structure at ${WORKSPACE_BASE_DIR}..."

	# Create base directory if it doesn't exist
	if [ ! -d "${WORKSPACE_BASE_DIR}" ]; then
		mkdir -p "${WORKSPACE_BASE_DIR}" || exit 2
		echo "[INFO]: Created base workspace directory: ${WORKSPACE_BASE_DIR}"
	fi

	# Create subdirectories
	for _subdir in ${WORKSPACE_SUBDIRS}; do
		local _full_path="${WORKSPACE_BASE_DIR}/${_subdir}"
		if [ ! -d "${_full_path}" ]; then
			mkdir -p "${_full_path}" || exit 2
			echo "[INFO]: Created directory: ${_full_path}"
		else
			echo "[INFO]: Directory already exists: ${_full_path}"
		fi
	done

	echo -e "[OK]: Workspace structure created successfully!\n"

	# Display the created structure
	echo "[INFO]: Workspace structure:"
	tree "${WORKSPACE_BASE_DIR}" 2>/dev/null || ls -la "${WORKSPACE_BASE_DIR}"
}

main()
{
	echo "[INFO]: Setting up 'Workspace Structure'..."

	create_workspace_structure

	echo -e "[OK]: 'Workspace Structure' setup completed successfully!"
	echo "[INFO]: Base directory: ${WORKSPACE_BASE_DIR}"
	echo "[INFO]: Created subdirectories: ${WORKSPACE_SUBDIRS}"
}

main "${@:-}"
## --- Main --- ##
