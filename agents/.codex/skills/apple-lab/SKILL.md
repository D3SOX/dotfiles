---
name: apple-lab
description: Build and test macOS, iOS and iPadOS apps using the local macOS Docker VM, Xcode simulators, and the physical iPad connected through nico-laptop. Use for macOS app, CLI or packaging checks, IPA preparation, native tests, WebView inspection, lifecycle checks, or physical acceptance checks.
---

# Apple lab

Read the repository's AGENTS.md and inspect the current branch/worktrees first. The macOS guest checkout has no Git metadata and may contain another task's sources. Identify the intended source commit before syncing or testing. Discover the target project's build workflow, Xcode project/workspace, scheme, bundle IDs, app product, test targets and deployment target; do not assume Capacitor, Xcode or a particular app layout. Use pnpm if the project already uses it; otherwise use bun for JavaScript commands. Native projects may not need either.

Before physical-device access or VM authentication, read [local.md](local.md) for private device identifiers and credentials. This file is Git-ignored; preserve it when copying skill updates. If it is missing, obtain the relevant values from the user or existing device configuration before access.

- **Simulator tests or IPA builds:** read [VM and builds](references/vm-and-builds.md).
- **macOS apps, CLIs or packages:** read [VM and builds](references/vm-and-builds.md) for access and source sync, then [macOS apps](references/macos-apps.md).
- **Physical iPad, installation or inspection:** read [Physical iPad](references/physical-ipad.md). IPA preparation also uses the VM reference.

## Shared resources

The Docker container `macos`, its guest desktop, shared simulators and physical iPad can be in use by other agents. Check existing sessions/processes before starting work; a newly introduced lock does not prove earlier agents are idle. Use an isolated guest checkout for each task. Never reset another checkout or stop another agent's inspector/build.

Use these host lock files for new lab sessions:

- VM desktop, simulator and Xcode work: `/tmp/apple-lab-vm.lock`
- Physical iPad: `/tmp/apple-lab-ipad.lock`, on **both this host and nico-laptop**.

These lock filenames identify shared hardware, not the app under test. Use them in every project.

Hold each needed lock as a separate long-running background command (its own exec session in Codex, `run_in_background` in Claude Code) for the whole workflow. The holder is a single process, so killing its PID releases the lock:

```sh
bash -c 'exec 9>>/tmp/apple-lab-vm.lock; flock -n -E 75 9 || exit 75; echo LAB_LOCK_ACQUIRED pid=$$; exec sleep infinity'
```

For physical work use the iPad lock locally, plus a remote holder. It exits when the SSH connection's terminal closes:

```sh
ssh -tt -o BatchMode=yes nico-laptop \
  "bash -c 'exec 9>>/tmp/apple-lab-ipad.lock; flock -n -E 75 9 || exit 75; echo LAB_LOCK_ACQUIRED pid=\$\$; exec sleep infinity'"
```

Continue only after each holder prints `LAB_LOCK_ACQUIRED pid=<PID>`, and record each PID. Exit 75 means occupied: coordinate or wait. While holding a lock, run commands directly; do not wrap them in `flock`, since your own holder makes that fail with 75. After restoration, inspector cleanup and any required VM shutdown below, release each lock by killing its recorded PID (`ssh -o BatchMode=yes nico-laptop 'kill PID'` for the remote one) and confirm with `flock -n LOCK_FILE true` on each host. Release every lock before ending your turn unless you continue lab work in the same session. Never kill holders by pattern (`pkill -f`), never use an ad-hoc `flock FILE COMMAND` holder (killing `flock` leaves its child holding the lock), and never delete a lock file to bypass its holder.

As soon as the macOS VM is no longer needed, stop the `macos` container, including when it was already running before your task. While still holding the VM lock, copy required artifacts and evidence to the host, finish cleanup and check that no other agent or user is using the guest. If it is idle, run `docker stop --timeout 120 macos` and verify `docker inspect --format '{{.State.Status}}' macos` reports `exited` before releasing the lock. Do not leave the VM running while waiting for user feedback or physical-device testing that does not need it. Leave it running only for another active user/task or an explicit user request, and state why in the handoff.

## Evidence and user involvement

- Exhaust useful unattended simulator checks before asking the user for repetitive hardware work. Use the available physical device for checks that do not require human actions or observation.
- When the user is away, do not lock the iPad, alter authentication/network access, or start a flow that needs them to recover it. Existing authorization and availability instructions take precedence.
- For a hardware test, give one concise sequence with the build, initial state, duration and exact success/failure question. Disconnect the inspector before background, PiP, screen-lock, interruption or battery-sensitive tests.
- Advancing time, a Pause icon, or working lock-screen controls do **not** prove audible playback. Obtain the user's listening result for sound and audio routes.
- Record source commit, installed build, model/OS build, simulator runtime, guest macOS version/architecture and any engine override. Distinguish stock simulator, modified simulator, temporary physical preview and compiled physical results.
- Preserve original failures and focused red/green evidence outside the repository, preferably under `~/.local/state/apple-lab/<app>/<task>/`. Keep issue updates concise. Restore settings, app state, temporary hooks and any playback state; preserve existing downloads and app data.
- Signing/installing a new IPA needs the user's iloader step in this setup. Preparing an IPA does not prove installation: verify the app's build afterward. A passing diagnostic app does not establish that the target app passes the same check.
