#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
_PROJECT_DIR="$(cd "${_SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
cd "${_PROJECT_DIR}" || exit 2


if ! command -v gh >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'gh' command, please install it first!" >&2
	exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
	echo "[ERROR]: You need to login: 'gh auth login'!" >&2
	exit 1
fi
## --- Base --- ##


## --- Main --- ##
main()
{
	local _current_version
	_current_version="$(./scripts/get-version.sh)"
	echo "[INFO]: Creating release for version: 'v${_current_version}'..."
	gh release create "v${_current_version}" --generate-notes
	echo "[OK]: Done."
}

main
## --- Main --- ##
