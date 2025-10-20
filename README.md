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

## 🚸 Usage/Examples

### Setup server environment on **Ubuntu (20.04+), Debian (12.0+)**

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/ubuntu/setup-ubuntu.sh | bash -s -- -u -a
```

Or with other useful options:

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/ubuntu/setup-ubuntu.sh | bash -s -- \
    --upgrade \
    --hostname=my-server \
    --timezone=Asia/Seoul \
    --all-runtimes
```

### Create a new user and setup development environment on most **Linux**

Setup development environment for the current user:

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/setup-user.sh | bash -s -- -a
```

Create a new user and setup development environment:

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/setup-user.sh | bash -s -- \
    --user=user \
    --all-runtimes
```

Create a new user with sudo privileges, password and setup development environment:

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/linux/setup-user.sh | bash -s -- \
    --user=admin \
    --password="admin_pass123" \
    --sudo \
    --all-runtimes
```

### Setup development environment on **macOS**

Note: This script will install **Homebrew** and any other essential packages if not already installed.

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/macos/setup-macos.sh | bash -s -- -a
```

### Setup development environment on **Unix/Linux/macOS**

Note: This script will only install and setup user-level runtimes and configurations, not system-level packages. Thus it doesn't require root privileges.

```sh
curl -fsSL https://github.com/humblebeeai/script-common/raw/main/src/setup/unix/setup-user-env.sh | bash -s -- -a
```

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
- <https://www.shellcheck.net>
- <https://www.gnu.org/software/bash/manual/bash.html>
- <https://www.zsh.org>
- <https://ohmyz.sh>
- <https://github.com/romkatv/powerlevel10k>
- <https://drasite.com/blog/Pimp%20my%20terminal>
- <https://gnunn1.github.io/tilix-web>
- <https://sw.kovidgoyal.net/kitty>
- <https://iterm2.com>
- <https://github.com/microsoft/terminal>
- <https://mobaxterm.mobatek.net>
- <https://hyper.is>
- <https://termius.com>
- <https://termux.dev>
