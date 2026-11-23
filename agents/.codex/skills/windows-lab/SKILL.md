---
name: windows-lab
description: Test and debug Windows desktop apps in this machine's local Windows Docker VM. Use for Windows executables, installers, native desktop interactions, startup/shutdown checks, or Windows-specific failures.
---

# Windows lab

Read the target repository's instructions and identify the intended source and build before testing. Discover its Windows packaging, executable, data directory and test workflow rather than assuming a framework or layout. Use task-specific guest directories and test profiles; existing guest files may belong to another task.

## Local setup

| Resource | Local value |
|---|---|
| Docker image / container | `dockurr/windows` / `windows` |
| Compose configuration | `/run/media/nico/200GB_DATA/windows-vm/compose.yml` |
| Guest | Windows 11 Pro; account from Compose `USERNAME` |
| Configured resources | 8 GB RAM, 18 vCPUs, 150 GB guest disk |
| Browser console | `http://127.0.0.1:8007/?autoconnect=1&resize=scale` |
| SSH | `127.0.0.1:2222`, Windows PowerShell 5.1 default shell |
| Host shared folder | `/run/media/nico/200GB_DATA/electron/artifacts` |
| Guest shared folder | `\\host.lan\Data` |
| Persistent VM storage | `/run/media/nico/Media/windows-lab-vm-storage` |
| OEM setup | `/run/media/nico/200GB_DATA/windows-vm/oem/install.bat` |

The shared folder's path is historical; it works for any project. The guest's C: drive is persistent. The OEM setup enables OpenSSH with Windows PowerShell as its shell and disables sleep; do not rerun provisioning to start a test.

The guest keeps its timezone on UTC because QEMU's clock is UTC, and Windows Time starts automatically. Keep both. If network or TLS requests hang, compare the guest clock with `date -u` first.

Node.js 24 with npm, Git and Visual Studio Build Tools 2026 are installed; pnpm and bun are not. `python.exe` is only the Microsoft Store stub, so node-gyp needs a real Python. Identify the OS by `BuildNumber`; the registry `ProductName` says Windows 10.

## Lock and lifecycle

Follow [lab locks](references/locks.md) with `/home/nico/.codex/skills/windows-lab/scripts/hold-lock.sh vm` for all guest access, testing, restoration and shutdown. Don't stop another task's processes or overwrite its files.

Inspect the container, then start it if stopped:

```sh
docker inspect windows --format '{{.State.Status}}'
docker start windows
```

If the container is missing, inspect the existing Compose setup before recreating it. Keep its storage mount and credentials. Never create a second VM on the same disk or reinstall Windows to get another OS version.

## PowerShell access

Credentials live in the Compose service's `environment`. The helper reads them at runtime and sends UTF-16LE encoded PowerShell, avoiding shell expansion and nested SSH quoting. Never copy the password into commands, scripts or evidence, or dump the Compose file or container environment.

```sh
H=/home/nico/.codex/skills/windows-lab/scripts/vm-ssh.py
python $H --wait-ready 600
python $H --command 'Get-CimInstance Win32_OperatingSystem | Select-Object Caption,BuildNumber'
python $H --script /absolute/host/path/check.ps1 --timeout 300
```

`--wait-ready SECONDS` retries until the guest runs commands, which takes several minutes after `docker start`, and prints `READY`. Docker's start message, the console and an open SSH port do not mean the guest is ready. `--script` runs a host file's contents; it does not upload the file. `--forward PORT` forwards host `127.0.0.1:PORT` to the guest's loopback port until you kill it, for example for a `--remote-debugging-port`.

The helper returns PowerShell's exit code, or 124 on timeout (default 120 seconds). A timeout does not stop the guest job or prove a crash: inspect its process before retrying a mutation. For native programs, check `$LASTEXITCODE` and `exit` with it when it must decide the result.

## Transfers and desktop tests

Create a host directory under the shared folder, such as `windows-lab/APP-TASK`, and a guest workspace at `C:\windows-lab\APP-TASK`. Copy artifacts through the share and extract them locally before running them:

```powershell
$share = '\\host.lan\Data\windows-lab\APP-TASK'
$work = 'C:\windows-lab\APP-TASK'
New-Item -ItemType Directory -Path $work -Force | Out-Null
Copy-Item (Join-Path $share 'app.zip') (Join-Path $work 'app.zip')
& tar.exe -xf (Join-Path $work 'app.zip') -C $work
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Use the project's complete packaging output, including icons, preloads, native modules and other runtime resources. An extracted installer payload verifies its app files, not installation, shortcuts, registry changes or upgrades. Noninteractive installer launches can wait on invisible dialogs; check the desktop before starting another installer. Linux `node_modules` and native binaries are not Windows build inputs.

For GUI launches, screenshots, native close actions and Electron inspection, read [desktop testing](references/desktop-testing.md). Processes started over SSH run outside the interactive desktop.

## Evidence and cleanup

Record the build or source, guest OS build, executable version, profile, launch flags and observed outcome. Windows 11 results do not establish Windows 10 compatibility. For timing-sensitive failures, include an uninstrumented run with stock graphics settings, since debuggers, logging and Task Manager change timing. Distinguish a disappearing window, a normal exit, an installer or bootstrapper exit and a native crash.

Save screenshots and recordings you show the user to `~/Pictures/agent-captures/<project>/`, with personal data removed. When done:

- Stop only your test processes, unregister your scheduled tasks and restore temporary app replacements and settings.
- Remove what your run created in the guest: your workspace and profiles, and protocol handlers, shortcuts, taskbar pins and `%APPDATA%` data the app registered there. Keep earlier installations and user data.
- Delete your share task folder, naming it with a literal path.

Then stop the VM, including when it was already running, unless `hold-lock.sh --status vm` shows another agent waiting or the user asked to keep it running; say so in your handoff.

```sh
docker stop --timeout 120 windows
docker inspect windows --format '{{.State.Status}} running={{.State.Running}}'
```

Wait for `exited running=false` before releasing the lock.
