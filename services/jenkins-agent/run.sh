# include required scripts
source ../../core/build.sh
source ../../core/backup.sh
source ../../core/run.sh
source ../../core/secrets.sh

# safety when an error occurs
set -e

# build and deploy
DockerBuild jenkins-agent $(pwd)/data/Dockerfile

DockerBackup -n jenkins-agent

# Generate SSH keys for Jenkins agent if they don't exist
JENKINS_AGENT_KEY=$(DockerSecrets -n jenkins-agent-key -t ssh-key)
JENKINS_AGENT_PUBLIC_KEY=$(cat ../../secrets/jenkins-agent-key.pub | sed 's/"/\"/g')

DockerRun \
  -i "jenkins-agent" \
  -n "jenkins-agent" \
  --network "jenkins" \
  -v "jenkins-agent-data:/home/jenkins" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -e "JENKINS_AGENT_SSH_PUBKEY=\"${JENKINS_AGENT_PUBLIC_KEY}\"" \
  --group-add "$(getent group docker | cut -d: -f3)" \
  -d

echo "Jenkins agent SSH private key (save this for Jenkins credentials):"
echo "$JENKINS_AGENT_KEY"
