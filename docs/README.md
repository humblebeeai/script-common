---
title: Home
hide:
  - navigation
#   - toc
---

# Home

## Scripts Overview

### 🛠️ System Setup

- **setup-user-groups.sh** - Create users and groups | [📖 docs](./setup/setup-user-groups.md)
- **setup-dir-structure.sh** - Create workspace directory structure | [📖 docs](./setup/setup-dir-structure.md)

### 📦 Installation Scripts

- **install-essentials.sh** - Install essential system packages | [📖 docs](./install/install-essentials.md)
- **install-docker.sh** - Install Docker with logging & data directory config | [📖 docs](./install/install-docker.md)
- **install-ohmyzsh.sh** - Install Oh My Zsh with plugins | [📖 docs](./install/install-ohmyzsh.md)

### 🚀 Runtime Environments

- **install-go.sh** - Install Go programming language | [📖 docs](./install/runtimes/install-go.md)
- **install-rust.sh** - Install Rust via rustup | [📖 docs](./install/runtimes/install-rust.md)
- **install-nvm.sh** - Install Node Version Manager | [📖 docs](./install/runtimes/install-nvm.md)
- **install-miniconda.sh** - Install Miniconda Python distribution | [📖 docs](./install/runtimes/install-miniconda.md)

## Quick Start

```bash
# Clone and navigate to scripts
git clone <repository-url>
cd script.common

# Make scripts executable
chmod +x src/**/*.sh

# Install essential packages
./src/install/install-essentials.sh

# Create workspace structure
./src/setup/setup-dir-structure.sh

# Install development tools
./src/install/runtimes/install-go.sh
./src/install/runtimes/install-rust.sh
./src/install/install-docker.sh
```

## Configuration

All scripts support configuration via `.env` files. Place `.env` in:

- Script directory
- Parent directory of script
- Current working directory

Example `.env`:

```bash
# Workspace configuration
WORKSPACE_BASE_DIR=/home/user/workspaces

# Runtime versions
GO_VERSION=1.22.3
RUST_TOOLCHAIN=stable
NODE_VERSION=20

# Docker settings
CONFIGURE_DOCKER_LOGGING=yes
DOCKER_LOG_MAX_SIZE=50m
```

## Script Standards

All scripts follow a consistent three-section structure:

- **Base**: Initialization, dependency checks, OS detection
- **Variables**: Configurable environment variables with defaults
- **Main**: Core functionality in organized functions

See **coding standards** for detailed guidelines.

## Platform Support

- **Linux**: Ubuntu/Debian (primary support)
- **macOS**: Full support with Homebrew
- **Other**: Limited support, may require modifications

## Requirements

- Bash 4.0+
- Standard Unix utilities (curl/wget, git, etc.)
- Root access for system-level installations
