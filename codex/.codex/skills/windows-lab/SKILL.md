---
name: windows-lab
description: Test and debug Windows desktop apps in this machine's local Windows Docker VM. Use for Windows executables, installers, native desktop interactions, startup/shutdown checks, or Windows-specific failures.
---

# Windows lab

Read the target repository's instructions and identify the intended source/build before testing. Discover its Windows packaging, executable, data directory, and test workflow rather than assuming a framework or project layout. Use task-specific guest directories and test profiles; existing guest files may belong to another task.

## Local setup

Verified on 2026-10-14. Recheck configuration and versions when they matter.

| Resource | Local value |
|---|---|
| Docker image / container | `dockurr/windows` / `windows` |
| Compose configuration | `/run/media/nico/200GB_DATA/windows-vm/compose.yml` |
| Guest | Windows 11 Pro; account from Compose `USERNAME` |
| Configured resources | 8 GB RAM, 18 vCPUs, 150 GB guest disk |
| Browser console | `http://127.0.0.1:8007` |
| SSH | `127.0.0.1:2222`, Windows PowerShell 5.1 default shell |
| RDP | `127.0.0.1:3390`, TCP and UDP |
| Host shared folder | `/run/media/nico/200GB_DATA/electron/artifacts` |
| Guest shared folder | `\\host.lan\Data` |
| Persistent VM storage | `/run/media/nico/Media/opentubex-windows-vm-storage` |
| OEM setup | `/run/media/nico/200GB_DATA/windows-vm/oem/install.bat` |
| SSH known hosts | `/run/media/nico/200GB_DATA/windows-vm/known_hosts` |

The storage and shared-folder names are historical infrastructure paths. They work for any project. The guest's C: drive is persistent; `/shared` is the Docker mount backing the guest's SMB share, not a Windows path. The OEM setup enables OpenSSH, selects Windows PowerShell as the SSH shell, and disables sleep/hibernation. Do not rerun provisioning just to start a test.

Credentials live in the Compose service's `environment.USERNAME` and `environment.PASSWORD`. Read them at runtime through the helper below. Do not copy passwords into the skill, scripts, command arguments, or evidence. Avoid dumping the full Compose file or container environment.

## Ownership and lifecycle

The container and desktop are shared. Hold `/tmp/windows-lab-vm.lock` throughout guest access, testing, restoration, and shutdown:

```sh
flock -n -E 75 /tmp/windows-lab-vm.lock \
  bash -c 'echo LAB_LOCK_ACQUIRED; exec sleep infinity'
```

Keep the holder in a separate interactive exec session. Continue after `LAB_LOCK_ACQUIRED`; exit 75 means occupied. Release with Ctrl-C when done, and never delete a lock file to bypass its holder. This lock is a new coordination convention; inspect existing lab sessions and the desktop before treating a previously running VM as idle. Do not stop another task's processes or overwrite its files.

Inspect the existing container, then start it if stopped:

```sh
docker inspect windows --format '{{.State.Status}} {{json .HostConfig.PortBindings}} {{json .Mounts}}'
docker start windows
docker logs --tail 15 windows
```

If the container is missing, inspect the existing Compose setup before recreating it. Preserve its storage mount and credentials. Do not create a second VM sharing the same writable disk or reinstall Windows to obtain a different OS version.

Boot can take several minutes. Docker's "Windows started successfully" message, a connected noVNC page, and an open SSH port do not establish guest readiness. Early SSH attempts have returned connection resets, banner timeouts, or connected without completing a command. Use bounded retries of a short readiness command, inspect the desktop, and allow the guest to finish signing in. The OEM `ssh-ready.txt` marker records provisioning, not current boot readiness.

## PowerShell access

The host has `sshpass` and Python with PyYAML. The helper uses the existing credentials and sends UTF-16LE encoded PowerShell, avoiding Bash/zsh expansion and nested SSH quoting:

```sh
python /home/nico/.codex/skills/windows-lab/scripts/vm-ssh.py \
  --command 'Write-Output READY; Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture; query user'

python /home/nico/.codex/skills/windows-lab/scripts/vm-ssh.py \
  --script /absolute/host/path/check.ps1 --timeout 60
```

`--script` reads a host file and executes its contents in the SSH session; it does not upload that file. The helper propagates SSH/PowerShell's exit code and returns 124 on timeout. A transport timeout does not prove a crash or stop the guest job: inspect its task/PID before retrying a mutation. For native programs, explicitly check `$LASTEXITCODE` in PowerShell and `exit` with that value when it must control the SSH result.

Do not assume the guest has a project's SDK, Git, package manager, or native dependencies. Node.js was available at `C:\Program Files\nodejs\node.exe` during earlier work; verify it and any required toolchain. Linux `node_modules` and native binaries are not Windows build inputs.

## Transfers and desktop tests

Create a unique host directory under the shared folder, for example `windows-lab/APP-TASK`, and its guest workspace at `C:\windows-lab\APP-TASK`. Copy ZIPs or build artifacts through the share, then extract locally for execution:

```powershell
$share = '\\host.lan\Data\windows-lab\APP-TASK'
$work = 'C:\windows-lab\APP-TASK'
New-Item -ItemType Directory -Path $work -Force | Out-Null
Copy-Item (Join-Path $share 'app.zip') (Join-Path $work 'app.zip')
& tar.exe -xf (Join-Path $work 'app.zip') -C $work
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

Use the project's complete packaging output. Wait for post-build steps to finish, preserve the configured package directory structure, and include icons, preloads, native modules, and other runtime resources. An extracted installer payload verifies its app files; it does not establish that installation, shortcuts, registry changes, or upgrades work. Noninteractive installer launches can wait on invisible dialogs; inspect the desktop before starting another installer.

For GUI launches, browser control, native close actions, and optional Electron inspection, read [references/desktop-testing.md](references/desktop-testing.md). SSH alone does not guarantee an app is visible in the interactive desktop session.

## Evidence and cleanup

Record the build/source, guest OS build, executable version, profile, launch flags, and actual observed outcome. Windows 11 results do not establish Windows 10 compatibility. For timing-sensitive failures, include an uninstrumented run with stock graphics settings; debuggers, logging, and Task Manager can change timing.

Distinguish a disappearing window, a normal process exit, an installer/bootstrapper exit, and a native crash. Preserve the initial failure and focused verification logs/screenshots/recordings in the task's shared artifact directory, with personal data removed. A passing launch process is insufficient when an app hands off to an existing instance or spawns a replacement.

Restore temporary app replacements and settings, unregister your temporary scheduled tasks, stop only your test processes, and remove your disposable profiles/workspaces after saving evidence. Preserve existing installations and user data. If you started the VM, stop it when it is no longer needed; if it was already running, check for other active users/tasks before stopping it. Leave it running only for an active owner or an explicit request, and state that in the handoff.

```sh
docker stop --timeout 120 windows
docker inspect windows --format '{{.State.Status}} running={{.State.Running}}'
```

Wait for `exited running=false` before reporting shutdown and releasing the lock. Keep the VM disk and shared artifact folder intact.
