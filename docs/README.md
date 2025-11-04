---
title: Home
hide:
  - navigation
#   - toc
---

# Home

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
- Supports common Unix-like/Linux OS:
    - **Linux** (primary support - Ubuntu/Debian)
    - **macOS** (support with Homebrew)
    - Other Unix-like systems (limited support)

---

## 🔨 Scripts

### 🔄 Setup - Ubuntu/Debian

| Script | Description | OS | Sudo |
|--------|--------------|----|------|
| [`setup/unix/linux/ubuntu/setup-ubuntu.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/ubuntu/setup-ubuntu.sh) | Run complete Ubuntu setup pipeline | Ubuntu/Debian | ✅ |
| [`setup/unix/linux/ubuntu/pre-setup-ubuntu.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/ubuntu/pre-setup-ubuntu.sh) | Pre-flight setup: update, locale, timezone, hostname, ulimit, umask | Ubuntu/Debian | ✅ |
| [`setup/unix/linux/ubuntu/install-essentials.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/ubuntu/install-essentials.sh) | Install basic build tools & CLI utils | Ubuntu/Debian | ✅ |
| [`setup/unix/linux/ubuntu/install-recommend.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/ubuntu/install-recommend.sh) | Install recommended extras (lsd, neovim, tailscale...) | Ubuntu/Debian | ✅ |
| [`setup/unix/linux/ubuntu/setup-nvidia-container.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/ubuntu/setup-nvidia-container.sh) | Setup NVIDIA container toolkit runtime | Ubuntu/Debian | ✅ |

### 🐧 Setup - Linux

| Script | Description | OS | Sudo |
|--------|--------------|----|------|
| [`setup/unix/linux/setup-docker.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/setup-docker.sh) | Install and configure Docker | Linux | ✅ |
| [`setup/unix/linux/setup-user.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/setup-user.sh) | Create/configure dev user post-install | Linux | ✅ |

### 🍎 Setup - macOS

| Script | Description | OS | Sudo |
|--------|--------------|----|------|
| [`setup/unix/macos/setup-macos.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/macos/setup-macos.sh) | Run complete macOS dev setup | macOS | ✅ |
| [`setup/unix/macos/install-essentials.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/macos/install-essentials.sh) | Install Homebrew & core CLI tools | macOS | ✅ |

### 👨‍💻 Setup user environment (per-user)

| Script | Description | OS | Sudo |
|--------|--------------|----|------|
| [`setup/unix/setup-user-env.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/setup-user-env.sh) | Setup user development environment | Unix/Linux/macOS | ❌ |
| [`setup/unix/setup-user-workspaces.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/setup-user-workspaces.sh) | Create standard workspaces directories | Unix/Linux/macOS | ❌ |
| [`setup/unix/setup-user-ohmyzsh.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/setup-user-ohmyzsh.sh) | Install Oh My Zsh & plugins | Unix/Linux/macOS | ❌ |
| [`setup/unix/setup-user-dotfiles.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/setup-user-dotfiles.sh) | Apply dotfiles/configs | Unix/Linux/macOS | ❌ |
| [`setup/unix/setup-user-nvchad.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/setup-user-nvchad.sh) | Install & setup NvChad for Neovim | Unix/Linux/macOS | ❌ |

### 🏃 Setup user runtimes (per-user)

| Script | Description | OS | Sudo |
|--------|--------------|----|------|
| [`setup/unix/runtimes/install-user-miniconda.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/runtimes/install-user-miniconda.sh) | Install Miniconda and Python | Unix/Linux/macOS | ❌ |
| [`setup/unix/runtimes/install-user-nvm.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/runtimes/install-user-nvm.sh) | Install NVM and Node.js | Unix/Linux/macOS | ❌ |
| [`setup/unix/runtimes/install-user-rust.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/runtimes/install-user-rust.sh) | Install Rust toolchain and runtime | Unix/Linux/macOS | ❌ |
| [`setup/unix/runtimes/install-user-go.sh`](https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/runtimes/install-user-go.sh) | Install Go runtime | Unix/Linux/macOS | ❌ |

### 👥 Account management (Linux)

| Script | Description | OS | Sudo |
|--------|--------------|----|------|
| [`account/unix/linux/create-group.sh`](https://github.com/humblebeeai/script-common/raw/main/src/account/unix/linux/create-group.sh) | Create a new system group | Linux | ✅ |
| [`account/unix/linux/create-user.sh`](https://github.com/humblebeeai/script-common/raw/main/src/account/unix/linux/create-user.sh) | Create a new user with home and shell | Linux | ✅ |
| [`account/unix/linux/change-user-password.sh`](https://github.com/humblebeeai/script-common/raw/main/src/account/unix/linux/change-user-password.sh) | Change a user password non-interactively | Linux | ✅ |
| [`account/unix/linux/change-users-pgroup.sh`](https://github.com/humblebeeai/script-common/raw/main/src/account/unix/linux/change-users-pgroup.sh) | Change users' primary group | Linux | ✅ |
| [`account/unix/linux/add-users-group.sh`](https://github.com/humblebeeai/script-common/raw/main/src/account/unix/linux/add-users-group.sh) | Add existing users to a group | Linux | ✅ |
| [`account/unix/linux/delete-users.sh`](https://github.com/humblebeeai/script-common/raw/main/src/account/unix/linux/delete-users.sh) | Delete a user | Linux | ✅ |

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
