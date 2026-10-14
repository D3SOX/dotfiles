# Desktop testing

## Browser console

In T3 Code, use its collaborative `preview_*` tools: inspect `preview_status`, then `preview_open` at `http://127.0.0.1:8007` if needed. Follow the active harness's browser ownership and fallback rules. Outside T3, use the available browser-control workflow. The console is noVNC; Windows controls are drawn on a canvas and usually have no browser accessibility locators. Inspect a screenshot before using coordinates.

The page can be connected while Windows is still booting or signing in. A black desktop is not proof of an application crash. Inspect again after boot. Ctrl+Alt+Delete reached the Windows security screen during prior use; Escape or Cancel returns to the desktop. Do not select Sign out, Lock, or Task Manager as routine readiness steps.

This noVNC build exposes `UI.rfb` through `/app/ui.js`. When browser evaluation is available, these calls send guest keys directly:

```js
const { default: UI } = await import('/app/ui.js')
UI.rfb.sendCtrlAltDel()
```

To open Run, focus the guest canvas first, then evaluate:

```js
const { default: UI } = await import('/app/ui.js')
UI.rfb.sendKey(0xffeb, 'MetaLeft', true)
UI.rfb.sendKey(0x72, 'KeyR', true)
UI.rfb.sendKey(0x72, 'KeyR', false)
UI.rfb.sendKey(0xffeb, 'MetaLeft', false)
```

Inspect the screenshot to confirm Run is open before typing. A previous Run command is normally selected, but verify rather than appending to it. For an ASCII command without credentials:

```js
const { default: UI } = await import('/app/ui.js')
const command = String.raw`powershell.exe -NoProfile -ExecutionPolicy Bypass -File \\host.lan\Data\windows-lab\APP-TASK\run.ps1`
for (const character of command) UI.rfb.sendKey(character.charCodeAt(0))
UI.rfb.sendKey(0xff0d)
```

Check the actual desktop result and the script's log. These module/key calls describe the currently verified noVNC build; if its interface changes, inspect the page and use normal browser interactions instead of assuming private properties remain stable. Save evidence with the harness's screenshot/recording tools when available.

## Interactive processes

Check `query user` for the active guest session. A GUI started over SSH may be invisible or use a different session. For desktop behavior, launch a PowerShell script through Run or use a temporary scheduled task with an interactive principal. For example, execute this through SSH after placing `run.ps1` in the share:

```powershell
$taskName = 'WindowsLab-APP-TASK'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File \\host.lan\Data\windows-lab\APP-TASK\run.ps1'
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings | Out-Null
Start-ScheduledTask -TaskName $taskName
Get-ScheduledTaskInfo -TaskName $taskName
```

Use the configured guest user and the required privilege level. Add `-RunLevel Highest` only when the workflow requires elevation and the account supports it. Choose a unique task name; do not overwrite another task. Registration/start acceptance does not prove execution: inspect task state/result and your script's progress log. A task launch was refused during a previous boot; launching through Run worked after the desktop was ready. Check readiness and task conditions before retrying. Remove your task with `Unregister-ScheduledTask -TaskName $taskName -Confirm:$false` after testing.

Have long-running scripts write progress and final verdicts to the share. Poll that file from the host without keeping a short SSH request blocked for the entire test. Preserve enough error output to distinguish a harness problem from the target app's failure.

## Startup and shutdown checks

Use an isolated profile supported by the target app, and verify that the executable actually uses it. Match the report's launch method and close action. `CloseMainWindow()` requests a native close; killing a process does not exercise normal window-close handling. With a logging console, `MainWindowHandle` can identify the console instead of the app. Where necessary, enumerate visible top-level windows with `EnumWindows`, check their PID/class/title, and send `WM_CLOSE` (`0x0010`) with `PostMessage` to the actual application window. Electron windows in this lab used class `Chrome_WidgetWin_1`; do not assume that class for other frameworks.

Wait for a usable app window, not merely a live PID. A fixed short sleep can fail during a cold VM start. After relaunch, inspect the window and the relevant process tree: single-instance apps can exit the newly launched process with code 0 while using an existing process, or schedule a third replacement process. Verify the lasting usable window rather than insisting that the initial PID survives.

For close/reopen races, distinguish two scenarios:

- Full shutdown: wait for exit before launching again.
- Overlapping shutdown: wait for the app window to disappear, then relaunch while the old process still exists. Record the delay, whether the old process was alive, both exit codes, and whether any usable app window remains.

The first scenario cannot exclude a failure in the second. Check settings such as close-to-tray, background operation, or confirmation dialogs before treating a hidden window as shutdown. Keep unsuccessful reproduction attempts and harness/setup errors separate from target failures.

## Optional Electron inspection

Use an app-supported debugging entrypoint or a temporary loopback `--remote-debugging-port=PORT` when needed. In the guest, `Invoke-RestMethod http://127.0.0.1:PORT/json/list` discovers actual renderer targets. With Playwright/CDP, an empty default browser context does not establish a missing UI; inspect all contexts and target URLs. Node.js at `C:\Program Files\nodejs\node.exe` was available in this VM, but verify dependencies such as Playwright before using them.

Prefer the app's existing Windows test/package workflow. Inspectors can change shutdown timing; disconnect them and repeat the reported flow without debugging flags before drawing a conclusion about an intermittent failure.
