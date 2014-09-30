#!/usr/bin/env bats

setup() {
  export SSH_OPTS="-o StrictHostKeyChecking=no -o Port=2222"
}

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
  sleep 0.25
  sshpass -p password sftp $SSH_OPTS aptible@localhost << EOF
    ls
EOF
}

@test "It should allow SCP" {
  touch $BATS_TMPDIR/ok
  USERNAME=aptible PASSWORD=password /usr/bin/start-sftp-server &> /dev/null &
  sleep 0.25
  run sshpass -p password scp $SSH_OPTS $BATS_TMPDIR/ok aptible@localhost:
  [[ "$status" -eq "0" ]]
  [[ -e /home/aptible/ok ]]
  rm /home/aptible/ok
}

@test "It should disallow SSH" {
  USERNAME=aptible PASSWORD=password /usr/bin/start-sftp-server &
  run sshpass -p password ssh $SSH_OPTS aptible@localhost
  [[ "$status" -ne "0" ]]
}
