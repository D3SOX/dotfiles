---
name: android-lab
description: Build and test Android apps on this machine's physical Pixel and Android emulators. Use for APK installation, ADB inspection, device lifecycle checks, or API-version coverage.
---

# Android lab

Use this local setup for Android builds and device testing. Read the target repository's instructions and discover its Android module, build variant, application ID, launch activity, instrumentation package and minimum SDK before choosing commands. Use pnpm if the project already uses it; otherwise use bun for JavaScript commands. Native projects may not need either.

Before physical-device access, read [local.md](local.md) for private connection values and substitute its named placeholders in the commands below. This file is Git-ignored; preserve it when copying skill updates. If it is missing, obtain the relevant values from the user or existing device configuration before connecting.

## Device ownership

The Pixel and each emulator are exclusive shared resources. Before `adb connect`, starting an emulator, or issuing any target-specific `adb` command, acquire the matching lock:

```text
Pixel 8 Pro:       /tmp/opentubex-android-pixel.lock
opentubex_api35:   /tmp/opentubex-android-api35.lock
opentubex_api26:   /tmp/opentubex-android-api26.lock
```

The existing lock filenames and AVD names are historical lab resource identifiers; keep them unchanged so all projects coordinate access to the same devices.

Start a long-running lock holder in its own exec session, using the exact file for the target. For example, for the Pixel:

```bash
flock -n -E 75 /tmp/opentubex-android-pixel.lock \
  bash -c 'echo DEVICE_LOCK_ACQUIRED; trap "exit 0" INT TERM; while sleep 60; do :; done'
```

Continue only after `DEVICE_LOCK_ACQUIRED` appears. Keep that exec session running for the entire device workflow. If the command exits with status 75, another agent is using the target. Do not connect to it, run commands against it, stop it, wipe it, or steal its lock. Choose an unlocked suitable device. If none is free and the task needs another emulator, create an isolated clone using the procedure below. Otherwise wait and coordinate with the other agent.

Release the lock by sending Ctrl-C to the lock-holder session after all device work and setting restoration is complete. The lock also releases if that session exits. Never delete the lock files, since replacing a locked file would bypass mutual exclusion.

## Physical Pixel

The physical device is a Pixel 8 Pro running Android 16. It can connect directly over Tailscale or by USB through `ssh nico-laptop`. When wireless ADB is unavailable or APK transfers are slow, use the [laptop USB workflow](references/pixel-laptop-usb.md) if the Pixel is plugged into the laptop. That workflow requires locks on both hosts.

The Pixel is rooted. Agents may use root-dependent tools and commands when they help with the assigned task, including privileged inspection, debugging, and testing. Verify the available root access on the device before relying on it; the device locks and setting-restoration rules still apply.

For direct access, use `PIXEL_ADB_ADDRESS` from `local.md`. Port `5555` works only when TCP ADB is enabled; Wireless debugging uses a changing port, so use the current address supplied by the user. The phone may be unavailable when it or Tailscale is offline.

Connect and confirm the Android user before every install:

```bash
adb connect PIXEL_ADB_ADDRESS
adb -s PIXEL_ADB_ADDRESS shell am get-current-user
```

Install test apps only for Android user 0. Never install them for users 10 or 11.

```bash
adb -s PIXEL_ADB_ADDRESS install --user 0 -r PATH_TO_APK
```

Set `APP_ID` and `LAUNCH_COMPONENT` from the selected APK/build variant, not from the repository name. `LAUNCH_COMPONENT` is the full `package/activity` component. Launch it for user 0 with:

```bash
adb -s PIXEL_ADB_ADDRESS shell am start --user 0 \
  -n "$LAUNCH_COMPONENT"
```

The phone has personal notifications. Collapse the shade before ordinary screenshots. When notification evidence is necessary, crop it narrowly and never expose unrelated notifications. Prefer inspecting the app's notifications without opening the full shade:

```bash
adb -s PIXEL_ADB_ADDRESS shell \
  cmd notification list | rg -F -- "$APP_ID"
```

Record the original value of any device setting changed for a test, then restore it. Do not treat force-stop as a supported durability test for background work because Android intentionally prevents restart until the user opens the app again.

## Build environment

The available Android toolchain is:

```text
ANDROID_HOME=/home/nico/Android/Sdk
JAVA_HOME=/usr/lib/jvm/java-21-openjdk
```

Use the repository's documented build and test workflow. For Capacitor apps, build the web assets and sync Android when renderer code changed; discover the scripts and web directory in the current project rather than assuming a `capacitor:sync:android` script exists. Skip this step for native apps.

Run Gradle from the directory containing the project's wrapper. For a project with the standard debug variant, for example:

```bash
ANDROID_HOME=/home/nico/Android/Sdk \
JAVA_HOME=/usr/lib/jvm/java-21-openjdk \
./gradlew assembleDebug testDebugUnitTest
```

## Android emulators

The emulator installation and AVD data live on the large local data partition:

```text
Partition: /run/media/nico/200GB_DATA
SDK:       /run/media/nico/200GB_DATA/android-emulator-sdk
AVD home:  /run/media/nico/200GB_DATA/android-emulator-avds
```

The shared baseline AVDs are `opentubex_api35` and `opentubex_api26`. When running on their configured ports, their ADB serials are `emulator-5556` and `emulator-5558` respectively.

Use `swangle` for graphics on this machine. Emulator 37.1.11 repeatedly segfaulted in `RenderThread` with both `swiftshader` and `swiftshader_indirect`, including with Vulkan disabled. A repeated app-launch test failed on launch four with `swiftshader_indirect`; `swangle` passed 20 launches on each of the three lab AVDs and local-video playback/seeking on API 26. `swangle` uses ANGLE over SwiftShader Vulkan instead of the older SwiftShader GLES renderer. Do not substitute `swiftshader` as a fallback for these crashes.

The lab AVD defaults are `hw.gpu.enabled = yes` and `hw.gpu.mode = swangle` in each AVD's `config.ini`. Preserve these settings, and set them for new AVDs while stopped and locked. These settings alone are insufficient in emulator 37.1.11: the launcher chooses its graphics library path from the command-line `-gpu` argument before reading the AVD configuration. Without explicit `-gpu swangle`, it can still load the older GLES renderer. Use the launcher below, or retain explicit `-gpu swangle` in a custom launch command. Confirm the startup log's `Graphics Adapter` contains `ANGLE`, not just `Google SwiftShader`.

The additional `opentubex_c96f_tablet` AVD uses API 35. Its lock is `/tmp/opentubex-android-opentubex_c96f_tablet.lock`; choose and lock a free port from the clone range below before starting it.

List the AVDs with:

```bash
ANDROID_SDK_ROOT=/run/media/nico/200GB_DATA/android-emulator-sdk \
ANDROID_AVD_HOME=/run/media/nico/200GB_DATA/android-emulator-avds \
/run/media/nico/200GB_DATA/android-emulator-sdk/emulator/emulator -list-avds
```

After acquiring the target's lock, check `adb devices -l`. Reuse a running emulator only while holding its matching lock. For a headless API 35 instance:

```bash
/home/nico/.codex/skills/android-lab/scripts/start-emulator.sh \
  opentubex_api35 5556
```

The launcher runs in the foreground and does not acquire locks; keep the matching lock holder alive for the entire workflow.

Use `opentubex_api26` and port `5558` for Android 8.0, API 26, when that version is supported by the target app. Boot without `-wipe-data` to preserve installed apps and the updated WebView. Use `-wipe-data` only when a factory reset is intended, then reinstall the WebView update below before renderer tests.

### Minimum supported Android tests

Check the target module's Gradle configuration for its effective `minSdk`/`minSdkVersion`, including variant overrides. Choose an emulator matching that minimum; the existing API 26 AVD provides minimum-version coverage only for apps whose minimum is 26. If the needed system image is not installed, report the coverage gap rather than substituting another API level.

Verify `ro.build.version.sdk` and `ro.build.version.release` before testing; the existing API 26 target should report `26` and `8.0.0`. Use the selected variant's actual application ID, launch component and instrumentation runner. Cover the affected flow, including renderer startup for WebView UI tests and applicable native services, notifications or lifecycle behavior.

For WebView-based apps, the shared API 26 AVD has Chrome 119.0.6045.193 installed as its active WebView provider. Verify it with `adb -s SERIAL shell dumpsys webviewupdate`. The factory system image contains WebView 69, so newly created clones and wiped AVDs need the same update. Install the APK bundled in this skill's `assets/` directory after boot, substituting the owned device's serial:

```bash
adb -s SERIAL install -r '/home/nico/.codex/skills/android-lab/assets/com.android.chrome_119.0.6045.193-604519327_minAPI24_maxAPI28(x86,x86_64)(nodpi)_apkmirror.com.apk'
adb -s SERIAL shell dumpsys webviewupdate
```

For this API 26 baseline, confirm that the current WebView package is `com.android.chrome`, version `119.0.6045.193`, before renderer tests. This update persists across normal restarts but not `-wipe-data`. Fresh clones do not inherit it. Do not count native-only tests as renderer coverage or add app compatibility code merely to accommodate the factory WebView. Use the target project's WebView requirements on other API levels. Report the OS and WebView versions used for tests.

### Extra emulators when devices are busy

Agents may create temporary clones when every suitable emulator is occupied. A clone means a fresh AVD using the same installed system-image package and hardware profile, with its own writable data. Do not copy a running AVD's userdata, snapshots, or lock files, and do not issue ADB commands to the occupied source.

- Choose a unique name such as `android_api26_<task-id>`. Acquire `/tmp/opentubex-android-<AVD_NAME>.lock` with the lock-holder pattern above before creating or starting it. Base AVDs retain the exact lock names in the device table.
- Use `avdmanager create avd` from the emulator SDK with `ANDROID_AVD_HOME` set to the lab's AVD home. For an API 26 Pixel clone, use `--name "$AVD_NAME" --package 'system-images;android-26;google_apis;x86_64' --device pixel`. Answer `no` to the custom hardware prompt. Use the task's required API level; never use `--force` to overwrite an existing AVD. Check disk space and memory first.
- Select an unused even console port from 5560 through 5682. Hold `/tmp/opentubex-android-port-<PORT>.lock` for the whole workflow and check that both the console port and the following ADB port are unused before launching. A lock alone does not prove a port is free. Ports 5556 and 5558 are reserved for the base AVDs.
- Launch headlessly with the flags above, using the clone's name and selected port. Wait for boot, verify the AVD name with `adb -s emulator-PORT emu avd name`, and check its API level before installing. Target every ADB command explicitly.
- When finished, stop only the clone you own, wait for its emulator process to exit, and delete that temporary AVD with `avdmanager delete avd --name "$AVD_NAME"`. Release its device and port locks afterward. Leave other agents' AVDs and the shared system images intact. Never delete lock files.
