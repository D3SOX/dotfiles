#!/usr/bin/env bash
set -euo pipefail

# Holds /tmp/android-lab-NAME.lock in this single process until it is killed.
# No child process inherits the lock, so killing the printed PID releases it.
if [[ $# -ne 1 || ! $1 =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo 'Usage: hold-lock.sh LOCK_NAME' >&2
  exit 2
fi

exec 9>>"/tmp/android-lab-$1.lock"
flock -n -E 75 9
echo "DEVICE_LOCK_ACQUIRED pid=$$"
exec sleep infinity
