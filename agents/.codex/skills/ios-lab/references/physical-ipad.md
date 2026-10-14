# Physical iPad through nico-laptop

## Access and installation

The iPad is connected by USB to **`ssh nico-laptop`**, not to the agent host or macOS VM. Acquire the local and laptop iPad locks described in SKILL.md before device work. Read [../local.md](../local.md) and substitute its `IPAD_UDID` in the commands below. Check presence and identity with the laptop's existing pymobiledevice3 installation:

```sh
ssh nico-laptop 'uv tool run --from pymobiledevice3 pymobiledevice3 usbmux list --usb --simple'
ssh nico-laptop 'uv tool run --from pymobiledevice3 pymobiledevice3 lockdown info --udid IPAD_UDID'
```

The second command returns personal identifiers; select only the needed model, ProductVersion and BuildVersion for reporting. Do not publish the complete response. Use `--help` when CLI versions differ.

Last verified 2026-09-28:

- Model: **iPad12,1**, OS: **iPadOS 26.7 (23H24)**. A previous user estimate of “27” was inaccurate; confirm actual values.
- Signing can change the bundle ID suffix; discover the target app's installed identity rather than assuming its production bundle ID.
- Developer Mode, signing-identity trust and Safari Web Inspector were enabled. Recheck only if relevant to an access failure.
- Bluetooth headphones, a phone hotspot and another screen for QR codes were available. AirPlay and an external keyboard/trackpad were not; availability can change.

`iloader-bin` from AUR has successfully signed and installed the IPAs. Put packages in `~/Downloads` on the laptop; the user performs signing/installing. SideStore documentation is not evidence that SideStore was physically tested.

Ask the user to install over the existing app using the same Apple account/settings, **without uninstalling**. Preserve app data and user downloads. Do not assume a free signing slot exists for a separate probe app. Replacing the normal app with a diagnostic probe needs explicit authorization and a prepared restore package.

After opening, verify the installed app's identity and build. For a Capacitor app with the App plugin, `await Capacitor.Plugins.App.getInfo()` through the inspector can do this; otherwise use the app's own build display or native installed-app metadata. A successful transfer or user starting the installer does not establish which build is running.

## Web Inspector / CDP

For WebView inspection, the iPad must be unlocked and the target app in the foreground. The locked WebView has repeatedly been unavailable. For media background failures, ask the user to unlock/reopen **without Play/Pause or changing media**, and ask whether sound returns from reopening alone.

Check port 9331 on both hosts before using it; choose another free port when needed. Start an owned inspector in a separate foreground exec session, keeping the service bound to loopback:

```sh
ssh -tt nico-laptop \
  'uv tool run --from pymobiledevice3 pymobiledevice3 webinspector cdp --udid IPAD_UDID --host 127.0.0.1 --port 9331'
```

In another session, forward it:

```sh
ssh -N -o ExitOnForwardFailure=yes \
  -L 127.0.0.1:9331:127.0.0.1:9331 nico-laptop
```

The discovery endpoint is `http://127.0.0.1:9331/json/list`. Keep only one evaluator attached at a time. The bridge can stall after repeated connections: preserve the failure, disconnect and restart **only your own** inspector/tunnel before assuming the device needs human intervention. If the WebView is still missing, verify the final installed inspection configuration and foreground/unlocked state.

Use the bundled Node 24+ evaluator, with a JS expression or async IIFE in a temporary file:

```sh
node ~/.codex/skills/ios-lab/scripts/evaluate-webview.mjs /tmp/ios-probe.js
```

Optional flags: `--endpoint http://127.0.0.1:PORT`, `--target TARGET_ID`, `--user-gesture`. The helper auto-selects only when exactly one localhost WebView exists. For another app origin or multiple targets, select the app's target explicitly with `--target`. The helper polls async results because this CDP bridge does not reliably support `awaitPromise`; it exits nonzero on JavaScript errors and timeouts. It does not acquire locks or open the app.

A framework-independent media probe, when playback is relevant:

```js
(() => ({
  visibility: document.visibilityState,
  media: [...document.querySelectorAll('video, audio')].map(element => ({
    time: element.currentTime, paused: element.paused,
    readyState: element.readyState, ended: element.ended
  }))
}))()
```

Discover app-specific stores, routers and native APIs from the current source before probing them. Do not assume Vue, Capacitor plugins or media selectors. Folder bookmarks, file paths and downloaded content can be personal: avoid printing full records, and redirect binary/base64 content to private files.

Record original settings and app state, including route, active tab and playback when applicable, before diagnostic mutations. Wait for framework updates and CSS transitions before measuring computed styles. Temporary CSS results are previews; repeat against a compiled package before marking the shipped fix verified.

## Native logs

For app-specific traces, use the laptop's syslog bridge in an owned foreground session, with the current process name or PID:

```sh
ssh nico-laptop 'uv tool run --from pymobiledevice3 pymobiledevice3 syslog live --udid IPAD_UDID --process-name APP_PROCESS' > /tmp/ios-lab-TASK-native.log
```

Confirm the installed app's process name before relying on the filter. A WebContent or system PiP failure may require a separate narrowly scoped capture. Check current `--help` for filtering options and do not publish unrelated device logs. This capture can remain running after disconnecting Web Inspector for a lifecycle test; stop only your capture afterward.

## Background, audio and lifecycle tests

Apply media-specific checks only when relevant to the target app and requested behavior.

Disconnect **both the CDP client and inspector service/tunnel** before timing background, PiP, screen-lock or audio-interruption behavior. Inspector attachment can change suspension behavior. Confirm the initial clip is audible before asking the user to lock; inspectable “playing” state is insufficient.

- **Queue:** use a short first clip and a known second clip. State whether the first was audible, how long to wait and whether the device should remain locked for the report. Preserve failing traces before resetting the queue.
- **PiP:** distinguish manual entry, automatic Home entry and return-to-app. Check audible picture continuity and full-width/normal-scale return. Verify the user's automatic PiP and rotation settings instead of changing them silently.
- **Clock interruption:** use an audible timer, not “Stop Playing.” Record whether recovery is automatic, requires one lock-screen Play, requires Pause→Play, or needs unlocking. These are different outcomes.
- **Audio routes:** record original output; distinguish expected pause on Bluetooth disconnection from failed reconnection. The user's listening result establishes the audible route.
- **Auto-Lock:** the observed iPad offered 2 minutes, not 1; the user's original setting was Never. Read the current setting and restore it after testing.
- **Local network:** check iPad and laptop are on the same Wi-Fi and the app has Local Network permission. USB connectivity alone does not provide Wi-Fi reachability.

For unattended work, avoid lock/passcode, permission revocation, network changes and disruptive native prompts that require the absent user. Resume simulator or source work instead. Physical iPhone, minimum-OS and unavailable accessory coverage remain separate.

## Finish

Remove temporary hooks, styles and panels; restore the captured settings and screen; retain existing files. Stop only your inspector and SSH tunnel, then release both iPad locks. Save narrowly scoped traces outside Git, redacting tokens, folder bookmarks, signing details and unrelated personal content before any publication.
