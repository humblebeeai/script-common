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

## 🚧 Prerequisites

- Bash 4.0+
- Standard utilities (curl/wget, git, etc.)
- Root access for system-level installations
- Unix-like OS:
    - **Linux** (Primary support - Ubuntu/Debian)
    - **macOS** (Full support with Homebrew)
    - Other Unix-like systems (limited support)

## 🚸 Usage/Examples

### Setup server environment on **Ubuntu [20.04+], Debian [12.0+]** (amd64/arm64/aarch64)

```sh
curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/ubuntu/setup-ubuntu.sh | \
    bash -s -- -u -a
```

Or with other useful options:

```sh
curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/linux/ubuntu/setup-ubuntu.sh | bash -s -- \
    --upgrade \
    --hostname=my-server \
    --timezone=Asia/Seoul \
    --all-runtimes
```

### Create a new user and setup development environment on most **Linux** (amd64/arm64/aarch64)

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

### Setup development environment on most **Linux** (amd64/arm64/aarch64)

```sh
curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/setup-user-env.sh | bash -s -- -a
```

### Setup development environment on **macOS** (intel/apple-silicon)

```sh
curl -fsSL https://raw.githubusercontent.com/humblebeeai/script-common/HEAD/src/setup/unix/macos/setup-macos.sh | bash -s -- -a
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
- <https://www.gnu.org/software/bash/manual/bash.html>
- <https://www.zsh.org>
- <https://ohmyz.sh>
