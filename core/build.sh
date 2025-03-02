DockerBuild() {
    dockerName=$1
    dockerFilePath=$2

    if [ -z "$dockerName" ] || [ -z "$dockerFilePath" ]; then
        echo "Usage: docker_build <docker-name> <dockerfile-path>"
        return 1
    fi

    if [ ! -f "$dockerFilePath" ]; then
        echo "Dockerfile not found at: $dockerFilePath"
        return 1
    fi

    echo "Building docker image: $dockerName"
    echo "Using Dockerfile at: $dockerFilePath"

    # Build new image first
    docker build -t "$dockerName" -f "$dockerFilePath" .

    # Remove old image if it exists
    if docker image inspect "$dockerName" >/dev/null 2>&1; then
        echo "Removing old image with same name (if any)"
        docker images | grep "$dockerName" | grep -v "$(docker images --quiet "$dockerName":latest)" | awk '{print $3}' | xargs -r docker rmi
    fi
}
