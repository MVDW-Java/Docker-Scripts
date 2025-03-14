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
    mkdir -p /run/sshd && \
    chown -R jenkins:jenkins /home/jenkins/.ssh && \
    chmod 700 /home/jenkins/.ssh && \
    chown -R jenkins:jenkins /run/sshd

# Ensure /etc/environment is writable by jenkins user
RUN touch /etc/environment && \
    chown jenkins:jenkins /etc/environment && \
    chmod 644 /etc/environment

# Create and set permissions for SSHD PID directory
RUN mkdir -p /var/run/sshd && \
    chmod 755 /var/run/sshd && \
    chown jenkins:jenkins /var/run/sshd

# Switch to jenkins user
USER jenkins

EXPOSE 22

ENTRYPOINT ["setup-sshd"]
