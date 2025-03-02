DockerRun() {
    # Default values
    IMAGE=""
    CONTAINER_NAME=""
    PORTS=""
    VOLUMES=""
    ENV_VARS=""
    NETWORK=""
    DETACH=false
    REMOVE=false
    INTERACTIVE=false
    TTY=false
    RESTART=""
    GROUP_ADD=""

    # Help function
    ShowHelp() {
        echo "Docker Run Helper Function"
        echo "Usage: docker_run [OPTIONS]"
        echo "Options:"
        echo "  -i, --image          Docker image name (required)"
        echo "  -n, --name           Container name"
        echo "  -p, --port           Port mapping (can be used multiple times) format: host:container"
        echo "  -v, --volume         Volume mapping (can be used multiple times) format: host:container"
        echo "  -e, --env           Environment variable (can be used multiple times) format: KEY=VALUE"
        echo "  --network            Network to connect to"
        echo "  -d, --detach         Run container in background"
        echo "  -r, --rm             Remove container when it exits"
        echo "  -it, --interactive   Run container with interactive TTY"
        echo "  -h, --help           Show this help message"
    }

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -i|--image)
                IMAGE="$2"
                shift 2
                ;;
            -n|--name)
                CONTAINER_NAME="$2"
                shift 2
                ;;
            -p|--port)
                if [ -z "$PORTS" ]; then
                    PORTS="$2"
                else
                    PORTS="$PORTS $2"
                fi
                shift 2
                ;;
            -v|--volume)
                if [ -z "$VOLUMES" ]; then
                    VOLUMES="$2"
                else
                    VOLUMES="$VOLUMES $2"
                fi
                shift 2
                ;;
            -e|--env)
                if [ -z "$ENV_VARS" ]; then
                    ENV_VARS="$2"
                else
                    ENV_VARS="$ENV_VARS $2"
                fi
                shift 2
                ;;
            --network)
                NETWORK="$2"
                shift 2
                ;;
            -d|--detach)
                DETACH=true
                shift
                ;;
            -r|--rm)
                REMOVE=true
                shift
                ;;
            -it|--interactive)
                INTERACTIVE=true
                TTY=true
                shift
                ;;
            --restart)
                RESTART="$2"
                shift 2
                ;;
            --group-add)
                if [ -z "$GROUP_ADD" ]; then
                    GROUP_ADD="$2"
                else
                    GROUP_ADD="$GROUP_ADD $2"
                fi
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

    # Check if image is provided
    if [ -z "$IMAGE" ]; then
        echo "Error: Image name is required"
        ShowHelp
        return 1
    fi

    # Stop and remove existing container if it exists
    if [ -n "$CONTAINER_NAME" ]; then
        if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo "Stopping and removing existing container: $CONTAINER_NAME"
            docker stop "$CONTAINER_NAME" >/dev/null 2>&1
            docker rm "$CONTAINER_NAME" >/dev/null 2>&1
        fi
    fi

    # Ensure network exists
    if [ -n "$NETWORK" ]; then
        if ! docker network ls | grep -q "$NETWORK"; then
            echo "Creating network: $NETWORK"
            docker network create "$NETWORK"
        fi
    fi

    # Build docker run command
    CMD="docker run"

    # Add container name if specified
    [ -n "$CONTAINER_NAME" ] && CMD="$CMD --name $CONTAINER_NAME"

    # Add ports
    for port in $PORTS; do
        CMD="$CMD -p $port"
    done

    # Add volumes
    for volume in $VOLUMES; do
        CMD="$CMD -v $volume"
    done

    # Add environment variables
    for env_var in $ENV_VARS; do
        CMD="$CMD -e $env_var"
    done

    # Add network if specified
    [ -n "$NETWORK" ] && CMD="$CMD --network $NETWORK"

    # Add other flags
    [ "$DETACH" = true ] && CMD="$CMD -d"
    [ "$REMOVE" = true ] && CMD="$CMD --rm"
    [ "$INTERACTIVE" = true ] && CMD="$CMD -i"
    [ "$TTY" = true ] && CMD="$CMD -t"

    [ -n "$RESTART" ] && CMD="$CMD --restart $RESTART"

    for group in $GROUP_ADD; do
        CMD="$CMD --group-add $group"
    done

    # Add image name
    CMD="$CMD $IMAGE"

    # Execute the command
    echo "Executing: $CMD"
    eval "$CMD"
}
