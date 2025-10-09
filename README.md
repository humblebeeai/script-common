# HBAI - Common Scripts

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/humblebeeai/script-common?logo=GitHub&color=blue)](https://github.com/humblebeeai/script-common/releases)

This repository contains a collection of common scripts.

## ✨ Features

- Shell scripts
- Setup and installation scripts
- Configuration scripts
- Preparation for environments
- Pre-configured for ease of use

## 🐤 Getting Started

### 1. 🚧 Prerequisites

[OPTIONAL] For **DEVELOPMENT** environment:

- Install [**git**](https://git-scm.com/downloads)
- Setup an [**SSH key**](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh)

### 2. 📥 Download or clone the repository

**2.1.** Prepare projects directory (if not exists):

```sh
# Create projects directory:
mkdir -pv ~/workspaces/projects

# Enter into projects directory:
cd ~/workspaces/projects
```

**2.2.** Follow one of the below options **[A]**, **[B]** or **[C]**:

**OPTION A.** Clone the repository:

```sh
git clone https://github.com/humblebeeai/script-common.git && \
    cd script-common
```

**OPTION B.** Clone the repository (for **DEVELOPMENT**: git + ssh key):

```sh
git clone git@github.com:humblebeeai/script-common.git && \
    cd script-common
```

**OPTION C.** Download source code:

1. Download archived **zip** or **tar.gz** file from [**releases**](https://github.com/humblebeeai/script-common/releases).
2. Extract it into the projects directory.
3. Enter into the project directory.

## Scripts Overview

### 🛠️ System Setup

- **[setup-user-groups.sh](src/setup/setup-user-groups.sh)** - Create users and groups | [📖 docs](docs/setup/setup-user-groups.md)
- **[setup-dir-structure.sh](src/setup/setup-dir-structure.sh)** - Create workspace directory structure | [📖 docs](docs/setup/setup-dir-structure.md)

### 📦 Installation Scripts

- **[install-essentials.sh](src/install/install-essentials.sh)** - Install essential system packages | [📖 docs](docs/install/install-essentials.md)
- **[install-docker.sh](src/install/install-docker.sh)** - Install Docker with logging & data directory config | [📖 docs](docs/install/install-docker.md)
- **[install-ohmyzsh.sh](src/install/install-ohmyzsh.sh)** - Install Oh My Zsh with plugins | [📖 docs](docs/install/install-ohmyzsh.md)

### 🚀 Runtime Environments

- **[install-go.sh](src/install/runtimes/install-go.sh)** - Install Go programming language | [📖 docs](docs/install/runtimes/install-go.md)
- **[install-rust.sh](src/install/runtimes/install-rust.sh)** - Install Rust via rustup | [📖 docs](docs/install/runtimes/install-rust.md)
- **[install-nvm.sh](src/install/runtimes/install-nvm.sh)** - Install Node Version Manager | [📖 docs](docs/install/runtimes/install-nvm.md)
- **[install-miniconda.sh](src/install/runtimes/install-miniconda.sh)** - Install Miniconda Python distribution | [📖 docs](docs/install/runtimes/install-miniconda.md)

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

See [coding standards](.vscode/copilot-instructions.md) for detailed guidelines.

## Platform Support

- **Linux**: Ubuntu/Debian (primary support)
- **macOS**: Full support with Homebrew
- **Other**: Limited support, may require modifications

## Requirements

- Bash 4.0+
- Standard Unix utilities (curl/wget, git, etc.)
- Root access for system-level installations

---

## 📝 Generate Docs

To build the documentation, run the following command:

```sh
# Install python documentation dependencies:
pip install -r ./requirements.txt

# Serve documentation locally (for development):
./src/docs.sh
# Or:
mkdocs serve -a 0.0.0.0:8000

# Or build documentation:
./src/docs.sh -b
# Or:
mkdocs build
```

## 📚 Documentation

- [Docs](./docs)

---

## 📑 References

- <https://www.shellscript.sh>
- <https://www.gnu.org/software/bash/manual/bash.html>
- <https://www.zsh.org>
- <https://ohmyz.sh>
