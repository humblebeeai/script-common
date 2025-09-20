#!/bin/bash

set -euo pipefail

## --- Base --- ##

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Check for required dependencies
if ! command -v wget >/dev/null 2>&1; then
    echo "[ERROR]: Required command 'wget' not found!" >&2
    exit 1
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR]: This script must be run as root (use sudo)" >&2
    exit 1
fi

# OS detection (Linux only)
_OS="$(uname -s)"
if [ "${_OS}" != "Linux" ]; then
    echo "[ERROR]: This script supports Linux only." >&2
    exit 1
fi

# Load .env if present
# shellcheck disable=SC1091
if [ -f "${_SCRIPT_DIR}/../.env" ]; then
    source "${_SCRIPT_DIR}/../.env"
elif [ -f "${_SCRIPT_DIR}/.env" ]; then
    source "${_SCRIPT_DIR}/.env"
elif [ -f .env ]; then
    source .env
fi

## --- Variables --- ##

ADD_CURRENT_USER_TO_DOCKER=${ADD_CURRENT_USER_TO_DOCKER:-"yes"} # yes/no
CONFIGURE_DOCKER_LOGGING=${CONFIGURE_DOCKER_LOGGING:-"yes"}     # yes/no
DOCKER_LOG_MAX_SIZE=${DOCKER_LOG_MAX_SIZE:-"10m"}               # log file max size
DOCKER_LOG_MAX_FILE=${DOCKER_LOG_MAX_FILE:-"10"}                # max log rotation files
CONFIGURE_DOCKER_DATA_ROOT=${CONFIGURE_DOCKER_DATA_ROOT:-"no"}  # yes/no - configure custom data directory
DOCKER_DATA_ROOT_PATH=${DOCKER_DATA_ROOT_PATH:-""}              # path to custom Docker data directory

## --- Main --- ##

remove_conflicting_packages()
{
    echo "[INFO]: Removing conflicting Docker packages..."
    
    local _conflicting_packages="docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc"
    
    for pkg in ${_conflicting_packages}; do
        if dpkg -l | grep -q "^ii.*${pkg}"; then
            echo "[INFO]: Removing conflicting package: ${pkg}"
            apt-get remove -y "${pkg}" || true
        fi
    done
    
    echo -e "[OK]: Done.\n"
}

install_docker()
{
    echo "[INFO]: Installing Docker using official script..."
    
    local _installer_script="/tmp/get-docker.sh"
    
    # Download Docker's official installation script
    echo "[INFO]: Downloading Docker installation script..."
    wget https://get.docker.com -O "${_installer_script}" || exit 2
    
    # Run the installation script
    echo "[INFO]: Running Docker installation script..."
    sh "${_installer_script}" || exit 2
    
    # Clean up
    rm -f "${_installer_script}"
    
    echo -e "[OK]: Done.\n"
}

configure_docker_user()
{
    if [ "${ADD_CURRENT_USER_TO_DOCKER}" != "yes" ]; then
        echo "[INFO]: Skipping user group configuration"
        return 0
    fi
    
    # Get the original user (the one who ran sudo)
    local _original_user="${SUDO_USER:-}"
    
    if [ -z "${_original_user}" ]; then
        echo "[INFO]: No original user found, skipping group addition"
        return 0
    fi
    
    echo "[INFO]: Configuring Docker for user '${_original_user}'..."
    
    # Create docker group (may already exist)
    groupadd -f docker || exit 2
    
    # Add user to docker group
    usermod -aG docker "${_original_user}" || exit 2
    
    echo "[INFO]: User '${_original_user}' added to docker group"
    echo "[INFO]: User will need to log out and back in for group changes to take effect"
    
    echo -e "[OK]: Done.\n"
}

configure_docker_daemon()
{
    # Check if any daemon configuration is needed
    local _needs_config="no"
    if [ "${CONFIGURE_DOCKER_LOGGING}" = "yes" ] || [ "${CONFIGURE_DOCKER_DATA_ROOT}" = "yes" ]; then
        _needs_config="yes"
    fi
    
    if [ "${_needs_config}" != "yes" ]; then
        echo "[INFO]: Skipping Docker daemon configuration"
        return 0
    fi
    
    echo "[INFO]: Configuring Docker daemon..."
    
    local _docker_dir="/etc/docker"
    local _daemon_config="${_docker_dir}/daemon.json"
    
    # Create /etc/docker directory if it doesn't exist
    mkdir -p "${_docker_dir}" || exit 2
    
    # Validate data root path if configured
    if [ "${CONFIGURE_DOCKER_DATA_ROOT}" = "yes" ]; then
        if [ -z "${DOCKER_DATA_ROOT_PATH}" ]; then
            echo "[ERROR]: DOCKER_DATA_ROOT_PATH must be set when CONFIGURE_DOCKER_DATA_ROOT=yes" >&2
            exit 2
        fi
        
        # Create the data root directory if it doesn't exist
        echo "[INFO]: Creating Docker data directory: ${DOCKER_DATA_ROOT_PATH}"
        mkdir -p "${DOCKER_DATA_ROOT_PATH}" || exit 2
        
        # Set proper ownership and permissions
        chown root:root "${DOCKER_DATA_ROOT_PATH}" || exit 2
        chmod 755 "${DOCKER_DATA_ROOT_PATH}" || exit 2
    fi
    
        # Stop Docker service before applying configuration changes
        echo "[INFO]: Stopping Docker service to apply configuration..."
        systemctl stop docker || exit 2
        
        # Build daemon.json configuration
        echo "[INFO]: Building daemon.json configuration..."
        
        # Build the configuration content in a variable
        local _config="{"
        
        # Add data-root configuration if enabled
        if [ "${CONFIGURE_DOCKER_DATA_ROOT}" = "yes" ]; then
            _config="${_config}
      \"data-root\": \"${DOCKER_DATA_ROOT_PATH}\""
            if [ "${CONFIGURE_DOCKER_LOGGING}" = "yes" ]; then
                _config="${_config},"
            fi
        fi
        
        # Add logging configuration if enabled
        if [ "${CONFIGURE_DOCKER_LOGGING}" = "yes" ]; then
            _config="${_config}
      \"log-driver\": \"json-file\",
      \"log-opts\": {
        \"max-size\": \"${DOCKER_LOG_MAX_SIZE}\",
        \"max-file\": \"${DOCKER_LOG_MAX_FILE}\"
      }"
        fi
        
        # Close JSON
        _config="${_config}
    }"
        
        # Write the configuration to file
        echo "${_config}" > "${_daemon_config}"
        
        # Display configuration summary
        echo "[INFO]: Docker daemon configuration updated:"
        if [ "${CONFIGURE_DOCKER_DATA_ROOT}" = "yes" ]; then
            echo "[INFO]: - Data root: ${DOCKER_DATA_ROOT_PATH}"
        fi
        if [ "${CONFIGURE_DOCKER_LOGGING}" = "yes" ]; then
            echo "[INFO]: - Log driver: json-file"
            echo "[INFO]: - Max file size: ${DOCKER_LOG_MAX_SIZE}"
            echo "[INFO]: - Max files: ${DOCKER_LOG_MAX_FILE}"
        fi
        echo "[INFO]: Configuration saved to: ${_daemon_config}"
        
        # Start Docker daemon to apply changes
        echo "[INFO]: Starting Docker daemon with new configuration..."
        systemctl start docker || exit 2
    
    echo -e "[OK]: Done.\n"
}

test_docker_installation()
{
    echo "[INFO]: Testing Docker installation..."
    
    # Test Docker version
    if docker --version >/dev/null 2>&1; then
        echo "[INFO]: Docker version: $(docker --version)"
    else
        echo "[ERROR]: Docker command not working" >&2
        exit 2
    fi
    
    # Test Docker Compose plugin
    if docker compose version >/dev/null 2>&1; then
        echo "[INFO]: Docker Compose plugin: $(docker compose version --short 2>/dev/null || docker compose version)"
    else
        echo "[WARNING]: Docker Compose plugin not available"
    fi
    
    # Test Docker hello-world
    echo "[INFO]: Running Docker hello-world test..."
    if docker run --rm hello-world >/dev/null 2>&1; then
        echo "[INFO]: Docker hello-world test passed"
    else
        echo "[WARNING]: Docker hello-world test failed (this may be normal if internet is restricted)"
    fi
    
    echo -e "[OK]: Done.\n"
}

main()
{
    echo "[INFO]: Setting up Docker..."

    # Remove conflicting packages
    remove_conflicting_packages

    # Install Docker using official script
    install_docker

    # Configure Docker for current user
    configure_docker_user
    
    # Configure Docker daemon (logging and data root)
    configure_docker_daemon

    # Test installation
    test_docker_installation

    echo -e "[OK]: Docker setup completed successfully!"
    echo "[INFO]: Docker is ready to use"
    
    if [ "${ADD_CURRENT_USER_TO_DOCKER}" = "yes" ] && [ -n "${SUDO_USER:-}" ]; then
        echo "[INFO]: User '${SUDO_USER}' needs to log out and back in to use Docker without sudo"
        echo "[INFO]: Or run 'newgrp docker' in the current session"
    fi
}

main "${@:-}"