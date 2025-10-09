# Install Essential System Binaries

This document explains how to use the `install-essentials.sh` script to install essential command-line tools and utilities on a newly created system. The script supports both Ubuntu/Debian and macOS systems.

## install-essentials.sh

The script organizes packages into logical categories. You can specify which categories to install as command-line arguments.

## Available Categories

- [base](#️-base-system-install_base) - Base system utilities (**always recommended**)
- [monitoring](#-monitoring--performance-install_monitoring) - Monitoring & performance tools
- [networking](#-networking--diagnostics-install_networking) - Networking & diagnostics tools
- [compression](#-compression--archiving-install_compression) - Compression & archiving tools
- [development](#️-development-tools-install_development) - Development tools
- [file-utils](#-file--search-utilities-install_file_utils) - File & search utilities
- [productivity](#-cli-productivity--ux-install_productivity) - CLI productivity & UX tools

## Package Categories

### 🏗️ Base System (INSTALL_BASE)

#### **Always installed by default - essential for any system**

```bash
curl, wget, git, vim, htop, rsync, screen, tmux, ncdu, build-essential*
```

```bash
# curl           - transfer data from/to servers (HTTP, FTP, etc.)
# wget           - download files from web servers
# git            - distributed version control system
# vim            - powerful text editor
# htop           - interactive process viewer (better than top)
# rsync          - efficient file synchronization tool
# screen         - terminal multiplexer for persistent sessions
# tmux           - modern terminal multiplexer with split panes
# ncdu           - disk usage analyzer with ncurses interface
# build-essential - compilation tools (gcc, make, etc.) *Linux only
```

---

### 🔍 Monitoring & Performance (INSTALL_MONITORING)

```bash
lsof, strace, iotop*, iftop*, bmon*, dstat, sysstat*, pv, moreutils
```

```bash
# lsof       - list open files and processes using them
# strace     - trace system calls and signals of a process
# iotop      - monitor real-time disk I/O usage by process *Linux only
# iftop      - monitor real-time network traffic per connection *Linux only
# bmon       - bandwidth monitor with graphical interface *Linux only
# dstat      - versatile system resource statistics tool
# sysstat    - collection of performance monitoring tools (sar, iostat, etc.) *Linux only
# pv         - monitor progress of data through a pipeline
# moreutils  - collection of handy unix utilities (sponge, ts, etc.)
```

---

### 🌐 Networking & Diagnostics (INSTALL_NETWORKING)

```bash
dnsutils/bind, nmap, mtr, traceroute*, socat, tcpdump, whois
```

```bash
# dnsutils/bind  - DNS query tools like dig and nslookup
# nmap           - powerful network scanner and security auditing tool
# mtr            - combines traceroute and ping for network diagnostics
# traceroute     - shows path packets take across the network *Linux only
# socat          - bidirectional data relay for sockets, serial, pipes
# tcpdump        - capture and analyze network packets
# whois          - query domain registration and ownership info
```

---

### 📦 Compression & Archiving (INSTALL_COMPRESSION)

```bash
zip, unzip, p7zip-full/p7zip, xz-utils/xz, pigz
```

```bash
# zip            - compress files into .zip archives
# unzip          - extract .zip archives
# p7zip-full/p7zip - 7z archive format support
# xz-utils/xz    - compression utilities for .xz format
# pigz           - parallel gzip compressor for faster compression
```

---

### 🛠️ Development Tools (INSTALL_DEVELOPMENT)

```bash
cmake, pkg-config, gpg/gnupg, openssl
```

```bash
# cmake          - cross-platform build system generator
# pkg-config     - helper tool for compiling/linking with libraries
# gpg/gnupg      - GNU Privacy Guard for encryption and signing
# openssl        - SSL/TLS cryptography and certificate management
```

---

### 📂 File & Search Utilities (INSTALL_FILE_UTILS)

```bash
tree, fd-find/fd, ripgrep, jq, yq
```

```bash
# tree           - display directory contents as a tree structure
# fd-find/fd     - fast, user-friendly alternative to find
# ripgrep        - fast recursive search through files (rg command)
# jq             - command-line JSON processor
# yq             - command-line YAML processor
```

---

### ⚡ CLI Productivity & UX (INSTALL_PRODUCTIVITY)

```bash
fzf, bat, eza, tldr
```

```bash
# fzf            - fuzzy finder for command-line
# bat            - cat clone with syntax highlighting and git integration
# eza            - modern replacement for ls with colors and git info
# tldr           - simplified man pages with practical examples
```

## Usage

### Install Base Packages Only (Default)

```bash
./install-essentials.sh
```

### Install Specific Categories

```bash
./install-essentials.sh networking base monitoring
```

### Install Multiple Categories

```bash
./install-essentials.sh base development file-utils productivity
```

### Install All Categories

```bash
./install-essentials.sh base monitoring networking compression development file-utils productivity
```

## Examples

### Minimal Setup (New System)

```bash
./install-essentials.sh base
```

### Developer Setup

```bash
./install-essentials.sh base development file-utils productivity
```

### System Administrator Setup

```bash
./install-essentials.sh base monitoring networking compression
```

### Complete Setup (All Tools)

```bash
./install-essentials.sh base monitoring networking compression development file-utils productivity
```

## Platform Notes

- **Linux**: Packages are installed via `apt-get` (Ubuntu/Debian)
- **macOS**: Packages are installed via `brew` (Homebrew required)
- Some tools may have different package names or may not be available on certain platforms (marked with *)
- The script automatically handles platform-specific package names and availability

## Recommended Usage for New Systems

1. **Minimal Setup**: Run with defaults (base packages only)
2. **Developer Setup**: Add `INSTALL_DEVELOPMENT=yes INSTALL_FILE_UTILS=yes`
3. **System Admin Setup**: Add `INSTALL_MONITORING=yes INSTALL_NETWORKING=yes`
4. **Complete Setup**: Enable all categories for full-featured development environment
