#!/usr/bin/env bats

teardown() {
  deluser aptible || true
  pkill sshd || true
  pkill rsyslogd || true
  pkill tail || true
}

@test "It should install sshd " {
  run /usr/sbin/sshd -v
  [[ "$output" =~ "OpenSSH_6.6.1p1" ]]
}

@test "It should fail without USERNAME and PASSWORD " {
  run /usr/bin/start-sftp-server
  [[ "$status" -ne "0" ]]
  [[ "$output" =~ '$USERNAME and $PASSWORD must be set' ]]
}

@test "It should set USERNAME and PASSWORD" {
  USERNAME=aptible PASSWORD=password /usr/bin/start-sftp-server &
  sleep 1
  sshpass -p password sftp -o StrictHostKeyChecking=no aptible@localhost << EOF
    ls
EOF
}

@test "It should allow SCP" {
  touch $BATS_TMPDIR/ok
  USERNAME=aptible PASSWORD=password /usr/bin/start-sftp-server &> /dev/null &
  sleep 1
  run sshpass -p password scp -o StrictHostKeyChecking=no \
    $BATS_TMPDIR/ok aptible@localhost:
  [[ "$status" -eq "0" ]]
  [[ -e /home/aptible/ok ]]
  rm /home/aptible/ok
}

@test "It should disallow SSH" {
  USERNAME=aptible PASSWORD=password /usr/bin/start-sftp-server &
  sleep 1
  run sshpass -p password ssh -o StrictHostKeyChecking=no aptible@localhost
  [[ "$status" -ne "0" ]]
}
