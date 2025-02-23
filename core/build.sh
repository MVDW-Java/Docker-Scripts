DockerBuild() {
    local dockerName=$1
    local dockerFilePath=$2

    if [ -z "$dockerName" ] || [ -z "$dockerFilePath" ]; then
        echo "Usage: DockerBuild <docker-name> <dockerfile-path>"
        return 1
    fi

    if [ ! -f "$dockerFilePath" ]; then
        echo "Dockerfile not found at: $dockerFilePath"
        return 1
    fi

    echo "Building docker image: $dockerName"
    echo "Using Dockerfile at: $dockerFilePath"

    # Remove old image if it exists
    if docker image inspect "$dockerName" >/dev/null 2>&1; then
        echo "Removing old image: $dockerName"
        docker rmi "$dockerName"
    fi

    docker build -t "$dockerName" -f "$dockerFilePath" .
}
