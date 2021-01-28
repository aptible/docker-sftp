#!/bin/bash

if [[ "$1" == "--initialize" ]]; then
  ssh-keygen -f /etc/ssh/keys/ssh_host_ecdsa_key -N '' -t ecdsa
  ssh-keygen -f /etc/ssh/keys/ssh_host_rsa_key -N '' -t rsa
  ssh-keygen -f /etc/ssh/keys/ssh_host_dsa_key -N '' -t dsa
  add-privileged-user "$USERNAME" "$PASSPHRASE"
  exit
fi

function exit_gracefully {
	SSH_PID=$(cat /var/run/sshd.pid)
	kill -TERM "$SSH_PID"
	sleep 2
	backup-users
	warn-sshd-config
}

trap exit_gracefully TERM INT

cp /etc-backup/* /etc
cp /etc-backup/ssh/* /etc/ssh/

# Ensure that rsyslogd creates the socket
rm -f /home/.sharedlogsocket
# Ensure /var/log is owned by the syslog group, since the GID changed
chgrp syslog /var/log
rsyslogd
/usr/sbin/sshd

echo "Verbose logging enabled for all users by default"
echo "Add user names, one per line, to '/home/.nolog' to disable for that user"
set-access-log

# Wait for /var/log/auth.log to exist, then tail it
while [ ! -f /var/log/auth.log ] ; do sleep 0.1; done
tail -f /var/log/auth.log &

# We would prefer to wait on the sshd PID, but it's not a subprocess of this shell.

TAIL_PID="$!"
wait "$TAIL_PID"
