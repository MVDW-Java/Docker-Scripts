DockerBackup() {
    # Default values
    local CONTAINER_NAME=""
    local BACKUP_NAME=""
    local BACKUP_PATH="../backups/storage"
    local COMPRESS=true

    # Help function
    ShowHelp() {
        echo "Docker Backup Helper Function"
        echo "Usage: DockerBackup [OPTIONS]"
        echo "Options:"
        echo "  -n, --name           Container name to backup (required)"
        echo "  -b, --backup-name    Backup name (default: container_name_YYYY-MM-DD_HHMMSS)"
        echo "  -p, --path           Backup path (default: ../backups/storage)"
        echo "  --no-compress        Don't compress the backup"
        echo "  -h, --help           Show this help message"
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            -b|--backup-name)
                BACKUP_NAME="$2"
                shift 2
                ;;
            -p|--path)
                BACKUP_PATH="$2"
                shift 2
                ;;
            --no-compress)
                COMPRESS=false
                shift
                ;;
            -h|--help)
                ShowHelp
                return 0
                ;;
            *)
                echo "Unknown option: $1"
                ShowHelp
                return 1
                ;;
        esac
    done

    # Check if container name is provided
    if [[ -z "$CONTAINER_NAME" ]]; then
        echo "Error: Container name is required"
        ShowHelp
        return 1
    fi

    # Check if container exists
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Error: Container '$CONTAINER_NAME' not found"
        return 1
    fi

    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_PATH"

    # Generate backup name if not provided
    if [[ -z "$BACKUP_NAME" ]]; then
        BACKUP_NAME="${CONTAINER_NAME}_$(date +%Y-%m-%d_%H%M%S)"
    fi

    # Create temporary directory for backup
    local TEMP_DIR="/tmp/docker_backup_${BACKUP_NAME}"
    mkdir -p "$TEMP_DIR"

    echo "Creating backup of container volumes: $CONTAINER_NAME"
    echo "Backup name: $BACKUP_NAME"
    echo "Backup path: $BACKUP_PATH"

    # Get volume information
    local VOLUMES=$(docker inspect --format='{{range .Mounts}}{{.Source}}:{{.Destination}};{{end}}' "$CONTAINER_NAME")

    # Backup each volume
    IFS=';' read -ra VOLUME_ARRAY <<< "$VOLUMES"
    for volume in "${VOLUME_ARRAY[@]}"; do
        if [ -n "$volume" ]; then
            IFS=':' read -r source destination <<< "$volume"
            if [ -d "$source" ]; then
                local volume_name=$(basename "$destination")
                echo "Backing up volume: $volume_name"
                cp -r "$source" "$TEMP_DIR/$volume_name"
            fi
        fi
    done

    # Create final backup
    if [[ "$COMPRESS" = true ]]; then
        echo "Compressing backup..."
        tar -czf "$BACKUP_PATH/${BACKUP_NAME}.tar.gz" -C "$TEMP_DIR" .
        echo "Backup created at: $BACKUP_PATH/${BACKUP_NAME}.tar.gz"
    else
        # Create uncompressed backup directory
        mkdir -p "$BACKUP_PATH/$BACKUP_NAME"
        cp -r "$TEMP_DIR"/* "$BACKUP_PATH/$BACKUP_NAME/"
        echo "Backup created at: $BACKUP_PATH/$BACKUP_NAME"
    fi

    # Cleanup temporary directory
    rm -rf "$TEMP_DIR"

    echo "Backup completed successfully"
}
