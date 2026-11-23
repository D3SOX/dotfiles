#!/usr/bin/env bash
set -euo pipefail

# The caller holds the device lock and, for nonbaseline AVDs, the port lock.
if [[ $# -ne 2 || ! $1 =~ ^[a-zA-Z0-9_-]+$ || ! $2 =~ ^[0-9]+$ ]]; then
  echo 'Usage: start-emulator.sh AVD_NAME CONSOLE_PORT' >&2
  exit 2
fi

# The emulator prefers ANDROID_HOME, which the login shell points at the
# image-less /opt/android-sdk, so set both.
export ANDROID_SDK_ROOT=/run/media/nico/200GB_DATA/android-emulator-sdk
export ANDROID_HOME=$ANDROID_SDK_ROOT
export ANDROID_AVD_HOME=/run/media/nico/200GB_DATA/android-emulator-avds
serial=emulator-$2

# Graphics: emulator 37.x segfaults in RenderThread with swiftshader and
# swiftshader_indirect, so use swangle (ANGLE over SwiftShader Vulkan). The
# launcher picks its GL library from -gpu before reading config.ini, so pass it
# explicitly; the startup log's Graphics Adapter should contain ANGLE.
#
# Boot crashes: emulator 37.x's modem simulator (API 30+ images) has a data race
# (ChannelMonitor) that segfaults up to a quarter of cold boots about 13 seconds
# in; hw.gsmModem=no does not avoid it. The emulator removes bootcompleted.ini
# at launch and recreates it once Android has booted, so relaunch only crashes
# that happen before boot completes. A 139 after boot, including the frequent
# harmless one during `adb emu kill`, goes to the caller.
trap 'kill $(jobs -p) 2>/dev/null; wait; exit 143' INT TERM HUP
for attempt in 1 2 3 4 5; do
  "$ANDROID_SDK_ROOT/emulator/emulator" \
    -avd "$1" -port "$2" -no-window -no-audio -no-boot-anim \
    -gpu swangle -no-snapshot &
  emulator=$!
  until [[ $(timeout 10 adb -s "$serial" shell getprop sys.boot_completed 2>/dev/null) == 1* ]]; do
    kill -0 "$emulator" 2>/dev/null || break
    sleep 2
  done
  kill -0 "$emulator" 2>/dev/null && echo "EMULATOR_BOOTED serial=$serial"
  status=0
  wait "$emulator" || status=$?
  if ((status != 139 || attempt == 5)) ||
    [[ -e $ANDROID_AVD_HOME/$1.avd/bootcompleted.ini ]]; then
    exit "$status"
  fi
  echo "start-emulator.sh: emulator segfaulted during boot; relaunching ($attempt/4)" >&2
done
