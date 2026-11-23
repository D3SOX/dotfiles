# Lab locks

Lab devices and VMs are shared by many agents on this machine. Hold the matching lock for the whole workflow, from first contact through cleanup and shutdown. The main skill lists the lock names; `scripts/hold-lock.sh NAME` in the skill's directory holds `/tmp/<skill>-NAME.lock`.

- Run the holder as its own long-running background command: in Claude Code, `run_in_background` with `timeout: 7200000`; in Codex, its own exec session. Continue after `LAB_LOCK_ACQUIRED pid=PID` and record the PID.
- Exit 75 means another agent holds the lock. `hold-lock.sh --status [NAME...]` lists held and queued locks with their PID, age and working directory, which names the agent's worktree. Use a free alternative, or queue with `hold-lock.sh --wait SECONDS NAME` and a background timeout above `SECONDS`. Never touch a locked target, its processes or its lock.
- The holder also stops when its background timeout expires, its session ends or T3 restarts. After long waits or a restart, check `kill -0 PID` before the next lab command and reacquire the lock if it is gone.
- While holding the lock, run commands directly. Wrapping them in `flock` fails with 75 against your own holder.
- After cleanup, release with `kill PID` (the holder exits 0) and confirm with `flock -n /tmp/<skill>-NAME.lock true`. Release before ending your turn unless you continue lab work in the same session.
- Never kill holders by pattern, use an ad-hoc `flock FILE COMMAND` holder (killing `flock` leaves its child holding the lock), or delete lock files.

## Locks on nico-laptop

Devices plugged into the laptop also need the laptop's lock, since agents there use them too. The laptop has no lab skills, so run this holder inline, as a separate background command after the local lock, with the same lock file name:

```sh
ssh -tt -o BatchMode=yes nico-laptop "bash -c 'exec 9>>/tmp/SKILL-NAME.lock; flock -n -E 75 9 || exit 75; echo LAB_LOCK_ACQUIRED remote_pid=\$\$; trap \"exit 0\" TERM; exec 8<> <(:); read -r -u 8'"
```

Record the `remote_pid`. If either lock is busy, release the one you got. Release the remote lock first with `ssh -o BatchMode=yes nico-laptop 'kill REMOTE_PID'`, then the local one, and confirm both are free.
