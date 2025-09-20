# Install Go

This document explains how to use the `install-go.sh` script to install the Go programming language and configure its installation directory and version.

## install-go.sh

- `GO_VERSION` - Go version to install (default: `1.22.3`)
- `GO_INSTALL_DIR` - Go installation directory (default: `${HOME}/workspaces/runtimes/go`)

## Usage

Set variables before running the script:

```bash
GO_VERSION="1.22.3" ./install-go.sh
```

Or use a `.env` file:

```bash
# .env
GO_VERSION=1.22.3
GO_INSTALL_DIR=${HOME}/workspaces/runtimes/go
```

By setting `GO_INSTALL_DIR`, you can control where Go is installed. The script will use this path for all Go operations and output. After installation, add `${GO_INSTALL_DIR}/bin` to your `PATH` to use Go from the command line.
