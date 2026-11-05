# Agents

Configuration for Codex, Claude Code, and T3 Code. Paths in this directory mirror `$HOME`.

## Launcher

`.local/bin/claude`, `codex`, and `t3code` are wrappers that start the real binaries in `/usr/bin` through `.local/bin/agent-run`. They take effect only while `~/.local/bin` comes before `/usr/bin` in `PATH`, which `zsh/.zshenv` sets up. The `.desktop` files in `.local/share/applications` launch T3 Code and the URL handlers through `agent-run` as well.

For each session, `agent-run`:

- creates a `TMPDIR` under `~/.cache/agent-tmp`, because `/tmp` is a small tmpfs, and holds a shared lock on it while the session runs;
- deletes session directories from earlier sessions whose lock has been released;
- sets `AGENT_RUN=1`, which makes `zsh/.zshenv` give non-interactive agent shells bash-like globbing and word splitting.

## Instructions and skills

`.codex/AGENTS.md` holds the global instructions. `.claude/CLAUDE.md` links to it, so Codex and Claude Code read the same file.

Skills live in `.codex/skills`. Claude Code finds them through `.claude/skills`, which has one relative link per skill, so a new skill needs a link there too. `.agents/skills` holds skills installed from other repositories, recorded in `.agents/.skill-lock.json`. Update those from their source instead of editing them here.

`android-lab`, `apple-lab`, and `windows-lab` depend on the devices and VMs connected to the desktop. Leave them off other machines.

## Cleanup jobs

Two user tmpfiles rules in `.config/user-tmpfiles.d` delete old agent files:

- `agent-tmp.conf` deletes session temp files in `~/.cache/agent-tmp` after 7 days without use.
- `agent-captures.conf` deletes screenshots and recordings in `~/Pictures/agent-captures` after 3 days without use.

systemd applies these rules only while the user cleanup timer is enabled. On a new machine, run this from this directory:

```sh
mkdir -p ~/.config/user-tmpfiles.d
cp .config/user-tmpfiles.d/*.conf ~/.config/user-tmpfiles.d/
systemd-tmpfiles --user --create
systemctl --user enable --now systemd-tmpfiles-clean.timer
```

`systemctl --user list-timers systemd-tmpfiles-clean.timer` shows the next run.
