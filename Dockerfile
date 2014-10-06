FROM quay.io/aptible/ubuntu:14.04

RUN apt-get update
RUN apt-get -y install openssh-server rssh sudo
RUN mkdir -p /var/run/sshd
RUN groupadd sftpusers
RUN chmod +s /usr/bin/sudo

# Delete default host keys
RUN rm /etc/ssh/*_key /etc/ssh/*_key.pub

ADD templates/etc /etc

ADD templates/bin /usr/bin
RUN chmod +x /usr/bin/start-sftp-server

VOLUME /home
VOLUME /etc/ssh/keys

EXPOSE 22

# Integration tests
RUN apt-get -y install sshpass
ADD test /tmp/test
RUN bats /tmp/test

CMD /usr/bin/start-sftp-server
