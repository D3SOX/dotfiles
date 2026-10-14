#!/usr/bin/env bash
set -euo pipefail

# The caller holds the device lock and, for nonbaseline AVDs, the port lock.
if [[ $# -ne 2 || ! $1 =~ ^[a-zA-Z0-9_-]+$ || ! $2 =~ ^[0-9]+$ ]]; then
  echo 'Usage: start-emulator.sh AVD_NAME CONSOLE_PORT' >&2
  exit 2
fi

export ANDROID_SDK_ROOT=/run/media/nico/200GB_DATA/android-emulator-sdk
export ANDROID_AVD_HOME=/run/media/nico/200GB_DATA/android-emulator-avds
exec "$ANDROID_SDK_ROOT/emulator/emulator" \
  -avd "$1" -port "$2" -no-window -no-audio -no-boot-anim \
  -gpu swangle -no-snapshot
