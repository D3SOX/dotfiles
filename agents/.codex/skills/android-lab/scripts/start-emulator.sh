#!/usr/bin/env bash
set -euo pipefail

# The caller holds the device lock and, for nonbaseline AVDs, the port lock.
if [[ $# -ne 2 || ! $1 =~ ^[a-zA-Z0-9_-]+$ || ! $2 =~ ^[0-9]+$ ]]; then
  echo 'Usage: start-emulator.sh AVD_NAME CONSOLE_PORT' >&2
  exit 2
fi

export ANDROID_SDK_ROOT=/run/media/nico/200GB_DATA/android-emulator-sdk
export ANDROID_AVD_HOME=/run/media/nico/200GB_DATA/android-emulator-avds

# Emulator 37.x's modem simulator (API 30+ images) has a data race that
# segfaults up to a quarter of cold boots. The emulator removes
# bootcompleted.ini at launch and recreates it once Android has booted, so
# relaunch only crashes that happen before boot completes.
trap 'kill $(jobs -p) 2>/dev/null; wait; exit 143' INT TERM HUP
for attempt in 1 2 3 4 5; do
  "$ANDROID_SDK_ROOT/emulator/emulator" \
    -avd "$1" -port "$2" -no-window -no-audio -no-boot-anim \
    -gpu swangle -no-snapshot &
  status=0
  wait "$!" || status=$?
  if ((status != 139 || attempt == 5)) ||
    [[ -e $ANDROID_AVD_HOME/$1.avd/bootcompleted.ini ]]; then
    exit "$status"
  fi
  echo "start-emulator.sh: emulator segfaulted during boot; relaunching ($attempt/4)" >&2
done
