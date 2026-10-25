# macOS apps in the VM

The guest is an **Intel (x86_64)** macOS VM (see the table in [vm-and-builds.md](vm-and-builds.md)). Use it for macOS builds, CLI tools, desktop apps and packaging checks. Its results do not establish Apple Silicon behavior, other macOS versions or GPU/Metal performance. arm64-only binaries cannot run there. Check `sw_vers`, `uname -m` and `lipo -archs BINARY` before testing.

## Builds and artifacts

Sync sources into an isolated task directory as described in the VM reference. For native Xcode projects there is no Apple developer identity in the VM, so sign ad hoc:

```sh
xcodebuild -project "$XCODE_PROJECT" -scheme "$XCODE_SCHEME" \
  -destination 'platform=macOS' \
  -derivedDataPath /Users/builder/apple-lab-APP-TASK-dd \
  CODE_SIGN_IDENTITY=- build   # or: test
```

For other stacks (Electron, Tauri, Flutter, SwiftPM, Go, Rust, …) follow the project's documented macOS build or CI workflow. Check which toolchains the guest already has before installing anything. Do not copy Linux `node_modules` or native binaries into the guest.

To test an existing artifact (CI `.dmg`, `.zip`, `.pkg` or `.app`), copy it into the task directory over the SSH control socket and record its source and checksum. Files copied with `scp`/`rsync` are not quarantined, so they skip the Gatekeeper first-launch path a downloaded file would hit. Signing, notarization and Gatekeeper behavior need a quarantined copy (`xattr -w com.apple.quarantine ...`) or a real download, and an unsigned build cannot verify them. Inspect signatures with `codesign -dv --verbose=4 APP` and `spctl -a -vv APP`.

## Launching and observing

The app must show up on the guest's logged-in desktop, which you can watch at the console URL. Run commands from the SSH session as `builder`, the same user who is logged in. Check the console to confirm the window actually appeared.

- Launch: `open -n APP --args ...` for normal LaunchServices behavior. Run `APP/Contents/MacOS/NAME` directly to capture stdout/stderr. Record the PID you started.
- Logs: run `log stream --style compact --predicate 'process == "NAME"'` in a session you own, or `log show --last 10m --predicate ...` afterward. Crash reports are in `~/Library/Logs/DiagnosticReports/`.
- Screenshots: `screencapture -x FILE.png` over SSH may need Screen Recording permission and can capture only the wallpaper. If it does, take the screenshot from the console instead.
- Interaction: use the console for clicks and typing. `osascript`/System Events automation needs Accessibility permission. Record any TCC permission you grant and revoke it afterward unless it was already granted.
- Web content: start Electron/Chromium apps with `--remote-debugging-port=PORT` bound to the guest's loopback, forward the port with `ssh -S /tmp/apple-lab-ssh -p2223 -N -L 127.0.0.1:PORT:127.0.0.1:PORT builder@127.0.0.1`, then use `scripts/evaluate-webview.mjs` with `--endpoint` and `--target`. For WKWebView, make the view inspectable (`isInspectable`) and use Safari Web Inspector in the guest.

Distinguish a window that never appears, a normal exit, a hand-off to an existing instance and a crash. Exit status alone is not enough.

## Cleanup

Quit only the processes you started, by PID. Remove app data, preferences, containers and login items that your task created (`~/Library/Application Support/ID`, `~/Library/Preferences/ID.plist`, `~/Library/Containers/ID`), and keep existing data. Uninstall test `.pkg` installs only if you installed them and know their payload. Then follow the VM shutdown and lock release steps in SKILL.md.
