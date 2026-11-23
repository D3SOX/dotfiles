---
name: android-lab
description: Build and test Android apps on this machine's physical Pixel and Android emulators. Use for APK installation, ADB inspection, device lifecycle checks, or API-version coverage.
---

# Android lab

Read the target repository's instructions and discover its Android module, build variant, application ID, launch activity, instrumentation package and minimum SDK before choosing commands. Set `APP_ID` and `LAUNCH_COMPONENT` (the full `package/activity`) from the selected build variant, not from the repository name.

Before physical-device access, read [local.md](local.md) for the private `PIXEL_USB_SERIAL` and `PIXEL_ADB_ADDRESS` values and substitute them below. It is Git-ignored; preserve it when copying skill updates. If it is missing, get the values from the user or the existing device configuration.

## Locks

Follow [lab locks](references/locks.md) with `/home/nico/.codex/skills/android-lab/scripts/hold-lock.sh NAME`. Lock before `adb connect`, starting an emulator or any target-specific `adb` command.

| Target | NAME |
|---|---|
| Pixel | `pixel`, on both hosts for the laptop route |
| Emulator | its AVD name, such as `android_api35` |
| Console port for an AVD without a fixed port | `port-PORT` |

## Build environment

The shell sets `ANDROID_HOME` and `ANDROID_SDK_ROOT` to `/home/nico/Android/Sdk`, the SDK with accepted licences. If either points elsewhere, such as `/opt/android-sdk`, override both, or Gradle fails on licences or conflicting SDK paths. Use `JAVA_HOME=/usr/lib/jvm/java-21-openjdk`.

Use the repository's documented build and test workflow. For Capacitor apps, build the web assets and sync Android after renderer changes, using the project's own scripts. Run Gradle from the directory containing the wrapper, for example `JAVA_HOME=/usr/lib/jvm/java-21-openjdk ./gradlew assembleDebug testDebugUnitTest`.

Set `ANDROID_SERIAL` to your locked device for connected tasks such as `connectedDebugAndroidTest`; otherwise they run on every attached device. They uninstall the app afterward, so never run them against the Pixel.

## Physical Pixel

The Pixel 8 Pro runs LineageOS (Android 17 on 2026-11-23; read `ro.build.version.release` for the current one) and is rooted with APatch, so `adb shell su -c CMD` works. Root-dependent tools are fine when they help the task.

USB through the laptop is faster and more reliable for APK transfers, so check it first:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 nico-laptop '/usr/bin/adb devices -l'
```

If `PIXEL_USB_SERIAL` is listed as `device`, use the [laptop USB workflow](references/pixel-laptop-usb.md). Otherwise try `adb connect PIXEL_ADB_ADDRESS` over Tailscale. Port `5555` works only when TCP ADB is enabled, which the user does with the action of the phone's ADB over Network Toggle module; Wireless debugging uses a changing port the user must supply. If neither route works and the task needs the physical Pixel, ask the user with your question tool to plug it into the laptop, and continue emulator work meanwhile.

On either route:

- Run `am get-current-user` before installing. Install and launch only for Android user 0, never another user such as the Private space (user 10): `install --user 0 -r PATH_TO_APK`, then `am start --user 0 -n "$LAUNCH_COMPONENT"`.
- CorePatch (in the Vector Xposed framework) disables signature checks, so debug and release builds install over each other without losing data; verified on Android 17 on 2026-11-23. If an install fails with a signature mismatch anyway, check that `adb shell su -c "/data/adb/lspd/cli modules ls"` lists `com.coderstory.toolkit` as enabled, and ask the user before uninstalling the app or clearing its data.
- The phone holds personal notifications, accounts and files. Collapse the shade before screenshots, and check the app's notifications with `adb shell cmd notification list | rg -F -- "$APP_ID"` instead of opening the shade. Never put Pixel captures in PRs, issues, releases or other public places; for public proof, reproduce on an emulator with test data.
- Record the original value of any setting you change, and restore it. Force-stop is not a durability test for background work, since Android prevents restart until the user opens the app again.

## Emulators

```text
SDK:      /run/media/nico/200GB_DATA/android-emulator-sdk
AVD home: /run/media/nico/200GB_DATA/android-emulator-avds
```

| AVD | API | Console port | Notes |
|---|---|---|---|
| `android_api26` | 26 (8.0) | 5558 | Chrome 119 WebView installed |
| `android_api35` | 35 | 5556 | |
| `android_api35_tablet` | 35 | free one from 5560–5682 | Boots in landscape |
| `android_api37` | 37 | free one from 5560–5682 | Newest WebView |

Other AVDs may belong to a task; leave them alone. List AVDs with `emulator -list-avds` (with `ANDROID_AVD_HOME` set) and installed images under `$SDK/system-images` rather than assuming them.

After taking the AVD lock (and a port lock outside the table's fixed ports), start the emulator as its own long-running background command, like a lock holder:

```bash
/home/nico/.codex/skills/android-lab/scripts/start-emulator.sh android_api35 5556
```

Wait for `EMULATOR_BOOTED serial=emulator-PORT`. If the launcher exits first, the emulator died; read its output. The launcher forces `-gpu swangle` and relaunches the emulator when it crashes during boot, printing a `relaunching` line and the marker again. Never launch emulators another way or change the GPU mode; the script's comments explain why. Stop with `adb -s emulator-PORT emu kill` and wait for the launcher to exit; a 139 from that kill is harmless. Reuse a running emulator only while holding its lock, and never boot shared AVDs with `-wipe-data`.

Emulator quirks: `FLAG_SECURE` screens (some app settings, the system unlock prompt) capture as black, and the notification-permission prompt returns after a reinstall.

### Minimum supported Android

Check the module's effective `minSdk`, including variant overrides, and test on an image with that API level. If it is not installed, report the coverage gap rather than substituting another level. Verify `ro.build.version.sdk` and `ro.build.version.release` first, and report the OS and WebView versions you tested.

The factory API 26 image ships WebView 69. `android_api26` has Chrome 119.0.6045.193 as its WebView provider instead, which survives restarts but not `-wipe-data`. Fresh API 26 clones need it before renderer tests:

```bash
adb -s SERIAL install -r '/home/nico/.codex/skills/android-lab/assets/com.android.chrome_119.0.6045.193-604519327_minAPI24_maxAPI28(x86,x86_64)(nodpi)_apkmirror.com.apk'
adb -s SERIAL shell dumpsys webviewupdate
```

Do not count native-only tests as renderer coverage, or add app compatibility code merely for the factory WebView.

### Clones when devices are busy

When every suitable emulator is locked, create a temporary clone: a fresh AVD from the same system image and hardware profile. Never copy a running AVD's data or touch the occupied source.

1. Pick a unique name such as `android_api35_<task>` and lock it before creating it. Check disk space and memory.
2. Create it with the emulator SDK's `cmdline-tools/latest/bin/avdmanager create avd --name "$AVD_NAME" --package 'system-images;android-35;google_apis;x86_64' --device pixel`, with `ANDROID_AVD_HOME` set. Answer `no` to the custom hardware prompt, and never use `--force`. Set `hw.gpu.enabled = yes` and `hw.gpu.mode = swangle` in its `config.ini`.
3. Lock a free even console port from 5560–5682 with `port-PORT`, check that it and the next port are unused, and start the clone with the launcher. Verify `adb -s emulator-PORT emu avd name` and the API level before installing.
4. When finished, stop it, wait for the launcher to exit, run `avdmanager delete avd --name "$AVD_NAME"`, then release both locks.

## WebView inspection

For a debuggable WebView build on any device you hold:

```bash
pid=$(adb -s SERIAL shell pidof "$APP_ID")
port=$(adb -s SERIAL forward tcp:0 "localabstract:webview_devtools_remote_$pid")
```

`tcp:0` picks a free local port and prints it, so you never take over another agent's forward. If the socket is missing, look for `webview_devtools_remote` in `adb shell cat /proc/net/unix`. Discover pages at `http://127.0.0.1:$port/json` and select the app's page by URL; the first page may be a background WebView. Playwright attaches with `chromium.connectOverCDP(url, { noDefaults: true })`; without `noDefaults` it fails with "Browser context management is not supported". Raw CDP over the page's `webSocketDebuggerUrl` also works. Recreate the forward when the app restarts, and remove only yours with `adb -s SERIAL forward --remove tcp:$port`.
