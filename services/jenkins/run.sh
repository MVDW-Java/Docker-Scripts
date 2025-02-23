source ../../core/main.sh

DockerBuild jenkins $(pwd)/data/Dockerfile

DockerBackup -n jenkins

DockerRun \
  -i "jenkins" \
  -n "jenkins" \
  --network "jenkins" \
  -p "8080:8080" \
  -p "50000:50000" \
  -v "jenkins-data:/var/jenkins_home" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -v "/certs/client:/certs/client:ro" \
  -e "JAVA_OPTS=-Dhudson.security.csrf.GlobalCrumbIssuerConfiguration.DISABLE_CSRF_PROTECTION=true" \
  -e "JENKINS_OPTS=--prefix=/" \
  --group-add "$(getent group docker | cut -d: -f3)" \
  -d
