#!/usr/bin/env bats

teardown() {
  deluser admin || true
  deluser test || true
  pkill sshd || true
  pkill rsyslogd || true
  rm /var/run/rsyslogd.pid
  rm /home/.sharedlogsocket
  pkill tail || true

  rm -rf /home/admin
  rm -rf /home/test
  rm -rf /home/.nolog
  rm -f /var/log/auth.log

  rm -f /etc/ssh/keys/*_key /etc/ssh/keys/*_key.pub
  rm -f /root/.ssh/known_hosts
}

wait_for_sftp() {
  USERNAME=admin PASSPHRASE=password run-database.sh --initialize
  run-database.sh &
  while ! pgrep tail ; do sleep 0.1; done
  while ! pgrep rsyslog ; do sleep 0.1; done
}

@test "It should install sshd " {
  run /usr/sbin/sshd -v
  [[ "$output" =~ "OpenSSH_6.6.1p1" ]]
}

@test "It should create an admin account" {
  wait_for_sftp
  sshpass -p password sftp -o StrictHostKeyChecking=no admin@localhost << EOF
    ls
EOF
}

@test "It should allow SCP for admins" {
  touch $BATS_TMPDIR/ok
  wait_for_sftp
  run sshpass -p password scp -o StrictHostKeyChecking=no \
    $BATS_TMPDIR/ok admin@localhost:
  [[ "$status" -eq "0" ]]
  [[ -e /home/admin/ok ]]
  rm /home/admin/ok
}

@test "It should allow SSH for admins" {
  wait_for_sftp
  run sshpass -p password ssh -o StrictHostKeyChecking=no admin@localhost
  [[ "$status" -eq "0" ]]
}

@test "It should allow sudo for admins" {
  wait_for_sftp
  run sshpass -p password ssh -o StrictHostKeyChecking=no admin@localhost sudo ls
  [[ "$status" -eq "0" ]]
}

@test "It should disallow SCP for regular users" {
  touch $BATS_TMPDIR/ok
  wait_for_sftp
  /usr/bin/add-sftp-user test "$(cat $BATS_TEST_DIRNAME/testkey.pub)"
  run scp -i $BATS_TEST_DIRNAME/testkey -o StrictHostKeyChecking=no \
    $BATS_TMPDIR/ok test@localhost:
  [[ "$status" -ne "0" ]]
}

@test "It should allow SFTP for regular users" {
  wait_for_sftp
  /usr/bin/add-sftp-user test "$(cat $BATS_TEST_DIRNAME/testkey.pub)"
  sftp -i $BATS_TEST_DIRNAME/testkey -o StrictHostKeyChecking=no test@localhost << EOF
    ls
EOF
}

@test "It should disallow SSH for regular users" {
  wait_for_sftp
  /usr/bin/add-sftp-user test "$(cat $BATS_TEST_DIRNAME/testkey.pub)"
  run ssh -i $BATS_TEST_DIRNAME/testkey -o StrictHostKeyChecking=no test@localhost
  [[ "$status" -ne "0" ]]
}

@test "It should log all SFTP access verbosely" {
  wait_for_sftp
  /usr/bin/add-sftp-user test "$(cat $BATS_TEST_DIRNAME/testkey.pub)"

  sftp -i $BATS_TEST_DIRNAME/testkey -o StrictHostKeyChecking=no test@localhost << EOF
    mkdir testcreatedir
EOF
  grep 'testcreatedir' /var/log/auth.log


  # ... even after a restart ...
  kill -TERM "$(cat /var/run/rsyslogd.pid)"
  rm -f /home/.sharedlogsocket
  sleep 1
  rsyslogd
  set-access-log test

  sftp -i $BATS_TEST_DIRNAME/testkey -o StrictHostKeyChecking=no test@localhost << EOF
    mkdir testcreatedir2
EOF
  grep 'testcreatedir2' /var/log/auth.log
}

@test "It should allow disabling verbose logging for SFTP users" {
  wait_for_sftp

  /usr/bin/add-sftp-user test "$(cat $BATS_TEST_DIRNAME/testkey.pub)"

  echo "test" >> /home/.nolog
  set-access-log test

  sftp -i $BATS_TEST_DIRNAME/testkey -o StrictHostKeyChecking=no test@localhost << EOF
    mkdir testcreatedir3
EOF
  run grep 'testcreatedir3' /var/log/auth.log
  [[ "$status" -ne "0" ]]
}

@test "It should prevent an SFTP user from disabling their own logging" {
  wait_for_sftp
  /usr/bin/add-sftp-user test "$(cat $BATS_TEST_DIRNAME/testkey.pub)"

  # Try to delete the socket
  sftp -i $BATS_TEST_DIRNAME/testkey -o StrictHostKeyChecking=no test@localhost << EOF
    rm /dev/log
EOF
  grep 'sent status Permission denied' /var/log/auth.log

  # Try to upload a file over the socket
  touch /home/test/log
  sftp -i $BATS_TEST_DIRNAME/testkey -o StrictHostKeyChecking=no test@localhost << EOF
    cd /dev
    put /home/test/log
EOF
  grep 'sent status Failure' /var/log/auth.log
}

@test "It should disable RepeatedMsgReduction in rsyslog" {
  grep -r "RepeatedMsgReduction off" /etc/rsyslog.d/
}
