---
name: ios-lab
description: Build and test iOS/iPadOS apps using the local macOS Docker VM, Xcode simulators, and the physical iPad connected through nico-laptop. Use for IPA preparation, native tests, WebView inspection, lifecycle checks, or physical acceptance checks.
---

# iOS lab

Read the repository's AGENTS.md and inspect the current branch/worktrees first. The macOS guest checkout has no Git metadata and may contain another task's sources. Identify the intended source commit before syncing or testing. Discover the target project's build workflow, Xcode project/workspace, scheme, bundle IDs, app product, test targets and deployment target; do not assume Capacitor or a particular app layout. Use pnpm if the project already uses it; otherwise use bun for JavaScript commands. Native projects may not need either.

Before physical-device access or VM authentication, read [local.md](local.md) for private device identifiers and credentials. This file is Git-ignored; preserve it when copying skill updates. If it is missing, obtain the relevant values from the user or existing device configuration before access.

- **Simulator tests or IPA builds:** read [VM and builds](references/vm-and-builds.md).
- **Physical iPad, installation or inspection:** read [Physical iPad](references/physical-ipad.md). IPA preparation also uses the VM reference.

## Shared resources

The Docker container `macos`, its guest desktop, shared simulators and physical iPad can be in use by other agents. Check existing sessions/processes before starting work; a newly introduced lock does not prove earlier agents are idle. Use an isolated guest checkout for each task. Never reset another checkout or stop another agent's inspector/build.

Use these host lock files for new lab sessions:

- VM desktop, simulator and Xcode work: `/tmp/opentubex-ios-vm.lock`
- Physical iPad: `/tmp/opentubex-ios-ipad.lock`, on **both this host and nico-laptop**.

These historical lock filenames identify shared hardware, not the app under test. Keep them unchanged across projects.

Hold each needed lock in a separate interactive exec session for the whole workflow:

```sh
flock -n -E 75 /tmp/opentubex-ios-vm.lock \
  bash -c 'echo LAB_LOCK_ACQUIRED; exec sleep infinity'
```

For physical work use the iPad lock locally, plus a remote holder:

```sh
ssh -tt -o BatchMode=yes nico-laptop \
  "flock -n -E 75 /tmp/opentubex-ios-ipad.lock bash -c 'echo LAB_LOCK_ACQUIRED; exec sleep infinity'"
```

Continue only after each holder prints `LAB_LOCK_ACQUIRED`. Exit 75 means occupied: coordinate or wait. Release with Ctrl-C after restoration and inspector cleanup. Verify a remote holder exited if SSH drops. Never delete a lock file to bypass its holder.

## Evidence and user involvement

- Exhaust useful unattended simulator checks before asking the user for repetitive hardware work. Use the available physical device for checks that do not require human actions or observation.
- When the user is away, do not lock the iPad, alter authentication/network access, or start a flow that needs them to recover it. Existing authorization and availability instructions take precedence.
- For a hardware test, give one concise sequence with the build, initial state, duration and exact success/failure question. Disconnect the inspector before background, PiP, screen-lock, interruption or battery-sensitive tests.
- Advancing time, a Pause icon, or working lock-screen controls do **not** prove audible playback. Obtain the user's listening result for sound and audio routes.
- Record source commit, installed build, model/OS build, simulator runtime and any engine override. Distinguish stock simulator, modified simulator, temporary physical preview and compiled physical results.
- Preserve original failures and focused red/green evidence outside the repository, preferably under `~/.local/state/ios-lab/<app>/<task>/`. Keep issue updates concise. Restore settings, app state, temporary hooks and any playback state; preserve existing downloads and app data.
- Signing/installing a new IPA needs the user's iloader step in this setup. Preparing an IPA does not prove installation: verify the app's build afterward. A passing diagnostic app does not establish that the target app passes the same check.
