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
case "${_OS}" in
	Linux | Darwin) : ;;
	*) echo "[ERROR]: Unsupported OS '${_OS}', only 'Linux' and 'macOS' are supported!" >&2; exit 1;;
esac

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

if [ -z "${HOME:-}" ]; then
	echo "[ERROR]: HOME environment variable is not set!" >&2
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
    -r, --runtimes [RUNTIME1,RUNTIME2,...]    Comma-separated list of runtimes to install ('conda', 'nvm', 'rust', 'go'). Default: 'conda,nvm'.
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
	echo "[INFO]: Setting up user development environment..."

	if [ -z "${SCRIPT_BASE_URL}" ]; then
		echo "[ERROR]: SCRIPT_BASE_URL is empty!" >&2
		exit 1
	fi


	_fetch "setup/unix/setup-user-workspaces.sh" | bash || {
		echo "[ERROR]: Failed to create workspaces!" >&2
		exit 2
	}

	_fetch "setup/unix/setup-user-ohmyzsh.sh" | bash || {
		echo "[ERROR]: Failed to install 'oh-my-zsh'!" >&2
		exit 2
	}

	_fetch "setup/unix/setup-user-dotfiles.sh" | bash || {
		echo "[ERROR]: Failed to setup configs!" >&2
		exit 2
	}

	if [ "${RUNTIMES}" = "all" ]; then
		RUNTIMES="conda,nvm,rust,go"
	elif [ "${RUNTIMES}" = "basic" ]; then
		RUNTIMES="conda,nvm"
	elif [ "${RUNTIMES}" = "none" ]; then
		RUNTIMES=""
	fi

	if [ -n "${RUNTIMES}" ]; then
		echo "[INFO]: Installing runtimes..."
		local _runtimes_arr
		IFS=',' read -r -a _runtimes_arr <<< "${RUNTIMES}"
		local _runtime
		for _runtime in "${_runtimes_arr[@]}"; do
			case "${_runtime}" in
				conda)
					_fetch "setup/unix/runtimes/install-user-miniconda.sh" | bash || {
						echo "[WARN]: Failed to install 'Miniconda', skipping!" >&2
					}
					continue;;
				nvm)
					_fetch "setup/unix/runtimes/install-user-nvm.sh" | bash || {
						echo "[WARN]: Failed to install 'NVM', skipping!" >&2
					}
					continue;;
				rust)
					_fetch "setup/unix/runtimes/install-user-rust.sh" | bash || {
						echo "[WARN]: Failed to install 'Rust', skipping!" >&2
					}
					continue;;
				go)
					_fetch "setup/unix/runtimes/install-user-go.sh" | bash || {
						echo "[WARN]: Failed to install 'Go', skipping!" >&2
					}
					continue;;
				*)
					echo "[ERROR]: Unsupported runtimes option '${_runtime}'!" >&2
					exit 1;;
			esac
		done
		echo "[OK]: Done."
	fi

	_fetch "setup/unix/setup-user-nvchad.sh" | bash || {
		echo "[WARN]: Failed to setup 'NvChad', skipping!" >&2
	}

	echo "[OK]: Successfully setup user development environment!"
	echo ""
}

main
## --- Main --- ##
