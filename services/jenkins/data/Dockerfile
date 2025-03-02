FROM jenkins/jenkins:lts
USER root
RUN apt-get update && apt-get install -y lsb-release python3-pip nano vim \
    curl
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
    https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y docker-ce-cli
USER jenkins
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN . nvm install 22 | bash

#RUN jenkins-plugin-cli --plugins "blueocean:1.25.3 docker-workflow:1.28"
