# HBAI - Common Scripts

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit)
[![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/humblebeeai/script-common?logo=GitHub&color=blue)](https://github.com/humblebeeai/script-common/releases)

This repository contains a collection of common useful scripts.

## ✨ Features

- Shell scripts
- Setup and installation scripts
- Configuration scripts
- Preparation for environments
- Pre-configured for ease of use
- Account management scripts
- Cross-platform support (Unix/Linux/macOS)
- Multi-architecture support (amd64/arm64/aarch64/intel/apple-silicon)

## 🚧 Prerequisites

- Bash 4.0+
- Basic command-line tools (curl/wget, git, etc.)
- Internet connection for downloading packages
- Root access for system-level setup and account management
- Common Unix-like/Linux OS:
    - **Linux** (primary support - Ubuntu/Debian)
    - **macOS** (support with Homebrew)
    - Other Unix-like systems (limited support)

---

## 🔨 Scripts

### Setup - Ubuntu/Debian

| Script | Description | OS | Sudo | Docs |
|--------|--------------|----|------|------|
| `setup/unix/linux/ubuntu/setup-ubuntu.sh` | Run complete Ubuntu setup pipeline | Ubuntu/Debian | ✅ | [docs](./docs/setup/unix/linux/ubuntu/setup-ubuntu.md) |
| `setup/unix/linux/ubuntu/pre-setup-ubuntu.sh` | Pre-flight setup: update, locale, timezone, hostname, ulimit, umask | Ubuntu/Debian | ✅ | [docs](./docs/setup/unix/linux/ubuntu/pre-setup-ubuntu.md) |
| `setup/unix/linux/ubuntu/install-essentials.sh` | Install basic build tools & CLI utils | Ubuntu/Debian | ✅ | [docs](./docs/setup/unix/linux/ubuntu/install-essentials.md) |
| `setup/unix/linux/ubuntu/install-recommend.sh` | Install recommended extras (lsd, neovim, tailscale...) | Ubuntu/Debian | ✅ | [docs](./docs/setup/unix/linux/ubuntu/install-recommend.md) |
| `setup/unix/linux/ubuntu/setup-nvidia-container.sh` | Setup NVIDIA drivers & container runtime | Ubuntu/Debian | ✅ | [docs](./docs/setup/unix/linux/ubuntu/setup-nvidia-container.md) |

### Setup - Linux

| Script | Description | OS | Sudo | Docs |
|--------|--------------|----|------|------|
| `setup/unix/linux/setup-docker.sh` | Install and configure Docker | Linux | ✅ | [docs](./docs/setup/unix/linux/ubuntu/setup-docker.md) |
| `setup/unix/linux/setup-user.sh` | Create/configure dev user post-install | Linux | ✅ | [docs](./docs/setup/unix/linux/ubuntu/setup-user.md) |

### Setup - macOS

| Script | Description | OS | Sudo | Docs |
|--------|--------------|----|------|------|
| `setup/unix/macos/setup-macos.sh` | Run complete macOS dev setup | macOS | ✅ | [docs](./docs/setup/unix/macos/setup-macos.md) |
| `setup/unix/macos/install-essentials.sh` | Install Homebrew & core CLI tools | macOS | ✅ | [docs](./docs/setup/unix/macos/install-essentials.md) |

### Setup user environment (per-user)

| Script | Description | OS | Sudo | Docs |
|--------|--------------|----|------|------|
| `setup/unix/setup-user-env.sh` | Setup user development environment | Unix/Linux/macOS | ❌ | [docs](./docs/runtimes/setup-user-env.md) |
| `setup/unix/setup-user-workspaces.sh` | Create standard workspaces directories | Unix/Linux/macOS | ❌ | [docs](./docs/runtimes/setup-user-workspaces.md) |
| `setup/unix/setup-user-ohmyzsh.sh` | Install Oh My Zsh & plugins | Unix/Linux/macOS | ❌ | [docs](./docs/runtimes/setup-user-ohmyzsh.md) |
| `setup/unix/setup-user-dotfiles.sh` | Apply dotfiles/configs | Unix/Linux/macOS | ❌ | [docs](./docs/runtimes/setup-user-dotfiles.md) |
| `setup/unix/setup-user-nvchad.sh` | Install & setup NvChad for Neovim | Unix/Linux/macOS | ❌ | [docs](./docs/runtimes/setup-user-nvchad.md) |

### Setup user runtimes (per-user)

| `setup/unix/runtimes/install-user-miniconda.sh` | Install Miniconda and Python | Unix/Linux/macOS | ❌ | [docs](./docs/runtimes/install-user-miniconda.md) |
| `setup/unix/runtimes/install-user-nvm.sh` | Install NVM and Node.js | Unix/Linux/macOS | ❌ | [docs](./docs/runtimes/install-user-nvm.md) |
| `setup/unix/runtimes/install-user-rust.sh` | Install Rust toolchain and runtime | Unix/Linux/macOS | ❌ | [docs](./docs/runtimes/install-user-rust.md) |
| `setup/unix/runtimes/install-user-go.sh` | Install Go runtime | Unix/Linux/macOS | ❌ | [docs](./docs/runtimes/install-user-go.md) |

### ⚙️ Account management (Linux)

| Script | Description | OS | Sudo | Docs |
|--------|--------------|----|------|------|
| `account/unix/linux/create-group.sh` | Create a new system group | Linux | ✅ | [docs](./docs/account/unix/linux/create-group.md) |
| `account/unix/linux/create-user.sh` | Create a new user with home and shell | Linux | ✅ | [docs](./docs/account/unix/linux/create-user.md) |
| `account/unix/linux/change-password.sh` | Change a user password non-interactively | Linux | ✅ | [docs](./docs/account/unix/linux/change-password.md) |
| `account/unix/linux/change-user-pgroup.sh` | Change users' primary group | Linux | ✅ | [docs](./docs/account/unix/linux/change-user-pgroup.md) |
| `account/unix/linux/add-user-group.sh` | Add existing users to a group | Linux | ✅ | [docs](./docs/account/unix/linux/add-user-group.md) |
| `account/unix/linux/delete-user.sh` | Delete a user | Linux | ✅ | [docs](./docs/account/unix/linux/delete-user.md) |

---

## 🚸 Usage/Examples

### Setup server environment on **Ubuntu (20.04+), Debian (12.0+)**

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/ubuntu/setup-ubuntu.sh | bash -s -- -u -r all
```

Or with other useful options:

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/ubuntu/setup-ubuntu.sh | bash -s -- \
    --upgrade \
    --hostname=my-server \
    --timezone=Asia/Seoul \
    --runtimes=all
```

### Create a new user and setup development environment on most **Linux**

Setup development environment for the current user:

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/setup-user.sh | bash -s -- -r all
```

Create a new user and setup development environment:

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/setup-user.sh | bash -s -- \
    --user=user \
    --runtimes=all
```

Create a new user with sudo privileges, password and setup development environment:

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/setup-user.sh | bash -s -- \
    --user=admin \
    --password="admin_pass123" \
    --sudo \
    --runtimes=all
```

### Setup development environment on **macOS**

Note: This script will install **Homebrew** and any other essential packages if not already installed.

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/macos/setup-macos.sh | bash -s -- -r all
```

### Setup development environment on **Unix/Linux/macOS**

Note: This script will only install and setup user-level runtimes and configurations, not system-level packages. Thus it doesn't require root privileges.

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/setup-user-env.sh | bash -s -- -r all
```
