# VS Code Copilot Instructions for Shell Scripts

This document outlines the coding standards and structure preferences for shell scripts in this project.

## Script Structure

All shell scripts in this project should follow a consistent structure with three main sections:

### 1. Base Section (## --- Base --- ##)
- **Purpose**: Common initialization code shared across all scripts
- **Required Elements**:
  - Shebang line: `#!/bin/bash`
  - Error handling: `set -euo pipefail`
  - Script directory detection: `_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"`
  - Dependency checks for required commands (prefer `wget` over `curl` when possible)
  - .env file loading capability with shellcheck disable comments
  - OS and distribution detection logic with proper error handling

### 2. Variables Section (## --- Variables --- ##)
- **Purpose**: Define only essential configurable environment variables with defaults
- **Requirements**:
  - Use `${VAR_NAME:-default_value}` pattern for all variables
  - Only include frequently changed or environment-specific settings
  - Keep customization minimal - avoid over-engineering
  - Add concise inline comments explaining each variable's purpose
  - Group related variables together
  - Use descriptive variable names with consistent naming conventions

### 3. Main Section (## --- Main --- ##)
- **Purpose**: Core functionality and helper functions
- **Requirements**:
  - All logic should be inside functions
  - Main execution should be in a `main()` function
  - Call main function at the end: `main "${@:-}"`
  - Use helper functions to break down complex operations

## Coding Standards

### Error Handling
- Always use `set -euo pipefail` at the script start
- Use `|| exit 2` for non-critical errors
- Use `|| exit 1` for critical errors (missing dependencies)
- Provide descriptive error messages with `[ERROR]:` prefix

### Output Formatting
- Use `[INFO]:` prefix for informational messages
- Use `[OK]:` prefix for success messages
- Use `[ERROR]:` prefix for error messages
- End success messages with `echo -e "[OK]: Done.\n"`

### Download Tools
- Prefer `wget` over `curl` for downloading files when possible
- Use `wget "${url}" -O "${output_file}"` format
- Include proper error handling for download operations

### Function Design
- Keep functions focused on a single responsibility
- Use descriptive function names with underscores
- Add parameter validation at function start
- Return meaningful exit codes

### OS Compatibility
- Support both Linux (Ubuntu/Debian) and macOS
- Use `_OS` variable to determine the operating system
- Handle OS-specific differences in conditional blocks (e.g., prioritize zsh on macOS)
- Test commands for availability before using them
- Account for OS-specific default behaviors (zsh on macOS, bash on Linux)

### Examples

#### Proper Variable Definition
```bash
## --- Variables --- ##
# Essential settings only:
APP_INSTALL_DIR=${APP_INSTALL_DIR:-"${HOME}/app"}      # Installation directory
APP_AUTO_START=${APP_AUTO_START:-"no"}                 # Auto-start service (yes/no)
## --- Variables --- ##
```

#### Proper Function Structure
```bash
get_installer_url()
{
	local _installer_name=""

	if [ "${_OS}" = "Linux" ]; then
		_installer_name="tool-latest-Linux-x86_64.sh"
	elif [ "${_OS}" = "Darwin" ]; then
		_installer_name="tool-latest-MacOSX-x86_64.sh"
	fi

	echo "https://example.com/${_installer_name}"
}

configure_tool()
{
    echo "[INFO]: Configuring tool..."
    
    if [ -z "${1:-}" ]; then
        echo "[ERROR]: Configuration parameter required!"
        exit 2
    fi
    
    local _config_param="${1}"
    
    # Configuration logic here...
    
    echo -e "[OK]: Done.\n"
}
```

#### Proper Main Function
```bash
main()
{
    echo "[INFO]: Setting up 'Tool'..."

    # Check if tool is already installed
    if [ -d "${TOOL_INSTALL_DIR}" ] && [ -f "${TOOL_INSTALL_DIR}/bin/tool" ]; then
        echo "[INFO]: Tool is already installed at ${TOOL_INSTALL_DIR}"
        echo "[INFO]: Updating existing installation..."
        # Update logic here...
        echo -e "[OK]: Done.\n"
    else
        # Download and install tool
        _installer_url="$(get_installer_url)"
        _installer_file="/tmp/tool-installer.sh"

        echo "[INFO]: Downloading tool installer..."
        wget "${_installer_url}" -O "${_installer_file}" || exit 2

        echo "[INFO]: Installing tool to ${TOOL_INSTALL_DIR}..."
        bash "${_installer_file}" -b -p "${TOOL_INSTALL_DIR}" || exit 2
        rm -f "${_installer_file}"
        echo -e "[OK]: Done.\n"

        # Initialize for shell (OS-specific handling)
        echo "[INFO]: Initializing tool for shell..."
        if [ "${_OS}" = "Darwin" ]; then
            # On macOS, prioritize zsh initialization
            if command -v zsh >/dev/null 2>&1; then
                "${TOOL_INSTALL_DIR}/bin/tool" init zsh || exit 2
            fi
            "${TOOL_INSTALL_DIR}/bin/tool" init bash || exit 2
        else
            # On Linux, initialize bash first, then zsh if available
            "${TOOL_INSTALL_DIR}/bin/tool" init bash || exit 2
            if command -v zsh >/dev/null 2>&1; then
                "${TOOL_INSTALL_DIR}/bin/tool" init zsh || exit 2
            fi
        fi
        echo -e "[OK]: Done.\n"
    fi

    # Configure settings
    configure_tool "${TOOL_CONFIG_PARAM}"

    echo -e "[OK]: 'Tool' setup completed successfully!"
    echo "[INFO]: Restart your terminal to use the tool."
}

main "${@:-}"
```

## Documentation Standards

### Inline Documentation
- Use concise inline comments for variable explanations
- Avoid extensive external documentation files
- Keep comments brief but informative
- Document only what's not immediately obvious from the code

### Variable Documentation
- Limit configurable variables to essential settings only
- Avoid over-customization - focus on commonly changed settings
- Use clear variable names that are self-documenting
- Include value options in comments when helpful (e.g., "yes/no")

## File Organization

### Keep It Simple
- Minimize external configuration files
- Use inline comments instead of extensive documentation
- Focus on essential functionality over extensive customization options

### Script Naming
- Use descriptive names: `install-<tool>.sh`
- Use hyphens to separate words in filenames
- Keep names concise but clear

## Testing and Validation

### Before Implementation
- Verify all required dependencies are available
- Test on both supported operating systems
- Validate environment variable handling
- Ensure proper error handling and exit codes

### Code Quality
- Use shellcheck for static analysis
- Follow consistent indentation (tabs or spaces)
- Add appropriate comments for complex logic
- Use `# shellcheck disable=SC1091` for intentional shellcheck warnings (like .env sourcing)
- Validate all user inputs and parameters

## Integration with VS Code

### Recommended Extensions
- ShellCheck for linting
- Bash IDE for syntax highlighting
- Better Comments for enhanced comment visibility

### Development Workflow
1. Follow the three-section structure template
2. Define only essential, frequently-changed variables with sensible defaults
3. Implement functionality in focused, single-responsibility functions
4. Handle OS-specific differences (especially macOS zsh vs Linux bash)
5. Use wget for downloads when possible
6. Add concise inline comments for complex logic
7. Test on target operating systems
8. Validate with shellcheck and fix warnings

This structure ensures consistency, maintainability, and reliability across all shell scripts in the project.
