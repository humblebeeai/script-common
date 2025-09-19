# Setup Workspace Structure

This document explains how to use the `setup-structure.sh` script to create a standardized workspace directory structure for development and data management.

## setup-structure.sh

The script creates a hierarchical workspace structure with predefined subdirectories for organizing different types of work and data.

### Configuration Variables

- `WORKSPACE_BASE_DIR` - Base workspace directory (default: `${HOME}/workspaces`)
- `WORKSPACE_SUBDIRS` - Space-separated list of subdirectories to create (default: `projects services runtimes archives datasets education models volumes`)

## Default Structure

The script creates the following directory structure:

```bash
workspaces/
├── projects/     # Development projects and code repositories
├── services/     # Service configurations and deployments
├── runtimes/     # Runtime environments and tool installations
├── archives/     # Archived projects and completed work
├── datasets/     # Data files and datasets
├── education/    # Learning materials and tutorials
├── models/       # Machine learning models and artifacts
└── volumes/      # Persistent data volumes and storage
```

## Usage

### Create Default Structure

```bash
./setup-structure.sh
```

### Custom Base Directory

```bash
WORKSPACE_BASE_DIR="/path/to/my/workspaces" ./setup-structure.sh
```

### Custom Subdirectories

```bash
WORKSPACE_SUBDIRS="code data docs tools" ./setup-structure.sh
```

### Use .env File

Create a `.env` file:

```bash
# .env
WORKSPACE_BASE_DIR=/home/user/my-workspace
WORKSPACE_SUBDIRS=projects services runtimes archives datasets
```

Then run:

```bash
./setup-structure.sh
```

## Directory Purposes

### projects/

- Development projects and code repositories
- Active development work
- Git repositories and source code

### services/

- Service configurations and deployments
- Docker Compose files
- Infrastructure as Code (IaC) configurations

### runtimes/

- Runtime environments and tool installations
- Language runtimes (Python, Node.js, etc.)
- Tool binaries and installations

### archives/

- Archived projects and completed work
- Old repositories and finished projects
- Historical data and backups

### datasets/

- Data files and datasets
- Training data for ML models
- Research data and collections

### education/

- Learning materials and tutorials
- Course work and documentation
- Educational resources and notes

### models/

- Machine learning models and artifacts
- Trained model files
- Model checkpoints and weights

### volumes/

- Persistent data volumes and storage
- Database files and persistent storage
- Long-term data that needs to persist

## Platform Support

- **Linux**: Full support
- **macOS**: Full support
- The script uses standard Unix commands and works on any POSIX-compliant system

## Safety Features

- **Idempotent**: Running the script multiple times is safe - it won't overwrite existing directories
- **Non-destructive**: Only creates directories, never removes or modifies existing content
- **Informative**: Shows which directories are created vs. already exist
- **Error handling**: Proper error handling with descriptive messages

## Integration

This workspace structure is designed to work well with the other scripts in this project:

- `install-essentials.sh` can install tools into `runtimes/`
- `install-go.sh` and `install-rust.sh` can install language runtimes into `runtimes/`
- Development projects can be organized in `projects/`
- Data for projects can be stored in `datasets/`
- ML models can be stored in `models/`

## Customization

You can customize the structure by modifying the `WORKSPACE_SUBDIRS` variable to include only the directories you need, or add additional directories for your specific workflow.
