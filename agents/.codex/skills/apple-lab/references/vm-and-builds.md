# VM, builds and simulators

## Access

| Item | Local setup |
|---|---|
| Docker container | `macos` |
| Guest console | `http://127.0.0.1:8006` on the agent host |
| SSH | `builder@127.0.0.1`, port `2223`, through the control socket `/tmp/apple-lab-ssh` |
| Guest | Intel, macOS 15.7.9, Xcode 26.2 (checked 2026-11-23) |
| JavaScript tool PATH | `export PATH="$HOME/.local/bin:$PATH"` in the guest |

While holding the `vm` lock, connect with:

```sh
/home/nico/.codex/skills/apple-lab/scripts/vm-connect.sh
```

It starts the container if needed, waits for the guest's SSH login, opens the control socket and prints `VM_CONNECTED`. The socket dies with the VM, so run the script again after any restart. To restart the guest, stop and start the container; `shutdown -r` inside the guest hangs. Then run guest commands with `ssh -S /tmp/apple-lab-ssh -p2223 builder@127.0.0.1 '...'`, and recheck versions when they matter:

```sh
ssh -S /tmp/apple-lab-ssh -p2223 builder@127.0.0.1 'sw_vers; xcodebuild -version; xcrun simctl list devices available; df -h /Users/builder'
```

The guest logs `builder` in automatically and never sleeps or locks its screen. If the console shows a login or lock screen anyway, log in there before GUI or media tests; media clocks stall on a locked desktop or with audio disabled. Keep the VM password out of command lines, logs and GitHub.

For builds or tests longer than a few minutes, start them in the guest with `nohup COMMAND > LOG 2>&1 &` and poll the log, so a host session restart doesn't kill them. After a restart, check the guest's processes before rerunning anything.

## Source synchronization

Create a task directory such as `/Users/builder/apple-lab-<app>-<task>`. Copy the selected host worktree's tracked files, including intended uncommitted edits, rather than relying on an old guest copy. A tracked-file list avoids copying host `node_modules`, credentials and `.git`:

```sh
git ls-files -z > "$TMPDIR/apple-lab-tracked-files"
rsync -a --from0 --files-from="$TMPDIR/apple-lab-tracked-files" \
  -e 'ssh -S /tmp/apple-lab-ssh -p2223' \
  ./ builder@127.0.0.1:/Users/builder/apple-lab-APP-TASK/
```

Add intended untracked source files explicitly. The command doesn't delete files, so remove obsolete ones yourself when reusing a directory. To save time, you may seed a new task directory from another task's prepared one with an APFS clone (`cp -c -R`), but always rerun the project's dependency install afterward; cloned dependencies are often stale. Never copy Linux `node_modules` or native binaries into the guest. The guest has no `gh`, and Homebrew no longer ships bottles for Intel macOS, so prefer tools that are already installed.

Follow the target repository's build preparation and CI workflow. For Capacitor apps, discover the web build output, iOS sync command and native preparation scripts in the current source, and build and sync after renderer changes. If the web build produces platform-independent assets, you may run it on the host and copy only its output to the guest before the iOS sync.

Before using the Xcode examples below, set `XCODE_PROJECT`, `XCODE_SCHEME`, `TEST_SELECTOR` and `APP_PRODUCT` from the target project. `TEST_SELECTOR` is a `target/class/method` identifier; `APP_PRODUCT` includes `.app`. For a workspace, replace `-project "$XCODE_PROJECT"` with `-workspace "$XCODE_WORKSPACE"`.

## Disk space and cleanup

The guest disk is usually over 90% full. Before stopping the VM, delete your own task directory, DerivedData, result bundles, logs and superseded archives once evidence and needed IPAs are on the host. You may also delete `/Users/builder/apple-lab-*` entries and archives older than 7 days that no running process uses (check with `lsof +D DIR` or the process list). Never delete simulators, runtimes or anything newer.

## Simulator tests

Use the shared `Lab …` simulators (iPhone SE, iPhone 16 Pro and iPad Air on iOS 18.6 and 26.3) unless the task needs another device; `xcrun simctl list devices available` lists them. Boot one if needed and wait with `xcrun simctl bootstatus UUID -b`. Use a task-specific DerivedData path so builds don't collide and cleanup is one directory, and a unique result bundle path, since xcodebuild refuses an existing one:

```sh
xcodebuild -project "$XCODE_PROJECT" -scheme "$XCODE_SCHEME" \
  -destination 'platform=iOS Simulator,id=UUID' \
  -derivedDataPath /Users/builder/apple-lab-APP-TASK-dd \
  -resultBundlePath /Users/builder/apple-lab-APP-TASK-RUN.xcresult \
  -only-testing:"$TEST_SELECTOR" \
  CODE_SIGN_IDENTITY=- test
```

Keep complete logs and count the tests actually executed: a misspelled `-only-testing` selector runs zero tests. Native-only tests do not establish renderer or audible background coverage. Take simulator screenshots with `xcrun simctl io UUID screenshot FILE.png`. To inspect a simulator WebView, use Safari Web Inspector on the guest console, or a temporary XCTest probe that evaluates JavaScript, kept only in the guest copy. If video stalls within its first second while data is buffered, compare on another simulator before blaming the app; one iOS 18.6 iPhone simulator did this after earlier background runs, and rebooting it didn't help.

The iOS 26 simulator's WebKit crashes on WASM in this Intel VM, and WebGL contexts can fail; neither establishes a physical-device failure. Use the iOS 18.6 runtime for real playback and UI tests. Check the target's effective `IPHONEOS_DEPLOYMENT_TARGET`, including generated configuration and preparation scripts, and choose a matching runtime for minimum-OS coverage; newer runtimes don't establish it. No iOS 17 runtime is installed.

## Inspectable IPA

There is no Apple signing setup in the VM. Build unsigned, then let the user sign and install with iloader on nico-laptop.

For an inspectable Capacitor build, set `ios.webContentsDebuggingEnabled=true` in the generated app `capacitor.config.json` after the **last** sync, since sync overwrites it. For another WKWebView app, use its supported inspection setting. Keep inspection overrides local and verify them inside the final archive, not just in the source config.

```sh
xcodebuild -project "$XCODE_PROJECT" -scheme "$XCODE_SCHEME" \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /Users/builder/apple-lab-APP-TASK-BUILD.xcarchive \
  CURRENT_PROJECT_VERSION=BUILD CODE_SIGNING_ALLOWED=NO archive
mkdir -p /Users/builder/apple-lab-APP-TASK-BUILD-package/Payload
ditto /Users/builder/apple-lab-APP-TASK-BUILD.xcarchive/Products/Applications/"$APP_PRODUCT" \
  /Users/builder/apple-lab-APP-TASK-BUILD-package/Payload/"$APP_PRODUCT"
cd /Users/builder/apple-lab-APP-TASK-BUILD-package
ditto -c -k --keepParent Payload /Users/builder/apple-lab-APP-TASK-BUILD-inspectable.ipa
```

Choose a new build number after checking recent packages. Validate the archived app's `Info.plist` identity, version and minimum OS, any inspection config and the frameworks and resources the project needs. Transfer guest → host → `nico-laptop:Downloads/apple-lab/` and compare SHA-256 checksums before handing it to the user.
