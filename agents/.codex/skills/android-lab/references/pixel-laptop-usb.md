# Pixel USB through the laptop

Use this route whenever the Pixel is plugged into `nico-laptop` with USB debugging authorized. SSH carries files and commands to the laptop, whose ADB (`/usr/bin/adb`) controls the phone over USB. No `adb connect` is needed.

Replace `PIXEL_USB_SERIAL` with its value from [../local.md](../local.md), and `APP_ID` and `LAUNCH_COMPONENT` with the selected build's values. Choose a task-specific name in place of `TASK`.

## Locks

Take the local `pixel` lock, then the laptop's `/tmp/android-lab-pixel.lock` with the inline remote holder from [lab locks](locks.md#locks-on-nico-laptop).

## Transfer, install and control

```bash
ssh -o BatchMode=yes nico-laptop \
  '/usr/bin/adb -s PIXEL_USB_SERIAL shell am get-current-user'
rsync --inplace --no-whole-file PATH_TO_APK nico-laptop:/tmp/android-pixel-TASK.apk
ssh -o BatchMode=yes nico-laptop \
  '/usr/bin/adb -s PIXEL_USB_SERIAL install --user 0 -r /tmp/android-pixel-TASK.apk'
ssh -o BatchMode=yes nico-laptop \
  '/usr/bin/adb -s PIXEL_USB_SERIAL shell am start --user 0 -n LAUNCH_COMPONENT'
```

`rsync` reuses unchanged bytes on later transfers. Require the install's `Success` output and check the package's version and `lastUpdateTime` with `dumpsys package APP_ID`: a wireless `--fastdeploy` attempt once exited 0 while leaving the old build installed.

Run other ADB commands the same way, including instrumentation, logcat, input and package inspection. For screenshots, don't allocate a TTY: `ssh ... '/usr/bin/adb -s PIXEL_USB_SERIAL exec-out screencap -p' > FILE.png`.

## WebView inspection from this host

Find the app's PID and create a forward on the laptop as in the main skill's WebView section, running the `adb` commands through SSH; `forward tcp:0` prints the laptop port. Then tunnel it to this host as a separate long-running command, using a free local port:

```bash
ssh -N -o BatchMode=yes -o ExitOnForwardFailure=yes \
  -L 127.0.0.1:LOCAL_PORT:127.0.0.1:LAPTOP_PORT nico-laptop
```

Local CDP tools then discover pages at `http://127.0.0.1:LOCAL_PORT/json`. Recreate the forward if the app process restarts.

For screen-lock tests, check Android's power state with `dumpsys power`; `document.hidden` can stay false for a while after the screen turns off. After waking and dismissing the keyguard, launch the activity again to bring the app back from background or picture-in-picture.

## Cleanup

Restore the user's settings and app state, including route and playback, and keep existing app data and downloads. Remove test-only packages, the transferred APK, and only your own ADB forward (`forward --remove tcp:LAPTOP_PORT`). Close the tunnel, then release the remote lock and the local one.
