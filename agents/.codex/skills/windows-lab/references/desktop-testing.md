# Desktop testing

## Browser console

In T3 Code, use its `preview_*` tools: check `preview_status`, then `preview_open` the console URL from SKILL.md if needed. Outside T3, use the available browser-control workflow. The console is noVNC: Windows draws its controls on a canvas without accessibility locators, so take a screenshot before clicking coordinates. Type text by focusing `#noVNC_keyboardinput` and typing into it, for example with `preview_act`.

The page can connect while Windows is still booting or signing in, so a black desktop is not proof of a crash; look again after boot. Do not select Sign out, Lock or Task Manager as readiness steps.

To open Run, focus the guest canvas and send Win+R through the page's noVNC client:

```js
const { default: UI } = await import('/app/ui.js')
UI.rfb.sendKey(0xffeb, 'MetaLeft', true)
UI.rfb.sendKey(0x72, 'KeyR', true)
UI.rfb.sendKey(0x72, 'KeyR', false)
UI.rfb.sendKey(0xffeb, 'MetaLeft', false)
```

Check a screenshot that Run opened and that its field holds only your command. If the noVNC interface changed, inspect the page instead of assuming these private properties.

When the host is loaded, noVNC can drop its connection and miss right-clicks. Take screenshots inside the guest instead, from the interactive session (see below), with a script like this:

```powershell
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
[System.Drawing.Graphics]::FromImage($bitmap).CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$bitmap.Save('\\host.lan\Data\windows-lab\APP-TASK\screen.png')
```

## Interactive processes

A GUI started over SSH may be invisible or run in another session, and processes started over SSH ignore Ctrl+C and have no interactive console. Test desktop, console and signal behavior from the interactive session. Check `query user` for it (it exits 1 even on success), then launch a PowerShell script through Run or a temporary scheduled task with an interactive principal:

```powershell
$taskName = 'WindowsLab-APP-TASK'
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File \\host.lan\Data\windows-lab\APP-TASK\run.ps1'
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings | Out-Null
Start-ScheduledTask -TaskName $taskName
Get-ScheduledTaskInfo -TaskName $taskName
```

Add `-RunLevel Highest` only when the workflow needs elevation. Use a unique task name. Registration and start do not prove execution: check the task result and your script's progress log. Early in a boot, task launches have been refused while Run worked. The first scheduled-task command after boot can take over a minute while PowerShell prepares its modules. Remove your task with `Unregister-ScheduledTask -TaskName $taskName -Confirm:$false` afterward.

Have long-running scripts write progress and final verdicts to the share, and poll that file from the host instead of keeping an SSH request open for the whole test.

## Startup and shutdown checks

Use an isolated profile the app supports, and verify the executable actually uses it. Match the reported launch method and close action: killing a process does not exercise normal window-close handling. To close like a user, send `WM_CLOSE` to the app's actual top-level window (found by PID with `EnumWindows`), not to a logging console.

Wait for a usable app window, not just a live PID. Single-instance apps can exit a new process with code 0 while an existing one takes over, or start a replacement, so verify the lasting window. For close/reopen races, a full shutdown (wait for exit, then relaunch) cannot exclude a failure when relaunching while the old process still exits. Check close-to-tray, background and confirmation settings before treating a hidden window as shutdown. Keep failed reproduction attempts and harness errors separate from target failures.

## Electron inspection

Use an app-supported debugging entrypoint or a temporary `--remote-debugging-port=PORT`, then run `vm-ssh.py --forward PORT` as a background command and connect from the host to `http://127.0.0.1:PORT/json/list`. With Playwright, an empty default browser context does not mean the UI is missing; check all contexts and target URLs. Inspectors change shutdown timing, so disconnect them and repeat the reported flow without debugging flags before concluding anything about an intermittent failure.
