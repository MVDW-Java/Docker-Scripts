DockerBash() {
    # Default values
    local CONTAINER_NAME=""
    local SHELL_CMD="/bin/bash"

    # Help function
    ShowHelp() {
        echo "Docker Bash Helper Function"
        echo "Usage: DockerBash [OPTIONS]"
        echo "Options:"
            echo "  -n, --name           Container name to access (required)"
            echo "  -s, --shell          Shell to use (default: /bin/bash)"
            echo "  -h, --help           Show this help message"
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            -s|--shell)
                SHELL_CMD="$2"
                shift 2
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

    # Get container image
    local CONTAINER_IMAGE=$(docker inspect --format='{{.Config.Image}}' "$CONTAINER_NAME")
    if [ -z "$CONTAINER_IMAGE" ]; then
        echo "Error: Could not determine container image"
        return 1
    fi

    # Try to execute the primary shell in the existing container
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "Attempting to connect to running container..."
        if docker exec -it "$CONTAINER_NAME" "$SHELL_CMD"; then
            return 0
        fi
        if docker exec -it "$CONTAINER_NAME" /bin/sh; then
            return 0
        fi
    fi

    # If we get here, either the container is not running or exec failed
    echo "Could not connect to running container. Creating temporary container from image..."

    # Create a temporary name for the debug container
    local TEMP_NAME="${CONTAINER_NAME}_debug_$(date +%s)"

    # Get all volume mounts from the original container
    local VOLUME_MOUNTS=$(docker inspect --format='{{range .Mounts}}{{if eq .Type "volume"}}-v {{.Name}}:{{.Destination}} {{end}}{{if eq .Type "bind"}}-v {{.Source}}:{{.Destination}} {{end}}{{end}}' "$CONTAINER_NAME")

    # Get all environment variables from the original container
    local ENV_VARS=$(docker inspect --format='{{range .Config.Env}}-e {{.}} {{end}}' "$CONTAINER_NAME")

    # Get network settings from the original container
    local NETWORK=$(docker inspect --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}' "$CONTAINER_NAME" | awk '{print $1}')
    local NETWORK_OPT=""
    if [ -n "$NETWORK" ] && [ "$NETWORK" != "bridge" ]; then
        NETWORK_OPT="--network $NETWORK"
    fi

    # Get group settings if any
    local GROUPS=$(docker inspect --format='{{range .HostConfig.GroupAdd}}--group-add {{.}} {{end}}' "$CONTAINER_NAME")

    # Construct and execute the run command
    local CMD="docker run --rm -it \
        $VOLUME_MOUNTS \
        $ENV_VARS \
        $NETWORK_OPT \
        $GROUPS \
        --name $TEMP_NAME \
        --entrypoint $SHELL_CMD \
        $CONTAINER_IMAGE"

    echo "Starting temporary debug container..."
    echo "Command: $CMD"

    eval "$CMD"

    # If the shell command failed, try with /bin/sh
    if [ $? -ne 0 ]; then
        echo "Failed to start with $SHELL_CMD, trying with /bin/sh..."
        CMD="docker run --rm -it \
            $VOLUME_MOUNTS \
            $ENV_VARS \
            $NETWORK_OPT \
            $GROUPS \
            --name $TEMP_NAME \
            --entrypoint /bin/sh \
            $CONTAINER_IMAGE"
        eval "$CMD"
    fi
}
