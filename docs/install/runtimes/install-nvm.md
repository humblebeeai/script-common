# Install NVM

This document explains how to use the `install-nvm.sh` script to install NVM (Node Version Manager) and optionally install a specific Node.js version.

## install-nvm.sh

- `NVM_INSTALL_DIR` - NVM installation directory (default: `${HOME}/workspaces/runtimes/.nvm`)

## Usage

Set variables before running scripts:

```bash
NVM_VERSION="0.39.0" NODE_VERSION="18" ./install-nvm.sh
```

Or use a `.env` file:

```bash
# .env
NVM_VERSION=0.39.0
NODE_VERSION=18
NVM_INSTALL_DIR="$HOME/workspaces/runtimes/.nvm"
```

By setting `NVM_INSTALL_DIR`, you can control where NVM is installed. The script will use this path for all NVM operations and output.
