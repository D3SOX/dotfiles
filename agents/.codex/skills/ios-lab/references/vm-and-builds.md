# VM, simulators and IPA builds

## Access

Last verified 2026-09-28; enumerate and recheck before relying on versions or IDs.

| Item | Local setup |
|---|---|
| Docker container | `macos` (may be started with `docker start macos`) |
| Guest console | `http://127.0.0.1:8006` on the agent host |
| SSH | `builder@127.0.0.1`, port `2223` |
| Existing SSH control socket | `/tmp/opentubex-ios-ssh` (historical shared infrastructure; reuse across projects) |
| Guest | Intel, macOS 15.7.9, Xcode 26.2 |
| JavaScript tool PATH | `export PATH="$HOME/.local/bin:$PATH"` in the guest |
| Guest checkouts | Existing directories under `/Users/builder` may belong to other tasks and lack `.git`; use an isolated task directory |

```sh
docker inspect --format '{{.State.Status}}' macos
ssh -S /tmp/opentubex-ios-ssh -O check -p2223 builder@127.0.0.1
ssh -S /tmp/opentubex-ios-ssh -p2223 builder@127.0.0.1 'xcodebuild -version; xcrun simctl list devices available; xcrun simctl list runtimes; df -h /Users/builder'
```

Read [../local.md](../local.md) for the VM-only `builder` credentials and authenticate interactively. Keep its VM-only credentials out of GitHub, logs and committed files. Reuse the control socket; if it has expired, establish a new authenticated SSH master interactively with `ssh -M -S /tmp/opentubex-ios-ssh -o ControlPersist=8h -p2223 builder@127.0.0.1`. Do not assume key authentication works or put the password on a command line.

Keep the guest desktop **unlocked and audio enabled** during media tests. Otherwise media clocks can stall. Inspect the console if playback timing is inexplicably frozen.

## Source synchronization

Create a task-specific directory such as `/Users/builder/ios-lab-<app>-<task>`. Copy the selected host worktree's tracked files, including intended uncommitted edits, rather than relying on an old guest snapshot. A tracked-file list avoids copying host node_modules, credentials and `.git`:

```sh
git ls-files -z > /tmp/ios-lab-TASK-tracked-files
rsync -a --from0 --files-from=/tmp/ios-lab-TASK-tracked-files \
  -e 'ssh -S /tmp/opentubex-ios-ssh -p2223' \
  ./ builder@127.0.0.1:/Users/builder/ios-lab-APP-TASK/
```

Add intended new untracked source files explicitly. Reusing a directory requires removing obsolete source files deliberately; this command does not delete them. Install dependencies in the guest with the repository's package-manager workflow when needed. Do not copy Linux native node_modules into macOS.

Follow the target repository's documented build preparation and CI workflow. For Capacitor apps, discover the web-build output, iOS sync command and any native preparation scripts in the current source. Build/sync after renderer changes and preserve required bundled runtimes. Skip web preparation for native projects.

For faster repeated renderer builds, the web build may run on the host if it produces platform-independent assets. Copy only the configured web output to the corresponding guest directory, then run the project's iOS sync and native preparation steps there. Do not assume script names or a `dist/capacitor/` layout.

Before using the Xcode examples below, set `XCODE_PROJECT`, `XCODE_SCHEME`, `TEST_SELECTOR` and `APP_PRODUCT` from the target project. `TEST_SELECTOR` is a valid `target/class/method` identifier; `APP_PRODUCT` includes `.app`. For a workspace-based project, replace `-project "$XCODE_PROJECT"` with `-workspace "$XCODE_WORKSPACE"`.

The VM disk is often almost full. Remove only your superseded generated archives/packages or disposable DerivedData after preserving evidence and required IPAs. Do not delete other agents' checkouts, simulators, runtimes or artifacts.

## Simulator tests

Last known devices, **not guaranteed current**:

| Runtime | Device | UUID |
|---|---|---|
| iOS 18.6, stock | iPad | `27B627D1-85B2-4D0C-A94D-40C2B1E55C5C` |
| iOS 18.6, stock | iPhone | `F8815EFE-522B-49F7-BA96-B2919F51AF63` |
| iOS 26.3 | iPad | `64222562-CBEA-4C2E-9211-E85978286758` |

Choose an available UUID from `simctl`, boot it if needed and wait with `xcrun simctl bootstatus UUID -b`. Use the target project's current test selectors and exclusions; live-network, playback and staged persistence tests may need specific setup.

```sh
xcodebuild -project "$XCODE_PROJECT" -scheme "$XCODE_SCHEME" \
  -destination 'platform=iOS Simulator,id=UUID' \
  -only-testing:"$TEST_SELECTOR" \
  CODE_SIGN_IDENTITY=- test
```

Use a unique `-resultBundlePath` when retaining an explicit `.xcresult`; xcodebuild refuses an existing result path. Preserve complete logs and count the tests actually executed: a misspelled `-only-testing` selector can run zero tests. Native-only tests do not establish renderer or audible background coverage.

Stock iOS 26 Intel VM WebKit has a known WASM sandbox crash. Stock iOS 18.6 has been useful for real playback and UI tests. If required for diagnosis, make a separate **local, untracked** test scheme with `JSC_useWasmIPInt=false` and `__XPC_JSC_useWasmIPInt=false` in its test environment. Never add this workaround to production/CI, and never report its results as stock-engine compatibility. Intel VM WebGL context failures likewise do not establish a physical-device failure.

Check the selected target's effective `IPHONEOS_DEPLOYMENT_TARGET`, including generated configuration and preparation scripts. Choose a matching runtime for minimum-OS coverage; newer-runtime results do not establish it.

## Inspectable IPA

There is no established Apple signing setup in this VM. Build unsigned, then let the user sign/install with iloader on nico-laptop.

For an inspectable Capacitor build, after the **last** sync set `ios.webContentsDebuggingEnabled=true` in the guest's generated app `capacitor.config.json`; locate it from the current project. Sync can overwrite it. For another WKWebView app, use its supported inspection configuration. Native apps without a WebView do not need this step. Keep inspection overrides local and verify them inside the final archive, not merely in the source config.

```sh
xcodebuild -project "$XCODE_PROJECT" -scheme "$XCODE_SCHEME" \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath /Users/builder/ios-lab-APP-TASK-BUILD.xcarchive \
  CURRENT_PROJECT_VERSION=BUILD CODE_SIGNING_ALLOWED=NO archive
mkdir -p /Users/builder/ios-lab-APP-TASK-BUILD-package/Payload
ditto /Users/builder/ios-lab-APP-TASK-BUILD.xcarchive/Products/Applications/"$APP_PRODUCT" \
  /Users/builder/ios-lab-APP-TASK-BUILD-package/Payload/"$APP_PRODUCT"
cd /Users/builder/ios-lab-APP-TASK-BUILD-package
ditto -c -k --keepParent Payload /Users/builder/ios-lab-APP-TASK-BUILD-inspectable.ipa
```

Choose a new build number after checking recent packages; do not reuse the dated examples. Validate the archived app's `Info.plist` identity/version/minimum OS, any inspection config and the frameworks/resources required by the target project. Transfer guest → host → `nico-laptop:Downloads/`; compare SHA-256 checksums before handing it to the user.
