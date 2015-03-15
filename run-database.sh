#!/bin/bash

if [[ "$1" == "--initialize" ]]; then
  ssh-keygen -f /etc/ssh/keys/ssh_host_ecdsa_key -N '' -t ecdsa
  ssh-keygen -f /etc/ssh/keys/ssh_host_rsa_key -N '' -t rsa
  ssh-keygen -f /etc/ssh/keys/ssh_host_dsa_key -N '' -t dsa
  add-privileged-user $USERNAME $PASSPHRASE
  cp /etc/{passwd,shadow,group} /etc-backup
  exit
fi

cp /etc-backup/* /etc
rsyslogd
/usr/sbin/sshd

# Wait for /var/log/auth.log to exist, then tail it
while [ ! -f /var/log/auth.log ] ; do sleep 0.1; done
tail -f /var/log/auth.log
