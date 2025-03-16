source ../../core/build.sh
source ../../core/backup.sh
source ../../core/run.sh

# safety when an error occurs
set -e

# build and deploy
DockerBuild portainer $(pwd)/data/Dockerfile

DockerBackup -n portainer

DockerRun \
  -i "portainer" \
  -n "portainer" \
  --network "portainer" \
  -p "8000:8000" \
  -p "9000:9000" \
  -v "portainer-data:/data" \
  -v "/var/run/docker.sock:/var/run/docker.sock:ro" \
  --restart "always" \
  -d
