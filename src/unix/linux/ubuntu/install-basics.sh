#!/bin/bash
set -euo pipefail


## --- Base --- ##
# Getting path of this script file:
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
_PROJECT_DIR="$(cd "${_SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
cd "${_PROJECT_DIR}" || exit 2


# Loading .env file (if exists):
if [ -f ".env" ]; then
	# shellcheck disable=SC1091
	source .env
fi
## --- Base --- ##


## --- Main --- ##
main()
{
	echo "[INFO]: Installing basic packages..."
	sudo apt update --fix-missing -o Acquire::CompressionTypes::Order::=gz || exit 2
	sudo apt upgrade -y || exit 2
	sudo apt install -y \
		ca-certificates \
		build-essential \
		cmake \
		locales \
		iputils-ping \
		net-tools \
		iproute2 \
		wget \
		curl \
		ssh \
		git-lfs \
		rsync \
		unzip \
		zip \
		vim \
		nano \
		jq \
		htop \
		ncdu \
		pydf \
		zsh || exit 2

	sudo apt autoremove -y || exit 2
	sudo apt clean || exit 2
	echo -e "[OK]: Done.\n"
}


main "${@:-}"
## --- Main --- ##
