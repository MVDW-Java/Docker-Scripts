FROM jenkins/ssh-agent:latest-jdk11

USER root

# Install essential tools
RUN apt-get update && \
    apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    lsb-release \
    nano \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
    https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Create required directories and set permissions
RUN mkdir -p /home/jenkins/.ssh && \
    chown -R jenkins:jenkins /home/jenkins/.ssh && \
    chmod 700 /home/jenkins/.ssh

# Switch to jenkins user
USER jenkins

EXPOSE 22

ENTRYPOINT ["setup-sshd"]
