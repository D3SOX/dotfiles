# Pixel USB through the laptop

Use this route when the Pixel is plugged into Nico's laptop with USB debugging authorized. It worked when direct Tailscale APK transfers to the phone suffered heavy packet loss. SSH carries files and commands to the laptop; the laptop's ADB controls the phone over USB.

```text
SSH alias:       nico-laptop
Remote ADB:      /usr/bin/adb
Android user:   0
```

Read [../local.md](../local.md) and replace `PIXEL_USB_SERIAL` below with its private value before executing commands. Prefer the SSH alias over the recorded IP in that file. No `adb connect` is needed for USB. Use the selected build's application ID and launch component in place of `APP_ID` and `LAUNCH_COMPONENT` below. Choose a task-specific remote APK filename in place of `TASK`; reuse it only within that task.

## Acquire both locks

Acquire the local Pixel lock as described in the main skill, then acquire `/tmp/opentubex-android-pixel.lock` on the laptop before any device commands. Both hosts may have agents using the phone.

Run the remote holder in its own interactive exec session with `tty: true`:

```bash
ssh -tt -o BatchMode=yes nico-laptop \
  "flock -n -E 75 /tmp/opentubex-android-pixel.lock bash -c 'echo DEVICE_LOCK_ACQUIRED; exec sleep infinity'"
```

Continue only after the remote `DEVICE_LOCK_ACQUIRED` appears. Keep both sessions running throughout the work. If either lock is busy, release any lock acquired for this attempt and wait or use a free emulator. Never delete lock files or terminate another agent's holder.

## Transfer, install, and control

Confirm the USB device is available and check the current Android user before installing. Install only for user 0; do not touch users 10 or 11.

```bash
ssh -o BatchMode=yes nico-laptop '/usr/bin/adb devices -l'
ssh -o BatchMode=yes nico-laptop \
  '/usr/bin/adb -s PIXEL_USB_SERIAL shell am get-current-user'
scp PATH_TO_APK nico-laptop:/tmp/android-pixel-TASK.apk
ssh -o BatchMode=yes nico-laptop \
  '/usr/bin/adb -s PIXEL_USB_SERIAL install --user 0 -r /tmp/android-pixel-TASK.apk'
ssh -o BatchMode=yes nico-laptop \
  '/usr/bin/adb -s PIXEL_USB_SERIAL shell am start --user 0 -n LAUNCH_COMPONENT'
```

For subsequent APK transfers, `rsync --inplace --no-whole-file PATH_TO_APK nico-laptop:/tmp/android-pixel-TASK.apk` can reuse unchanged bytes. Wait for the transfer to finish before installing.

Require the install's `Success` output and verify the selected package's version/build and `lastUpdateTime` with `adb shell dumpsys package APP_ID`. A prior wireless `--fastdeploy` attempt exited 0 after only `Performing Streamed Install` while leaving the old build installed. Do not infer installation from that exit status alone.

Run other ADB operations through the same SSH command and explicit USB serial, including instrumentation, logcat, input events, screenshots, and package inspection. Keep binary screenshot output in a file with `ssh ... '... exec-out screencap -p' > /tmp/pixel.png`; do not allocate a TTY for binary output.

## Inspect a WebView from this host

For a debuggable WebView-based build, find the current app PID and its WebView debugging socket on the laptop. The socket is typically `webview_devtools_remote_<PID>`; verify it in `/proc/net/unix`. Recreate the forward if the app process restarts.

```bash
ssh -o BatchMode=yes nico-laptop \
  '/usr/bin/adb -s PIXEL_USB_SERIAL shell pidof APP_ID'
ssh -o BatchMode=yes nico-laptop \
  '/usr/bin/adb -s PIXEL_USB_SERIAL shell cat /proc/net/unix'
```

The following ports worked previously. Check that they are free and choose alternatives if occupied. Replace `APP_PID` with the verified PID, then create the ADB forward:

```bash
ssh -o BatchMode=yes nico-laptop \
  '/usr/bin/adb -s PIXEL_USB_SERIAL forward --no-rebind tcp:41093 localabstract:webview_devtools_remote_APP_PID'
```

Keep this SSH tunnel in a separate running exec session:

```bash
ssh -N -o BatchMode=yes -o ExitOnForwardFailure=yes \
  -L 127.0.0.1:9237:127.0.0.1:41093 nico-laptop
```

Local CDP tools can now discover pages at `http://127.0.0.1:9237/json`. Keep the tunnel bound to loopback.

For screen-lock tests, verify Android's power state with `dumpsys power`. `document.hidden` can remain false temporarily while Android is inactive. After waking and dismissing the keyguard, launch the activity again to restore the full app from background or picture-in-picture.

## Cleanup

Restore the user's original settings and app state, including route and playback when applicable, and preserve existing app data/downloads. Remove test-only packages and transferred APKs created by this test. Remove only the ADB forward created for this session, for example:

```bash
ssh -o BatchMode=yes nico-laptop \
  '/usr/bin/adb -s PIXEL_USB_SERIAL forward --remove tcp:41093'
```

Close the SSH tunnel, then send Ctrl-C to the remote lock-holder session and the local holder after all device commands finish. If a connection drops, verify that your remote holder exited before considering cleanup complete; do not assume closing the local SSH process released the remote lock.
