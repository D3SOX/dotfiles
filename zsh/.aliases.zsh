# Move wget hosts file
alias wget="wget --hsts-file ~/.config/wget-hsts"
alias yt2mp3="yt-dlp -i --extract-audio --audio-format mp3 --embed-thumbnail --add-metadata -o '%(title)s.%(ext)s'"
alias ytdl="yt-dlp -i -f 'bestvideo[ext!=webm]+bestaudio[ext!=webm]/best[ext!=webm]'"

if [ "$TERM_PROGRAM" != "vscode" ]; then
    alias clear="clear && pfetch"
fi

alias ls="eza -lhg --color=always --group-directories-first --icons=always"
alias dke="docker exec"
alias dkup="docker compose up -d"
alias dkuplog='docker compose up -d && docker compose logs -f'
alias vim="nvim"
alias vi="nvim"
alias v="nvim"
alias mv="mv -i -v"
alias cp="cp -v"
alias rm="rm -i -v"
alias mkdir="mkdir -v"
alias chmod="chmod -c"
alias chown="chown -c"
alias upload="curl --upload-file"
alias sxconf="$EDITOR ~/.config/sxhkd/sxhkdrc"
alias bconf="$EDITOR ~/.config/bspwm/bspwmrc"
alias rrsync="rsync -uvrP"
alias sstart="sudo systemctl start"
alias srestart="sudo systemctl restart"
alias sstop="sudo systemctl stop"
alias sstatus="sudo systemctl status"
alias senable="sudo systemctl enable"
alias sdisable="sudo systemctl disable"
alias sustart="systemctl --user start"
alias surestart="systemctl --user restart"
alias sustop="systemctl --user stop"
alias sustatus="systemctl --user status"
alias suenable="systemctl --user enable"
alias sudisable="systemctl --user disable"
alias ga="git add"
alias gc="git commit -v"
alias gp="git push"
alias gspp='() { sid=$(git stash push -q -m gspp && git stash list | head -1 | cut -d: -f1); git pull && [ -n "$sid" ] && git stash pop "$sid"; }'
alias gsu="git submodule update --init --recursive"
alias ":q"="exit"
alias type-clipboard='sh -c "sleep 3; xdotool type \"$(xclip -o -sel clip)\""'
alias reboot-windows="sudo grub-reboot 'Windows Boot Manager (on /dev/nvme1n1p1)' && sudo reboot"
alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"

# Forward remote services to localhost, optionally remapping a single local port.
ssh-portforward() {
    local ssh_host remote_ports remote_port local_port
    local -a ports forwards
    local usage='Usage: ssh-pfw [port[,port...]] [host] [-l|--local-port port (single port only)] (ports: 1-65535)'
    while (( $# )); do
        case "$1" in
            -l|--local-port)
                if (( $# < 2 )) || [[ "$2" != <1-65535> ]]; then
                    print -u2 "$usage"
                    return 1
                fi
                local_port="$2"
                shift
                ;;
            <->|*,*)
                if [[ -n "$remote_ports" ]]; then
                    print -u2 "$usage"
                    return 1
                fi
                remote_ports="$1"
                ;;
            -*|'')
                print -u2 "$usage"
                return 1
                ;;
            *)
                if [[ -n "$ssh_host" ]]; then
                    print -u2 "$usage"
                    return 1
                fi
                ssh_host="$1"
                ;;
        esac
        shift
    done

    if [[ -z "$ssh_host" ]]; then
        read -r "ssh_host?SSH host (or user@host): " || return 1
    fi
    if [[ -z "$remote_ports" ]]; then
        read -r "remote_ports?Remote service ports (comma-separated): " || return 1
    fi
    ports=("${(@s:,:)remote_ports}")

    if [[ -z "$ssh_host" ]] || (( ${#ports} == 0 )) || [[ -n "$local_port" && ${#ports} != 1 ]]; then
        print -u2 "$usage"
        return 1
    fi
    for remote_port in "${ports[@]}"; do
        if [[ "$remote_port" != <1-65535> ]]; then
            print -u2 'Enter an SSH host and ports between 1 and 65535.'
            return 1
        fi
        forwards+=(-L "127.0.0.1:${local_port:-$remote_port}:localhost:${remote_port}")
    done

    for remote_port in "${ports[@]}"; do
        print "Forwarding localhost:${local_port:-$remote_port} to ${ssh_host}:${remote_port} (Ctrl+C to stop)."
    done
    ssh -N -o ExitOnForwardFailure=yes "${forwards[@]}" -- "$ssh_host"
}
alias ssh-pfw='ssh-portforward'

# CodeRabbit review queue on the Pi
# Each command accepts an optional repository name; the default is all three.
unalias crq-start crq-stop crq-status crq-sync-to-pi 2>/dev/null

_crq-pi() {
  python3 - "$@" <<'PY'
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys

repos = ("OpenTubeX/OpenTubeX", "D3SOX/Nevumi", "D3SOX/Vegsnap")
action = sys.argv[1]
selection = sys.argv[2:]
if len(selection) > 1:
    raise SystemExit(f"Usage: crq-{action} [all|opentubex|nevumi|vegsnap]")
if selection and selection[0].lower() != "all":
    selected = selection[0].lower()
    repos = tuple(repo for repo in repos if selected in (repo.lower(), repo.split('/')[1].lower()))
    if not repos:
        raise SystemExit(f"Unknown repository: {selection[0]}. Choose opentubex, nevumi, vegsnap, or all.")

if action != "sync-to-pi":
    remote = '''
set -u
action=$1
shift
state="${XDG_STATE_HOME:-$HOME/.local/state}/coderabbit-review-queue"
queue=/home/alarm/.local/bin/coderabbit-review-queue
result=0
for repo in "$@"; do
    key="${repo%/*}__${repo#*/}"
    pid_file="/tmp/coderabbit-review-queue-$key.pid"
    pid=''
    [[ ! -r $pid_file ]] || read -r pid < "$pid_file"
    running=0
    if [[ $pid =~ ^[0-9]+$ ]] && (( pid > 1 )) && kill -0 "$pid" 2>/dev/null; then
        running=1
    fi
    printf '\\n%s\\n' "$repo"
    case $action in
        start)
            if (( running )); then
                printf 'Monitor: already running (PID %s)\\n' "$pid"
            else
                if [[ ! -x $queue ]] || ! mkdir -p "$state"; then
                    printf 'Monitor: cannot start %s\\n' "$queue" >&2
                    result=1
                    continue
                fi
                nohup "$queue" --repo "$repo" >>"$state/$key-monitor.log" 2>&1 </dev/null &
                printf 'Monitor: start requested (log: %s/%s-monitor.log)\\n' "$state" "$key"
            fi
            ;;
        stop)
            if (( running )); then
                if kill -TERM "$pid"; then
                    printf 'Monitor: stop requested (PID %s)\\n' "$pid"
                else
                    result=1
                fi
            else
                printf 'Monitor: already stopped\\n'
            fi
            ;;
        status)
            if (( running )); then
                printf 'Monitor: running (PID %s)\\n' "$pid"
            else
                printf 'Monitor: stopped\\n'
            fi
            "$queue" --repo "$repo" --status || result=1
            ;;
    esac
done
exit "$result"
'''
    subprocess.run(["ssh", "pi", shlex.join(["bash", "-s", "--", action, *repos])], input=remote, text=True, check=True)
    raise SystemExit(0)

state = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "coderabbit-review-queue"
# Sync queue order and portable preferences; missing files restore defaults.
# Agent host stays configured separately on each machine.
settings = (
    "order.txt", "excluded-branches", "excluded-authors",
    "ignore-drafts", "new-items-at-top", "requeued-items-at-top",
    "notify-sound", "notify-sound-path",
    "notify-sound-volume", "stop-when-empty",
    "auto-delegate", "delegation-prompt-mode", "delegation-prompt-template",
    "steer-running-agents", "resolve-merge-conflicts",
    "auto-merge", "merge-method", "delete-branch",
    "merge-after-delegation", "merge-after-approval", "merge-admin",
    "archive-after-merge",
)
if not state.is_dir():
    raise SystemExit(f"Queue settings directory does not exist: {state}")
values = {}
for repo in repos:
    key = repo.replace("/", "__")
    values[repo] = {}
    for setting in settings:
        path = state / f"{key}-{setting}"
        try:
            values[repo][setting] = path.read_text()
        except FileNotFoundError:
            values[repo][setting] = None

remote = '''
import json, os, tempfile
from pathlib import Path
import sys
state = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state"))) / "coderabbit-review-queue"
state.mkdir(parents=True, exist_ok=True)
for repo, settings in json.load(sys.stdin).items():
    key = repo.replace("/", "__")
    for setting, value in settings.items():
        target = state / f"{key}-{setting}"
        if value is None:
            target.unlink(missing_ok=True)
        else:
            with tempfile.NamedTemporaryFile(mode="w", dir=state, delete=False) as temporary:
                temporary.write(value)
            os.replace(temporary.name, target)
    print(f"Synced {repo} queue order and preferences to pi.")
'''
subprocess.run(["ssh", "pi", "python3 -c " + shlex.quote(remote)], input=json.dumps(values), text=True, check=True)
PY
}

crq-start() { _crq-pi start "$@"; }
crq-stop() { _crq-pi stop "$@"; }
crq-status() { _crq-pi status "$@"; }
crq-sync-to-pi() { _crq-pi sync-to-pi "$@"; }

# Do a dummy git commit to trigger the PGP sign modal
alias dummygc="mkdir ~/testgit && cd ~/testgit && git init && touch a && git add a && git commit -m 'a' && cd ~ && rm -rf ~/testgit"

# Load machine-local credentials when available.
[[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/claudex/secrets.zsh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/claudex/secrets.zsh"

# Launch Claude Code with GPT-5.6 Sol through the local Codex bridge.
alias claudex='ANTHROPIC_BASE_URL=http://127.0.0.1:8317 ANTHROPIC_AUTH_TOKEN="${CODEX_BRIDGE_TOKEN:?Set CODEX_BRIDGE_TOKEN in ~/.config/claudex/secrets.zsh}" CLAUDE_CODE_SUBAGENT_MODEL=gpt-5.6-sol CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3 ENABLE_TOOL_SEARCH=false claude --dangerously-skip-permissions --model gpt-5.6-sol'
