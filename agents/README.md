# Agents

Configuration for Codex, Claude Code, and T3 Code. Paths in this directory mirror `$HOME`.

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
