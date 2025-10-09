#!/bin/bash

set -euo pipefail

## --- Base --- ##

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Check for required dependencies
for cmd in groupadd useradd usermod; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "[ERROR]: Required command '${cmd}' not found!" >&2
        exit 1
    fi
done

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR]: This script must be run as root (use sudo)" >&2
    exit 1
fi

# OS detection
_OS="$(uname -s)"
case "${_OS}" in
    Linux*)     _OS=Linux;;
    Darwin*)    _OS=Darwin;;
    *)
        echo "[ERROR]: Unsupported OS: ${_OS}" >&2
        exit 1
        ;;
esac

# Loading .env file:
if [ -r .env ]; then
	echo "[INFO]: Loading configuration from .env file"
	set -a
	# shellcheck disable=SC1091
	. .env
	set +a
fi

## --- Variables --- ##

# Groups configuration (format: "group1:gid1 group2:gid2 ...")
SETUP_GROUPS=${SETUP_GROUPS:-""}                        # Groups to create with GIDs
# Users configuration (format: "user1:primary_group:secondary_groups user2:primary_group ...")
SETUP_USERS=${SETUP_USERS:-""}                         # Users to create with group assignments
# User home directory base path
USER_HOME_BASE=${USER_HOME_BASE:-"/home"}               # Base directory for user homes
# Default shell for new users
USER_SHELL=${USER_SHELL:-"/bin/bash"}                   # Default shell
# Create home directories for users (yes/no)
CREATE_HOME=${CREATE_HOME:-"yes"}                       # Create home directory
# Dry run mode (yes/no)
DRY_RUN=${DRY_RUN:-"no"}                               # Show what would be done without executing

## --- Main --- ##

check_group_exists()
{
    local _group_name="${1}"
    getent group "${_group_name}" >/dev/null 2>&1
}

check_user_exists()
{
    local _username="${1}"
    getent passwd "${_username}" >/dev/null 2>&1
}

create_group()
{
    local _group_spec="${1}"
    local _group_name
    local _gid

    # Parse group specification (name:gid)
    IFS=':' read -r _group_name _gid <<< "${_group_spec}"

    if [ -z "${_group_name}" ] || [ -z "${_gid}" ]; then
        echo "[ERROR]: Invalid group specification: ${_group_spec} (expected: name:gid)" >&2
        return 1
    fi

    if check_group_exists "${_group_name}"; then
        echo "[INFO]: Group '${_group_name}' already exists"
        return 0
    fi

    if [ "${DRY_RUN}" = "yes" ]; then
        echo "[INFO]: [DRY RUN] Would create group: ${_group_name} (GID: ${_gid})"
        return 0
    fi

    echo "[INFO]: Creating group: ${_group_name} (GID: ${_gid})"

    # Use groupadd with -f flag (force) to avoid errors if group exists
    if groupadd -f -g "${_gid}" "${_group_name}"; then
        echo "[OK]: Created group: ${_group_name}"
    else
        echo "[ERROR]: Failed to create group: ${_group_name}" >&2
        return 1
    fi
}

create_user()
{
    local _user_spec="${1}"
    local _username
    local _primary_group
    local _secondary_groups

    # Parse user specification (username:primary_group:secondary_groups)
    IFS=':' read -r _username _primary_group _secondary_groups <<< "${_user_spec}"

    if [ -z "${_username}" ] || [ -z "${_primary_group}" ]; then
        echo "[ERROR]: Invalid user specification: ${_user_spec} (expected: username:primary_group[:secondary_groups])" >&2
        return 1
    fi

    # Check if primary group exists
    if ! check_group_exists "${_primary_group}"; then
        echo "[ERROR]: Primary group '${_primary_group}' does not exist for user '${_username}'" >&2
        return 1
    fi

    if check_user_exists "${_username}"; then
        echo "[INFO]: User '${_username}' already exists"
        # Still try to update group memberships
        if [ -n "${_secondary_groups}" ]; then
            if [ "${DRY_RUN}" = "yes" ]; then
                echo "[INFO]: [DRY RUN] Would add user '${_username}' to secondary groups: ${_secondary_groups}"
            else
                echo "[INFO]: Adding user '${_username}' to secondary groups: ${_secondary_groups}"
                if usermod -aG "${_secondary_groups}" "${_username}"; then
                    echo "[OK]: Updated group memberships for user: ${_username}"
                else
                    echo "[ERROR]: Failed to update group memberships for user: ${_username}" >&2
                    return 1
                fi
            fi
        fi
        return 0
    fi

    if [ "${DRY_RUN}" = "yes" ]; then
        echo "[INFO]: [DRY RUN] Would create user: ${_username} (primary: ${_primary_group}, secondary: ${_secondary_groups:-none})"
        return 0
    fi

    echo "[INFO]: Creating user: ${_username} (primary group: ${_primary_group})"

    # Build useradd command
    local _useradd_args=()
    _useradd_args+=(-s "${USER_SHELL}")
    _useradd_args+=(-g "${_primary_group}")

    if [ "${CREATE_HOME}" = "yes" ]; then
        _useradd_args+=(-m)
        _useradd_args+=(-d "${USER_HOME_BASE}/${_username}")
    fi

    _useradd_args+=("${_username}")

    if useradd "${_useradd_args[@]}"; then
        echo "[OK]: Created user: ${_username}"
    else
        echo "[ERROR]: Failed to create user: ${_username}" >&2
        return 1
    fi

    # Add to secondary groups if specified
    if [ -n "${_secondary_groups}" ]; then
        echo "[INFO]: Adding user '${_username}' to secondary groups: ${_secondary_groups}"
        if usermod -aG "${_secondary_groups}" "${_username}"; then
            echo "[OK]: Added user '${_username}' to secondary groups"
        else
            echo "[ERROR]: Failed to add user '${_username}' to secondary groups" >&2
            return 1
        fi
    fi
}

setup_groups()
{
    if [ -z "${SETUP_GROUPS}" ]; then
        echo "[INFO]: No groups specified, skipping group creation"
        return 0
    fi

    echo "[INFO]: Setting up groups..."

    # Split SETUP_GROUPS by space and process each group
    for _group_spec in ${SETUP_GROUPS}; do
        if ! create_group "${_group_spec}"; then
            echo "[ERROR]: Failed to create group from specification: ${_group_spec}" >&2
            exit 2
        fi
    done

    echo -e "[OK]: Groups setup completed.\n"
}

setup_users()
{
    if [ -z "${SETUP_USERS}" ]; then
        echo "[INFO]: No users specified, skipping user creation"
        return 0
    fi

    echo "[INFO]: Setting up users..."

    # Split SETUP_USERS by space and process each user
    for _user_spec in ${SETUP_USERS}; do
        if ! create_user "${_user_spec}"; then
            echo "[ERROR]: Failed to create user from specification: ${_user_spec}" >&2
            exit 2
        fi
    done

    echo -e "[OK]: Users setup completed.\n"
}

show_usage()
{
    cat << EOF
Setup Users and Groups Script

This script creates custom users and groups according to configuration.

USAGE:
    sudo ${0} [--dry-run] [--help]

    When run without configuration, creates default: ubuntu user in devs group (GID 1000)

OPTIONS:
    --dry-run    Show what would be done without making changes
    --help       Show this help message

CONFIGURATION (via environment variables or .env file):

    SETUP_GROUPS="group1:1001 group2:1002 ..."
        Create groups with specified names and GIDs
        Format: space-separated "name:gid" pairs

    SETUP_USERS="user1:primary_group:secondary_groups user2:primary_group ..."
        Create users with primary and secondary group memberships
        Format: space-separated "username:primary_group[:secondary_groups]"
        Secondary groups are comma-separated (optional)

    USER_HOME_BASE="/home"     # Base directory for user home directories
    USER_SHELL="/bin/bash"     # Default shell for new users
    CREATE_HOME="yes"          # Create home directory for users (yes/no)
    DRY_RUN="no"              # Show what would be done without executing (yes/no)

EXAMPLES:
    # Use defaults (ubuntu user in devs group)
    sudo ${0}

    # Create groups only
    sudo SETUP_GROUPS="developers:1001 admins:1002" ${0}

    # Create users with existing groups
    sudo SETUP_USERS="john:developers:admins jane:admins" ${0}

    # Create both groups and users
    sudo SETUP_GROUPS="developers:1001 admins:1002" \\
         SETUP_USERS="john:developers:admins jane:admins" ${0}

    # Dry run to see what would be done (with defaults)
    sudo ${0} --dry-run

    # Dry run with custom configuration
    sudo SETUP_GROUPS="developers:1001" SETUP_USERS="john:developers" ${0} --dry-run

NOTES:
    - Script must be run as root (use sudo)
    - If no configuration provided, defaults to creating ubuntu:devs:1000
    - Groups must exist before creating users that reference them
    - Secondary groups in user specification are comma-separated
    - Existing users/groups are skipped (idempotent operation)

EOF
}

main()
{
    # Parse command line arguments
    while [ $# -gt 0 ]; do
        case "${1}" in
            --dry-run)
                DRY_RUN="yes"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            "")
                # Skip empty arguments
                shift
                ;;
            *)
                echo "[ERROR]: Unknown option: '${1}'" >&2
                show_usage
                exit 1
                ;;
        esac
    done

    echo "[INFO]: Setting up users and groups on ${_OS}..."

    if [ "${DRY_RUN}" = "yes" ]; then
        echo "[INFO]: DRY RUN MODE - No changes will be made"
    fi

    # Validate we have something to do, or set defaults
    if [ -z "${SETUP_GROUPS}" ] && [ -z "${SETUP_USERS}" ]; then
        echo "[INFO]: No groups or users specified. Using defaults: ubuntu user in devs group."
        SETUP_GROUPS="devs:1000"
        SETUP_USERS="ubuntu:devs"
    fi

    # Create groups first (users may depend on them)
    setup_groups

    # Create users
    setup_users

    if [ "${DRY_RUN}" = "yes" ]; then
        echo "[OK]: Dry run completed successfully!"
    else
        echo "[OK]: User and group setup completed successfully!"
        echo "[INFO]: You may need to restart terminals or re-login for group changes to take effect."
    fi
}

main "${@:-}"
