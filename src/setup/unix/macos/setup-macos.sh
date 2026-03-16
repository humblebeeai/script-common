#!/usr/bin/env bash
set -euo pipefail


## --- Base --- ##
_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-"$0"}")" >/dev/null 2>&1 && pwd -P)"

# shellcheck disable=SC1091
[ -f .env ] && . .env

IS_REMOTE=${IS_REMOTE:-true}
cd "${_SCRIPT_DIR}" || exit 2
if [ "${IS_REMOTE}" = true ]; then
	echo "[INFO]: Running in REMOTE mode, fetching scripts from remote..."
else
	echo "[INFO]: Running in LOCAL mode, using local scripts..."
	_SOURCE_DIR="$(cd "${_SCRIPT_DIR}/../../../.." && pwd -P)"
	cd "${_SOURCE_DIR}" || exit 2
	echo "[INFO]: Current directory: $(pwd)"
fi


_OS="$(uname)"
if [ "${_OS}" != "Darwin" ]; then
	echo "[ERROR]: Unsupported OS '${_OS}', only 'macOS' is supported!" >&2
	exit 1
fi

if [ "${IS_REMOTE}" = true ]; then
	if ! command -v curl >/dev/null 2>&1; then
		echo "[ERROR]: 'curl' command not found or not installed!" >&2
		exit 1
	fi
fi

if [ "$(id -u)" -eq 0 ]; then
	echo "[ERROR]: Current user is 'root', please run this script as a normal user!" >&2
	exit 1
fi
## --- Base --- ##


## --- Variables --- ##
RUNTIMES=${RUNTIMES:-conda,nvm}
SCRIPT_BASE_URL="${SCRIPT_BASE_URL:-https://github.com/humblebeeai/script-common/raw/main/src}"
## --- Variables --- ##


## --- Menu arguments --- ##
_usage_help() {
	cat <<EOF
USAGE: ${0} [options]

OPTIONS:
    -r, --runtimes [RUNTIME1,RUNTIME2,...]    Comma-separated list of runtimes to install
                                                ('all', 'conda', 'nvm', 'rust', 'go', 'none'). Default: 'conda,nvm'.
    -h, --help                                Show help.

EXAMPLES:
    ${0} --runtimes all
EOF
}

while [ $# -gt 0 ]; do
	case "${1}" in
		-r | --runtimes)
			[ $# -ge 2 ] || { echo "[ERROR]: ${1} requires a value!" >&2; exit 1; }
			RUNTIMES="${2}"
			shift 2;;
		-r=* | --runtimes=*)
			RUNTIMES="${1#*=}"
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
_fetch()
{
	if [ -z "${1:-}" ]; then
		echo "[ERROR]: No script path provided to fetch!" >&2
		exit 1
	fi

	if [ "${IS_REMOTE}" = true ]; then
		curl -H 'Cache-Control: no-cache' \
			--retry 3 \
			--retry-delay 2 \
			--connect-timeout 10 \
			-fsSL \
			"${SCRIPT_BASE_URL}/${1}" || {
				echo "[ERROR]: Failed to fetch '${SCRIPT_BASE_URL}/${1}'!" >&2
				exit 1
			}
	else
		if [ ! -r "./${1}" ]; then
			echo "[ERROR]: Not found or not readable './${1}' file!" >&2
			exit 1
		fi

		cat "./${1}" || {
			echo "[ERROR]: Failed to read './${1}' file!" >&2
			exit 1
		}
	fi
}

main()
{
	echo ""
	echo "[INFO]: Setting up development environment on macOS..."

	if [ -z "${SCRIPT_BASE_URL}" ]; then
		echo "[ERROR]: SCRIPT_BASE_URL is empty!" >&2
		exit 1
	fi


	_fetch "setup/unix/macos/install-essentials.sh" | bash || {
		echo "[ERROR]: Failed to install essential packages!" >&2
		exit 2
	}

	_fetch "setup/unix/macos/install-nerd-fonts.sh" | bash || {
		echo "[WARN]: Failed to install Nerd Fonts, skipping!" >&2
	}

	_fetch "setup/unix/setup-user-env.sh" | \
		bash -s -- -r="${RUNTIMES}" || {
			echo "[ERROR]: Failed to setup user environment!" >&2
			exit 2
		}

	echo "[OK]: Successfully setup development environment on macOS."
	echo ""
}

main
## --- Main --- ##
