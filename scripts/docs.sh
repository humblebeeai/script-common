#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
_PROJECT_DIR="$(cd "${_SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
cd "${_PROJECT_DIR}" || exit 2


for _cmd in mkdocs mike; do
	if ! command -v "${_cmd}" >/dev/null 2>&1; then
		echo "[ERROR]: Not found '${_cmd}' command, please install it first!" >&2
		exit 1
	fi
done
## --- Base --- ##


## --- Variables --- ##
# Flags:
_IS_BUILD=false
_IS_PUBLISH=false
_IS_CLEAN=true
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -b, --build            Build documentation pages.
    -p, --publish          Publish documentation pages.
    -c, --disable-clean    Disable cleaning after publishing.
    -h, --help             Show help.

EXAMPLES:
    ${0}
    ${0} --build
    ${0} --publish
    ${0} -p -c
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-b | --build)
			_IS_BUILD=true
			shift;;
		-p | --publish)
			_IS_PUBLISH=true
			shift;;
		-c | --disable-clean)
			_IS_CLEAN=false
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


## --- Validate arguments --- ##
if [ "${_IS_PUBLISH}" == true ]; then
	if ! command -v git >/dev/null 2>&1; then
		echo "[ERROR]: 'git' not found or not installed!" >&2
		exit 1
	fi
fi
## --- Validate arguments --- ##


## --- Main --- ##
main()
{
	local _major_minor_version
	if [ "${_IS_BUILD}" == true ]; then
		echo "[INFO]: Building documentation pages (HTML) into the 'site' directory..."
		mkdocs build

		# _major_minor_version="$(./scripts/get-version.sh | cut -d. -f1-2)"
		# mike deploy -u "${_major_minor_version}" latest
		# mike set-default latest
	elif [ "${_IS_PUBLISH}" == true ]; then
		echo "[INFO]: Publishing documentation pages to the GitHub Pages..."
		# mkdocs gh-deploy --force

		_major_minor_version="$(./scripts/get-version.sh | cut -d. -f1-2)"
		mike deploy -p -u "${_major_minor_version}" latest
		mike set-default -p latest

		if [ "${_IS_CLEAN}" == true ]; then
			./scripts/clean.sh || exit 2
		fi
	else
		echo "[INFO]: Starting documentation server..."
		#shellcheck disable=SC2086
		mkdocs serve -a 0.0.0.0:${DOCS_PORT:-8000}
		# mike serve -a 0.0.0.0:${DOCS_PORT:-8000}
	fi
	echo "[OK]: Done."
}

main
## --- Main --- ##
