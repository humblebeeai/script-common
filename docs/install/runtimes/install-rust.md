# Install Rust

This document explains how to use the `install-rust.sh` script to install the Rust programming language via rustup and configure its installation directory and toolchain.

## install-rust.sh

- `RUST_INSTALL_DIR` - Rust/Cargo installation directory (default: `${HOME}/workspaces/runtimes/.cargo`)
- `RUST_TOOLCHAIN` - Rust toolchain to install (default: `stable`, options: `stable`/`beta`/`nightly`)
- `RUST_PROFILE` - Install profile (default: `default`, options: `minimal`/`default`/`complete`)

## Usage

Set variables before running the script:

```bash
RUST_TOOLCHAIN="stable" RUST_PROFILE="default" ./install-rust.sh
```

Or use a `.env` file:

```bash
# .env
RUST_INSTALL_DIR=$HOME/workspaces/runtimes/.cargo
RUST_TOOLCHAIN=stable
RUST_PROFILE=default
```

By setting `RUST_INSTALL_DIR`, you can control where Rust is installed. The script will use this path for all Rust operations and output. After installation, add `${RUST_INSTALL_DIR}/bin` to your `PATH` to use Rust from the command line.
