# Install Oh My Zsh

Install Oh My Zsh framework for Zsh with popular plugins and themes.

## Usage

```bash
# Basic installation
./install-ohmyzsh.sh

# Custom installation directory
OH_MY_ZSH_INSTALL_DIR="/opt/oh-my-zsh" ./install-ohmyzsh.sh

# Disable plugins installation
OH_MY_ZSH_INSTALL_PLUGINS="no" ./install-ohmyzsh.sh
```

## Configuration

- `OH_MY_ZSH_INSTALL_DIR` - Installation directory (default: `${HOME}/.oh-my-zsh`)
- `OH_MY_ZSH_INSTALL_PLUGINS` - Install additional plugins (default: "yes")
- `OH_MY_ZSH_THEME` - Theme to set (default: "agnoster")
- `OH_MY_ZSH_PLUGINS` - Space-separated list of plugins to install

## What It Does

1. **Check Dependencies**: Verifies curl and git are available
2. **Install Oh My Zsh**: Downloads and runs official installation script
3. **Configure Theme**: Sets specified theme in .zshrc
4. **Install Plugins**: Installs popular additional plugins
5. **Update Configuration**: Applies plugin and theme settings

## Default Plugins

The script installs these popular plugins by default:

- **zsh-autosuggestions** - Fish-like auto suggestions
- **zsh-syntax-highlighting** - Command syntax highlighting
- **zsh-completions** - Additional completion definitions

## Requirements

- Zsh shell installed
- curl and git commands available
- Linux (Ubuntu/Debian) or macOS system

## After Installation

```bash
# Restart shell or source configuration
source ~/.zshrc

# Verify installation
echo $ZSH
```

## Custom Configuration

Use `.env` file for custom settings:

```bash
# .env
OH_MY_ZSH_INSTALL_DIR=/home/user/.oh-my-zsh
OH_MY_ZSH_THEME=robbyrussell
OH_MY_ZSH_PLUGINS="git docker kubectl"
OH_MY_ZSH_INSTALL_PLUGINS=yes
```

## Plugin Options

Popular plugins you can add via `OH_MY_ZSH_PLUGINS`:

- `git` - Git aliases and functions
- `docker` - Docker completion and aliases
- `kubectl` - Kubernetes completion
- `npm` - NPM completion and aliases
- `python` - Python utilities
- `rust` - Rust completion
- `golang` - Go completion

## Theme Options

Popular themes you can set via `OH_MY_ZSH_THEME`:

- `robbyrussell` - Default Oh My Zsh theme
- `agnoster` - Powerline-style theme
- `powerlevel10k` - Advanced powerline theme
- `pure` - Minimal async prompt
- `spaceship` - Minimalistic and powerful prompt

## Manual Steps (Reference)

The script automates these steps:

```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
```
