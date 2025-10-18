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
- Standard utilities (curl/wget, git, etc.)
- Root access for system-level installations
- Most Unix-like OS:
    - **Linux** (Primary support - Ubuntu/Debian)
    - **macOS** (Full support with Homebrew)
    - Other Unix-like systems (limited support)

## 🚸 Usage/Examples

### Setup server environment on **Ubuntu (20.04+), Debian (12.0+)**

```sh
curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/ubuntu/setup-ubuntu.sh | bash -s -- -u -a
```

Or with other useful options:

```sh
curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/ubuntu/setup-ubuntu.sh | bash -s -- \
    --upgrade \
    --hostname=my-server \
    --timezone=Asia/Seoul \
    --all-runtimes
```

### Create a new user and setup development environment on most **Linux**

Setup development environment for the current user:

```sh
curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/setup-user.sh | bash -s -- -a
```

Create a new user and setup development environment:

```sh
curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/setup-user.sh | bash -s -- \
    --user=user \
    --all-runtimes
```

Create a new user with sudo privileges, password and setup development environment:

```sh
curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/setup-user.sh | bash -s -- \
    --user=admin \
    --password="admin_pass123" \
    --sudo \
    --all-runtimes
```

### Setup development environment on **macOS**

Note: This script will install **Homebrew** and any other essential packages if not already installed.

```sh
curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/macos/setup-macos.sh | bash -s -- -a
```

### Setup development environment on **Unix/Linux/macOS**

Note: This script will only install and setup user-level runtimes and configurations, not system-level packages. Thus it doesn't require root privileges.

```sh
curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/setup-user-env.sh | bash -s -- -a
```

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
