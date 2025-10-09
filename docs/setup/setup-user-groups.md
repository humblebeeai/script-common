# Setup User Groups

This document explains how to use the `setup-user-groups.sh` script to create custom users and groups according to configuration.

## setup-user-groups.sh

The script creates users and groups with specified configurations, supporting both primary and secondary group memberships. It follows Linux best practices for user and group management, preferring `groupadd` over `addgroup` and providing comprehensive error handling.

**Default Behavior**: When run without any configuration, the script creates an `ubuntu` user in a `devs` group (GID 1000).

### Configuration Variables

- `SETUP_GROUPS` - Space-separated list of groups to create (format: "name:gid name:gid ...")
- `SETUP_USERS` - Space-separated list of users to create (format: "username:primary_group:secondary_groups username:...")
- `USER_HOME_BASE` - Base directory for user home directories (default: "/home")
- `USER_SHELL` - Default shell for new users (default: "/bin/bash")
- `CREATE_HOME` - Create home directories for users (default: "yes")
- `DRY_RUN` - Show what would be done without executing (default: "no")

### Command Line Options

- `--dry-run` - Show what would be done without making changes
- `--help` - Show help message and usage examples

## Usage Examples

### Default Usage (No Configuration Required)

```bash
# Creates ubuntu user in devs group (GID 1000)
sudo ./setup-user-groups.sh

# See what would be created without making changes
sudo ./setup-user-groups.sh --dry-run
```

### Create Groups Only

```bash
# Create devs and admins groups
sudo SETUP_GROUPS="devs:1001 admins:1002" ./setup-user-groups.sh
```

### Create Users Only

```bash
# Create users (assuming groups already exist)
sudo SETUP_USERS="john:devs:admins jane:admins" ./setup-user-groups.sh
```

### Create Both Groups and Users

```bash
# Create groups and users together
sudo SETUP_GROUPS="devs:1001 admins:1002 ops:1003" \
     SETUP_USERS="john:devs:admins jane:admins:ops bob:ops" \
     ./setup-user-groups.sh
```

### Custom User Settings

```bash
# Create users with custom home base and shell
sudo SETUP_GROUPS="devs:1001" \
     SETUP_USERS="john:devs" \
     USER_HOME_BASE="/opt/users" \
     USER_SHELL="/bin/zsh" \
     ./setup-user-groups.sh
```

### Dry Run

```bash
# See what would be done without making changes
sudo SETUP_GROUPS="devs:1001" SETUP_USERS="john:devs" ./setup-user-groups.sh --dry-run
```

### Use .env File

Create a `.env` file in the script directory or current directory:

```bash
# .env
SETUP_GROUPS="devs:1001 admins:1002 ops:1003"
SETUP_USERS="john:devs:admins jane:admins:ops bob:ops"
USER_HOME_BASE="/home"
USER_SHELL="/bin/bash"
CREATE_HOME="yes"
```

Then run:

```bash
sudo ./setup-user-groups.sh
```

## Configuration Format

### Groups Format

Groups are specified as `name:gid` pairs separated by spaces:

```bash
SETUP_GROUPS="group1:1001 group2:1002 group3:1003"
```

- `group1` - Group name
- `1001` - Group ID (GID)

### Users Format

Users are specified as `username:primary_group:secondary_groups` separated by spaces:

```bash
SETUP_USERS="user1:group1:group2,group3 user2:group2"
```

- `user1` - Username
- `group1` - Primary group (must exist)
- `group2,group3` - Secondary groups (comma-separated, optional)

## Requirements

- **Root privileges**: Script must be run with `sudo` (root can create first users on fresh systems)
- **Linux/macOS**: Currently supports Linux and macOS systems
- **Dependencies**: `groupadd`, `useradd`, `usermod` commands must be available
- **Group dependencies**: When creating users, their primary groups must already exist

## Safety Features

- **Idempotent**: Running the script multiple times is safe - it won't recreate existing users/groups
- **Non-destructive**: Only creates new users and groups, never modifies existing ones
- **Dry run support**: Use `--dry-run` to preview changes without applying them
- **Error handling**: Stops on first error and reports what failed
- **Validation**: Checks configuration format and dependencies before making changes
- **Group existence**: Validates that primary groups exist before creating users

## Platform Support

- **Linux**: Full support with standard user management commands
- **macOS**: Basic support (may require additional setup for some features)

## Integration

This script works well with other system setup scripts:

- Use with `setup-structure.sh` to create workspace directories after user creation
- Combine with `install-essentials.sh` to set up development tools for specific user groups
- Use after installing development tools to configure user environments

## Examples

### Fresh System Setup (Root User Creating First Users)

When setting up a new system where only root exists, this script creates the initial users:

```bash
# Create initial groups and users on a fresh system
sudo SETUP_GROUPS="users:1000 admin:1001 developers:1002" \
     SETUP_USERS="john:users:admin,developers jane:developers alice:admin" \
     ./setup-user-groups.sh

# Alternative: Use .env file for cleaner configuration
cat > .env << EOF
SETUP_GROUPS="users:1000 admin:1001 developers:1002"
SETUP_USERS="john:users:admin,developers jane:developers alice:admin"
USER_HOME_BASE="/home"
USER_SHELL="/bin/bash"
CREATE_HOME="yes"
EOF

sudo ./setup-user-groups.sh
```

This is particularly useful for:

- **New server setup**: Creating initial user accounts
- **Container initialization**: Setting up users in Docker containers
- **VM provisioning**: Automated user creation during deployment

### Development Team Setup

```bash
# Step 1: Create development groups
sudo SETUP_GROUPS="devs:2000 admins:2001 qa:2002" ./setup-user-groups.sh

# Step 2: Create team members
sudo SETUP_USERS="alice:devs:admins bob:devs:qa charlie:qa:admins" ./setup-user-groups.sh
```

### Service Accounts

```bash
# Create service groups and accounts without home directories
sudo SETUP_GROUPS="web:3000 db:3001 api:3002" \
     SETUP_USERS="www-data:web nginx:web:api postgres:db" \
     USER_SHELL="/bin/false" \
     CREATE_HOME="no" \
     ./setup-user-groups.sh
```

### Multi-Environment Setup

```bash
# Development environment
sudo SETUP_GROUPS="dev:1000 dev-admin:1001" \
     SETUP_USERS="devuser:dev:dev-admin" \
     ./setup-user-groups.sh

# Production environment
sudo SETUP_GROUPS="prod:2000 prod-admin:2001 prod-readonly:2002" \
     SETUP_USERS="produser:prod:prod-admin readonly:prod-readonly" \
     ./setup-user-groups.sh
```

## Linux Group Management Reference

The script follows Linux best practices for group management:

- Uses `groupadd -f -g GID GROUP_NAME` for group creation
- Uses `usermod -aG PRIMARY_GROUP -g PRIMARY_GROUP USERNAME` for primary group assignment
- Uses `usermod -aG SECONDARY_GROUPS USERNAME` for secondary group assignment
- Supports both primary and secondary group memberships
- Validates group existence before user creation

For manual group operations outside this script, you can use standard Linux commands as documented in various Linux administration guides.
