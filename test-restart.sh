#!/bin/bash
set -o errexit
set -o nounset

IMG="$1"

DB_CONTAINER="sftp"
DATA_CONTAINER="${DB_CONTAINER}-data"

function cleanup {
  echo "Cleaning up"
  docker rm -f "$DB_CONTAINER" "$DATA_CONTAINER" >/dev/null 2>&1 || true
}

function wait_for_db {
  for _ in $(seq 1 100); do
    if docker exec -it "$DB_CONTAINER" pgrep tail >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done

  echo "DB never came online"
  docker logs "$DB_CONTAINER"
  return 1
}

trap cleanup EXIT
cleanup

echo "Creating data container"
docker create --name "$DATA_CONTAINER" "$IMG"

echo "Starting DB"
docker run -it --rm \
  -e USERNAME=user -e PASSPHRASE=pass \
  --volumes-from "$DATA_CONTAINER" \
  "$IMG" --initialize \
  >/dev/null 2>&1

docker run -d --name="$DB_CONTAINER" \
  --volumes-from "$DATA_CONTAINER" \
  "$IMG" >/dev/null 2>&1

echo "Waiting for DB to come online"
wait_for_db

echo "Creating additional users."
docker exec "$DB_CONTAINER" add-sftp-user foo fee
docker exec "$DB_CONTAINER" useradd bar

echo "Modify the sshd config."
docker exec "$DB_CONTAINER" bash -c "echo '#foobar' >> /etc/ssh/sshd_config"

echo "Stopping DB"
docker stop "$DB_CONTAINER" >/dev/null 2>&1

echo "Check that SSHD was terminated."
docker logs "$DB_CONTAINER" | grep "Received signal 15; terminating." >/dev/null 2>&1

echo "Esnure we got warned that an sshd_config was modified"
docker logs "$DB_CONTAINER" | grep 'WARNING - changes detected in /etc/ssh/sshd_config' >/dev/null 2>&1

echo "Simulate deploy restart (volume persists, container recycled)"
docker rm "$DB_CONTAINER" >/dev/null
docker run -d --name="$DB_CONTAINER" \
  --volumes-from "$DATA_CONTAINER" \
  "$IMG" >/dev/null 2>&1

echo "Checking the additional users do exist."
docker exec "$DB_CONTAINER" id foo >/dev/null 2>&1
docker exec "$DB_CONTAINER" id bar >/dev/null 2>&1

echo "Check the sshd_config modifications were lost."
! docker exec "$DB_CONTAINER" grep "foobar" /etc/ssh/sshd_config >/dev/null 2>&1

echo "Modify and persist the sshd_config."
docker exec "$DB_CONTAINER" mkdir /etc-backup/ssh
docker exec "$DB_CONTAINER" bash -c "echo '#foobar' >> /etc/ssh/sshd_config"
docker exec "$DB_CONTAINER" cp /etc/ssh/sshd_config /etc-backup/ssh/

echo "Simulate deploy restart (volume persists, container recycled)"
docker stop "$DB_CONTAINER" >/dev/null 2>&1
docker rm "$DB_CONTAINER" >/dev/null
docker run -d --rm --name="$DB_CONTAINER" \
  --volumes-from "$DATA_CONTAINER" \
  "$IMG" >/dev/null 2>&1

echo "Ensure the sshd file is still modified"
docker exec "$DB_CONTAINER" grep "foobar" /etc/ssh/sshd_config >/dev/null 2>&1
