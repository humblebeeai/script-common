#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"
_PROJECT_DIR="$(cd "${_SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
cd "${_PROJECT_DIR}" || exit 2


if ! command -v python >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'python' command, please install it first!" >&2
	exit 1
fi

if ! command -v pre-commit >/dev/null 2>&1; then
	echo "[ERROR]: Not found 'pre-commit' command, please install it first!" >&2
	exit 1
fi

if [ ! -f .pre-commit-config.yaml ]; then
	echo "[ERROR]: '.pre-commit-config.yaml' file not found!" >&2
	exit 1
fi
## --- Base --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Running pre-commit hooks..."
	pre-commit run -a --color=always || exit 2
	echo "[OK]: Done."
}

main
## --- Main --- ##
