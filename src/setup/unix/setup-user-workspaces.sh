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

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
WORKSPACES_DIR="${WORKSPACES_DIR:-${HOME}/workspaces}"
SYMLINK_DIR="${SYMLINK_DIR:-}"
WORKSPACES_SUBDIRS="${WORKSPACES_SUBDIRS:-runtimes,projects,services,datasets,models,storage,archives,education}"
SERVICES_SUBDIRS="${SERVICES_SUBDIRS:-prod,staging,test,qa,docs}"
PROJECTS_SUBDIRS="${PROJECTS_SUBDIRS:-hbai,shared,my,tmp}"
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -w, --workspaces, --workspaces-dir [PATH]    Set workspaces directory path. Default: '~/workspaces'
    -l, --symlink, --symlink-dir       [PATH]    Set target dir and symlink WORKSPACES_DIR to it.
    -s, --subdirs [DIR1,DIR2,...]                Comma-separated list of subdirectories to create under WORKSPACES_DIR.
                                                     Default: 'runtimes,projects,services,datasets,models,storage,archives,education'
    -S, --services [DIR1,DIR2,...]               Comma-separated list of subdirectories to create under 'services' subdirectory.
                                                     Default: 'prod,staging,test,qa,docs'
    -p, --projects [DIR1,DIR2,...]               Comma-separated list of subdirectories to create under 'projects' subdirectory.
                                                     Default: 'hbai,shared,my,tmp'
    -h, --help                                   Show help.

EXAMPLES:
    ${0} --workspaces=./workspaces
    ${0} -w ~/workspaces -l /mnt/nas/accounts/username/workspaces
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		# workspaces:
		-w | --workspaces | --workspaces-dir)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			WORKSPACES_DIR="${2}"
			shift 2;;
		-w=* | --workspaces=* | --workspaces-dir=*)
			WORKSPACES_DIR="${1#*=}"
			shift;;
		# symlink:
		-l | --symlink | --symlink-dir)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			SYMLINK_DIR="${2}"
			shift 2;;
		-l=* | --symlink=* | --symlink-dir=*)
			SYMLINK_DIR=${1#*=}
			shift;;
		# subdirs:
		-s | --subdirs)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			WORKSPACES_SUBDIRS="${2}"
			shift 2;;
		-s=* | --subdirs=*)
			WORKSPACES_SUBDIRS="${1#*=}"
			shift;;
		# services:
		-S | --services)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			SERVICES_SUBDIRS="${2}"
			shift 2;;
		-S=* | --services=*)
			SERVICES_SUBDIRS="${1#*=}"
			shift;;
		# projects:
		-p | --projects)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			PROJECTS_SUBDIRS="${2}"
			shift 2;;
		-p=* | --projects=*)
			PROJECTS_SUBDIRS="${1#*=}"
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
	echo "[INFO]: Creating workspaces and subdirectories..."

	if [ -z "${WORKSPACES_DIR}" ]; then
		echo "[ERROR]: WORKSPACES_DIR variable is empty!" >&2
		exit 1
	fi


	if [ -n "${SYMLINK_DIR}" ]; then
		if [ ! -e "${SYMLINK_DIR}" ]; then
			#shellcheck disable=SC2174
			mkdir -pv -m 775 "${SYMLINK_DIR}" || exit 2
		else
			echo "[WARN]: SYMLINK_DIR '${SYMLINK_DIR}' already exists, skipping!"
		fi
	fi

	if [ ! -e "${WORKSPACES_DIR}" ]; then
		if [ -n "${SYMLINK_DIR}" ] && [ -e "${SYMLINK_DIR}" ]; then
			ln -snfv "${SYMLINK_DIR}" "${WORKSPACES_DIR}" || exit 2
		else
			#shellcheck disable=SC2174
			mkdir -pv -m 775 "${WORKSPACES_DIR}" || exit 2
		fi
	else
		echo "[WARN]: WORKSPACES_DIR '${WORKSPACES_DIR}' already exists, skipping!"
	fi

	if [ ! -d "${WORKSPACES_DIR}" ] && [ ! -L "${WORKSPACES_DIR}" ]; then
		echo "[ERROR]: WORKSPACES_DIR '${WORKSPACES_DIR}' is not a directory or broken symlink!" >&2
		exit 1
	fi

	if [ -n "${WORKSPACES_SUBDIRS}" ]; then
		local _workspaces_subdirs_arr
		IFS=',' read -r -a _workspaces_subdirs_arr <<< "${WORKSPACES_SUBDIRS}"
		local _workspaces_subdir
		for _workspaces_subdir in "${_workspaces_subdirs_arr[@]}"; do
			local _workspaces_full_path="${WORKSPACES_DIR}/${_workspaces_subdir}"
			if [ ! -d "${_workspaces_full_path}" ]; then
				#shellcheck disable=SC2174
				mkdir -pv -m 775 "${_workspaces_full_path}" || exit 2
			fi

			if [ "${_workspaces_subdir}" = "services" ] && [ -n "${SERVICES_SUBDIRS}" ]; then
				local _services_subdirs_arr
				IFS=',' read -r -a _services_subdirs_arr <<< "${SERVICES_SUBDIRS}"
				local _services_subdir
				for _services_subdir in "${_services_subdirs_arr[@]}"; do
					local _services_full_path="${_workspaces_full_path}/${_services_subdir}"
					if [ ! -d "${_services_full_path}" ]; then
						#shellcheck disable=SC2174
						mkdir -pv -m 775 "${_services_full_path}" || exit 2
					fi
				done
			elif [ "${_workspaces_subdir}" = "projects" ] && [ -n "${PROJECTS_SUBDIRS}" ]; then
				local _projects_subdirs_arr
				IFS=',' read -r -a _projects_subdirs_arr <<< "${PROJECTS_SUBDIRS}"
				local _projects_subdir
				for _projects_subdir in "${_projects_subdirs_arr[@]}"; do
					local _projects_full_path="${_workspaces_full_path}/${_projects_subdir}"
					if [ ! -d "${_projects_full_path}" ]; then
						#shellcheck disable=SC2174
						mkdir -pv -m 775 "${_projects_full_path}" || exit 2
					fi
				done
			fi
		done
	fi

	echo "[OK]: Successfully created workspaces and subdirectories."
	echo ""
}

main
## --- Main --- ##
