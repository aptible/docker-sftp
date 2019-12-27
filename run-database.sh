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
cp /etc-backup/ssh/* /etc/ssh/

echo "$SSHD_CONFIG_SHA1SUM /etc/ssh/sshd_config" | sha1sum -c - \
  || echo "WARNING: unexpected hash for /etc/ssh/sshd_config. "\
           "This _may_ be malicious, or you may have intended to "\
           "change this file."

# Ensure that rsyslogd creates the socket
rm -f /home/.sharedlogsocket
rsyslogd
/usr/sbin/sshd

echo "Verbose logging enabled for all users by default"
echo "Add user names, one per line, to '/home/.nolog' to disable for that user"
set-access-log

# Wait for /var/log/auth.log to exist, then tail it
while [ ! -f /var/log/auth.log ] ; do sleep 0.1; done
tail -f /var/log/auth.log
