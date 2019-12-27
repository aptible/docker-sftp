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

docker run -d --rm --name="$DB_CONTAINER" \
  --volumes-from "$DATA_CONTAINER" \
  "$IMG" >/dev/null 2>&1

echo "Waiting for DB to come online"
wait_for_db

echo "Creating user and intentionally persisting."
docker exec -it "$DB_CONTAINER" add-sftp-user foo fee
docker exec -it "$DB_CONTAINER" cp /etc/{passwd,shadow,group} /etc-backup

echo "Creating ephemeral user."
docker exec -it "$DB_CONTAINER" add-sftp-user bar bee

docker exec -it "$DB_CONTAINER" id foo >/dev/null 2>&1
docker exec -it "$DB_CONTAINER" id bar >/dev/null 2>&1

echo "Stopping DB"
docker stop "$DB_CONTAINER"

echo "Starting DB"
docker run -d --rm --name="$DB_CONTAINER" \
  --volumes-from "$DATA_CONTAINER" \
  "$IMG" >/dev/null 2>&1


echo "Checking the persistent user does exist."
docker exec -it "$DB_CONTAINER" id foo >/dev/null 2>&1

echo "Checking the ephemeral user does not exist."
! docker exec -it "$DB_CONTAINER" id bar >/dev/null 2>&1