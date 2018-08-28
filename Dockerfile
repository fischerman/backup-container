FROM ubuntu:18.04

RUN apt-get update && apt-get install -y rsync rdiff-backup curl postgresql-client bc openssh-client
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    pg_dump --version
RUN curl -LO https://github.com/borgbackup/borg/releases/download/1.1.7/borg-linux64 && \
    mv borg-linux64 /usr/local/bin/borg && \
    chown root:root /usr/local/bin/borg && \
    chmod 755 /usr/local/bin/borg

ADD backup-nextcloud.sh /
RUN chmod +x /backup-nextcloud.sh