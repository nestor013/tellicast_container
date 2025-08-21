#
# Docker-compose setup for running tellicast in a container
# Maintainer: Daniel R. Hurtmans
#
FROM ubuntu:20.04

LABEL maintainer="Daniel R. Hurtmans"

ARG USER_ID=${USER_ID:-1002}
ARG GROUP_ID=${GROUP_ID:-1000}
ARG USER_NAME=${USER_NAME:-eumetcast}
ARG GROUP_NAME=${GROUP_NAME:-iasi_op}

# Minimal stuff to run
RUN apt-get update && apt-get install -y pcscd libccid libgtk2.0-0 sudo

# Copy and install tellicast and token software
COPY pkgs/eumetsat/*.deb /tmp
RUN apt-get install -y /tmp/tellicast-client-*amd64.deb \
                       /tmp/SafenetAuthenticationClient-core-9.0.43-0_amd64.deb && \
    apt-get install -f && \
    rm /tmp/*.deb

# Clean cache to reduce size
RUN apt-get clean

# Add user to run tellicast inside container
RUN groupadd -g $GROUP_ID $GROUP_NAME && \
    useradd -u $USER_ID -g $GROUP_ID -d /home/$USER_NAME -s /bin/bash $USER_NAME && \
    mkdir -p /home/$USER_NAME && \
    chown $USER_NAME:$GROUP_NAME /home/$USER_NAME

# Add user in sudoers for start-up commands
RUN echo $USER_NAME ALL=NOPASSWD: /etc/init.d/pcscd >> /etc/sudoers.d/$USER_NAME && \
    echo $USER_NAME ALL=NOPASSWD: /etc/init.d/SACSrv >> /etc/sudoers.d/$USER_NAME && \
    echo $USER_NAME ALL=NOPASSWD: /etc/init.d/tellicast-client >> /etc/sudoers.d/$USER_NAME

# Copy entry-point and make it run
COPY pkgs/drh/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

