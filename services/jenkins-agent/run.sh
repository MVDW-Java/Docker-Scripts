# Docker-Scripts/services/jenkins-agent/run.sh

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

# Generate SSH host keys if they don't exist
DockerSecrets -n jenkins-agent-ssh-host-rsa -t ssh-key --key-type rsa
DockerSecrets -n jenkins-agent-ssh-host-ecdsa -t ssh-key --key-type ecdsa
DockerSecrets -n jenkins-agent-ssh-host-ed25519 -t ssh-key --key-type ed25519

# Generate SSH keys for Jenkins agent if they don't exist
JENKINS_AGENT_KEY=$(DockerSecrets -n jenkins-agent-key -t ssh-key)
JENKINS_AGENT_PUBLIC_KEY=$(cat ../../secrets/jenkins-agent-key.pub)

DockerRun \
  -i "jenkins-agent" \
  -n "jenkins-agent" \
  --network "jenkins" \
  -v "jenkins-agent-data:/home/jenkins" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -v "$(pwd)/../../secrets/jenkins-agent-ssh-host-rsa:/etc/ssh/ssh_host_rsa_key" \
  -v "$(pwd)/../../secrets/jenkins-agent-ssh-host-rsa.pub:/etc/ssh/ssh_host_rsa_key.pub" \
  -v "$(pwd)/../../secrets/jenkins-agent-ssh-host-ecdsa:/etc/ssh/ssh_host_ecdsa_key" \
  -v "$(pwd)/../../secrets/jenkins-agent-ssh-host-ecdsa.pub:/etc/ssh/ssh_host_ecdsa_key.pub" \
  -v "$(pwd)/../../secrets/jenkins-agent-ssh-host-ed25519:/etc/ssh/ssh_host_ed25519_key" \
  -v "$(pwd)/../../secrets/jenkins-agent-ssh-host-ed25519.pub:/etc/ssh/ssh_host_ed25519_key.pub" \
  -e "JENKINS_AGENT_SSH_PUBKEY=$JENKINS_AGENT_PUBLIC_KEY" \
  -e "SKIP_SSH_KEYGEN=true" \
  --group-add "$(getent group docker | cut -d: -f3)" \
  --restart "unless-stopped" \
  -d

echo "Jenkins agent SSH private key (save this for Jenkins credentials):"
echo "$JENKINS_AGENT_KEY"
