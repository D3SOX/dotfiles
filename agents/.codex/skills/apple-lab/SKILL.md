---
name: apple-lab
description: Build and test macOS, iOS and iPadOS apps using the local macOS Docker VM, Xcode simulators, and the physical iPad connected through nico-laptop. Use for macOS app, CLI or packaging checks, IPA preparation, native tests, WebView inspection, lifecycle checks, or physical acceptance checks.
---

# Apple lab

Read the repository's AGENTS.md and inspect the current branch and worktrees first. Identify the intended source commit before syncing or testing. Discover the project's build workflow, Xcode project or workspace, scheme, bundle IDs, app product, test targets and deployment target; do not assume Capacitor, Xcode or a particular layout.

[local.md](local.md) holds the private `IPAD_UDID` and the VM-only `builder` password. It is Git-ignored; preserve it when copying skill updates. Never print the whole file: read only the value you need (for example `grep IPAD_UDID`), and let `scripts/vm-connect.sh` read the password.

- **Simulator tests or IPA builds:** read [VM and builds](references/vm-and-builds.md).
- **macOS apps, CLIs or packages:** read [VM and builds](references/vm-and-builds.md), then [macOS apps](references/macos-apps.md).
- **Physical iPad:** read [Physical iPad](references/physical-ipad.md). IPA preparation also uses the VM reference.

## Locks

Follow [lab locks](references/locks.md) with `/home/nico/.codex/skills/apple-lab/scripts/hold-lock.sh NAME`:

- `vm`: the `macos` container, its desktop, simulators and Xcode.
- `ipad`: the physical iPad, on both this host and nico-laptop (`/tmp/apple-lab-ipad.lock` there).

Work in your own guest task directory. Never reset another task's checkout or stop another agent's inspector or build.

## VM shutdown

Stop the `macos` container as soon as you no longer need it, including when it was already running before your task. While still holding the `vm` lock, copy artifacts and evidence to the host, delete your guest files as described in the VM reference, run `docker stop --timeout 120 macos`, and wait until `docker inspect --format '{{.State.Status}}' macos` reports `exited` before releasing the lock. Don't leave the VM running while you wait for user feedback or for physical-device tests that don't need it.

If `hold-lock.sh --status vm` shows another agent waiting, you may leave the VM running for it; say so in your handoff. Also leave it running on the user's explicit request.

## Evidence and user involvement

- Exhaust useful unattended simulator checks before asking the user for repetitive hardware work. Use the physical device for checks that need no human action or observation.
- When the user is away, don't lock the iPad, change authentication or network access, or start a flow that needs them to recover it. Resume simulator or source work instead.
- For a hardware test, give one concise sequence with the build, initial state, duration and the exact success or failure question.
- Advancing time, a Pause icon or working lock-screen controls do not prove audible playback. Ask the user whether they heard sound, and which output it came from.
- Record the source commit, installed build, device model and OS build, simulator runtime, guest macOS version and architecture, and any engine override. Distinguish stock simulator, modified simulator, temporary physical preview and compiled physical results.
- Keep original failures and focused red/green evidence outside the repository, preferably under `~/.local/state/apple-lab/<app>/<task>/`. Restore settings, app state, temporary hooks and playback state; keep existing downloads and app data.
- Signing and installing a new IPA needs the user's iloader step. Preparing an IPA does not prove installation; verify the installed build afterward. A passing diagnostic app does not show that the target app passes the same check.
