# Install Miniconda

This document explains how to use the `install-miniconda.sh` script to install Miniconda, configure it, and optionally create a custom conda environment.

## install-miniconda.sh

- `MINICONDA_INSTALL_DIR` - Installation directory (default: `${HOME}/miniconda3`)
- `MINICONDA_AUTO_ACTIVATE` - Auto-activate base environment: `yes`/`no` (default: `no`)
- `MINICONDA_CREATE_ENV` - Create custom environment: `yes`/`no` (default: `yes`)
- `MINICONDA_PYTHON_VERSION` - Python version for custom environment (default: `3.11`)

## Usage

Set variables before running scripts:

```bash
MINICONDA_INSTALL_DIR="/opt/miniconda3" ./install-miniconda.sh
```

Or use a `.env` file:

```bash
# .env
MINICONDA_INSTALL_DIR=/opt/miniconda3
MINICONDA_AUTO_ACTIVATE=yes
MINICONDA_CREATE_ENV=yes
MINICONDA_PYTHON_VERSION=3.9
```
