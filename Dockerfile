FROM quay.io/aptible/ubuntu:14.04

RUN apt-get update
RUN apt-get -y install openssh-server rssh
RUN mkdir -p /var/run/sshd

ADD templates/etc /etc

ADD templates/bin /usr/bin
RUN chmod +x /usr/bin/start-sftp-server

VOLUME /home

EXPOSE 22

# Integration tests
RUN apt-get -y install sshpass
ADD test /tmp/test
RUN bats /tmp/test

CMD /usr/bin/start-sftp-server
