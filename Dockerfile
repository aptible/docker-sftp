FROM quay.io/aptible/ubuntu:14.04

RUN apt-get update
RUN apt-get -y install openssh-server rssh sudo
RUN mkdir -p /var/run/sshd
RUN groupadd sftpusers
RUN chmod +s /usr/bin/sudo

# Delete default host keys
RUN rm /etc/ssh/*_key /etc/ssh/*_key.pub

ENV SSHD_CONFIG_SHA1SUM ad2a2b17ecde36c7ff9b0c55f925754e881bd1f5
ADD templates/etc /etc
ADD templates/bin /usr/bin

VOLUME ["/home", "/etc-backup", "/etc/ssh/keys", "/sftp"]

ADD run-database.sh /usr/bin/

# Integration tests
RUN apt-get -y install sshpass
ADD test /tmp/test
# Ensure private key permissions are correct for testing
RUN chmod 600 /tmp/test/testkey && bats /tmp/test

EXPOSE 22

ENTRYPOINT ["run-database.sh"]
