#!/usr/bin/env bats

teardown() {
  deluser admin || true
  deluser test || true
  pkill sshd || true
  pkill rsyslogd || true
  pkill tail || true

  rm -rf /home/admin
  rm -rf /home/test
  rm -f /var/log/auth.log

  rm -f /etc/ssh/keys/*_key /etc/ssh/keys/*_key.pub
  rm -f /root/.ssh/known_hosts
}

wait_for_sftp() {
  ADMIN_USER=admin PASSWORD=password /usr/bin/start-sftp-server &
  while ! pgrep tail ; do sleep 0.1; done
}

@test "It should install sshd " {
  run /usr/sbin/sshd -v
  [[ "$output" =~ "OpenSSH_6.6.1p1" ]]
}

@test "It should fail without ADMIN_USER and PASSWORD " {
  run /usr/bin/start-sftp-server
  [[ "$status" -ne "0" ]]
  [[ "$output" =~ '$ADMIN_USER and $PASSWORD must be set' ]]
}

@test "It should set ADMIN_USER and PASSWORD" {
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
  /usr/bin/add-sftp-user test $(cat $BATS_TEST_DIRNAME/test.pub)
  run scp -i $BATS_TEST_DIRNAME/test -o StrictHostKeyChecking=no \
    $BATS_TMPDIR/ok test@localhost:
  [[ "$status" -ne "0" ]]
}

@test "It should allow SFTP for regular users" {
  # Quay appears to be changing file permissions...
  if [ ! $(stat --format '%a' $BATS_TEST_DIRNAME/test) == "600" ]; then
    skip
  fi

  wait_for_sftp
  /usr/bin/add-sftp-user test $(cat $BATS_TEST_DIRNAME/test.pub)
  sftp -i $BATS_TEST_DIRNAME/test -o StrictHostKeyChecking=no test@localhost << EOF
    ls
EOF
}

@test "It should disallow SSH for regular users" {
  wait_for_sftp
  /usr/bin/add-sftp-user test $(cat $BATS_TEST_DIRNAME/test.pub)
  run ssh -i $BATS_TEST_DIRNAME/test -o StrictHostKeyChecking=no test@localhost
  [[ "$status" -ne "0" ]]
}
