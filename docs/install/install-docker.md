# Install Docker

Install Docker on Linux using Docker's official installation script with automatic log rotation setup and optional custom data directory.

## Usage

```bash
# Basic installation
sudo ./install-docker.sh

# Skip Docker logging configuration
sudo CONFIGURE_DOCKER_LOGGING="no" ./install-docker.sh

# Custom log settings
sudo DOCKER_LOG_MAX_SIZE="10m" DOCKER_LOG_MAX_FILE="10" ./install-docker.sh

# Configure custom Docker data directory
sudo CONFIGURE_DOCKER_DATA_ROOT="yes" DOCKER_DATA_ROOT_PATH="/mnt/ssd/1/docker/data-root" ./install-docker.sh

# Full customization example
sudo CONFIGURE_DOCKER_DATA_ROOT="yes" DOCKER_DATA_ROOT_PATH="/mnt/external/docker" \
     DOCKER_LOG_MAX_SIZE="10m" DOCKER_LOG_MAX_FILE="10" ./install-docker.sh
```

## Configuration

- `ADD_CURRENT_USER_TO_DOCKER` - Add current user to docker group (default: "yes")
- `CONFIGURE_DOCKER_LOGGING` - Configure Docker log rotation (default: "yes")
- `DOCKER_LOG_MAX_SIZE` - Maximum size per log file (default: "10m")
- `DOCKER_LOG_MAX_FILE` - Maximum number of rotated log files (default: "10")
- `CONFIGURE_DOCKER_DATA_ROOT` - Configure custom Docker data directory (default: "no")
- `DOCKER_DATA_ROOT_PATH` - Path to custom Docker data directory (required if CONFIGURE_DOCKER_DATA_ROOT="yes")

## What It Does

1. **Clean up**: Removes conflicting packages (docker.io, docker-compose, etc.)
2. **Install**: Downloads and runs Docker's official installation script from get.docker.com
3. **Configure**: Adds current user to docker group for sudo-free usage
4. **Daemon Setup**: Configures Docker daemon with log rotation and optional custom data directory
5. **Test**: Verifies Docker and Docker Compose plugin work

## Requirements

- Linux system with internet access
- Run with `sudo`

## After Installation

```bash
# Verify installation
docker --version
docker compose version

# Test Docker (logout/login first, or run: newgrp docker)
docker run hello-world
```

**Note**: Users must logout/login (or run `newgrp docker`) to use Docker without sudo.

## Docker Data Directory (Optional)

By default, Docker stores all data in `/var/lib/docker`. You can optionally configure a custom data directory, typically for:

- **External Storage**: Move Docker data to external drives or mounted storage
- **Performance**: Use faster storage (SSD) for Docker operations  
- **Space Management**: Use larger storage volumes for Docker data

To configure a custom data directory:

```bash
sudo CONFIGURE_DOCKER_DATA_ROOT="yes" DOCKER_DATA_ROOT_PATH="/mnt/ssd/1/docker/data-root" ./install-docker.sh
```

**Important**:

- The data directory will be created if it doesn't exist
- Docker service will be stopped and restarted during configuration
- Ensure the storage is properly mounted before running the script

## Docker Logging

The script automatically configures Docker with log rotation to prevent logs from consuming unlimited disk space:

- **Log Driver**: Uses `json-file` driver for structured logging
- **Max Size**: Limits each log file to 10MB (configurable)
- **Rotation**: Keeps 10 rotated files (configurable)
- **Location**: Configuration saved to `/etc/docker/daemon.json`

To disable logging configuration:

```bash
sudo CONFIGURE_DOCKER_LOGGING="no" ./install-docker.sh
```

## Manual Steps (Reference)

The script automates these Docker installation steps:

```bash
# Remove conflicting packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
    sudo apt-get remove $pkg
done

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh

# Post-installation
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```
