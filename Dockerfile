ARG ubuntu_version="22.04"

FROM ubuntu:$ubuntu_version

ARG uid=1000
ARG gid=1000
ARG user=user
ARG docker_gid=998

ENV DEBIAN_FRONTEND=noninteractive
RUN yes | unminimize
RUN apt-get install -y \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg \
        locales \
        lsb-release \
        man \
        openssh-server \
        rsync \
        sudo \
        tmux \
        unzip \
        zip \
        zsh \
&&  locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Docker
RUN groupadd -g $docker_gid docker \
&&  mkdir -p /etc/apt/keyrings \
&&  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
&&  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
&&  apt-get update \
&&  sudo apt-get install -y docker-ce docker-ce-cli docker-compose-plugin

# User
RUN groupadd -g $gid $user \
&&  useradd -u $uid -g $gid -G sudo,docker -m -s /usr/bin/zsh $user
RUN echo $user "ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_user_nopasswd
COPY authorized_keys /tmp
RUN sshdir=/home/$user/.ssh \
;   mkdir -p $sshdir \
&&  mv /tmp/authorized_keys $sshdir/authorized_keys \
&&  chmod 0700 $sshdir \
&&  chmod 0600 $sshdir/authorized_keys \
&&  chown -R $uid:$gid $sshdir

# Dotfiles
USER $user
RUN cd \
;   git clone https://github.com/spacifici/dotfiles.git .dotfiles \
&&  cd .dotfiles \
&&  make install

# SSH
USER root
COPY sshd_config /etc/ssh/sshd_config
RUN mkdir -p /var/run/sshd \
&&  chmod 755 /var/run/sshd \
&&  chmod 0600 /etc/ssh/sshd_config

EXPOSE 22

COPY init.sh /root/
RUN echo $user > /root/.userinfo
ENTRYPOINT /root/init.sh $user

