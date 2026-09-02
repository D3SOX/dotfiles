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

# CodeRabbit review queue on the Pi
alias crq-start='ssh pi "nohup /home/alarm/.local/bin/coderabbit-review-queue --repo OpenTubeX/OpenTubeX >>/home/alarm/.local/state/coderabbit-review-queue/OpenTubeX__OpenTubeX-monitor.log 2>&1 </dev/null &"'
alias crq-stop='ssh pi "kill -TERM \$(cat /tmp/coderabbit-review-queue-OpenTubeX__OpenTubeX.pid)"'
alias crq-status='ssh pi "bash -lc '\''if [[ -s /tmp/coderabbit-review-queue-OpenTubeX__OpenTubeX.pid ]] && kill -0 \"\$(cat /tmp/coderabbit-review-queue-OpenTubeX__OpenTubeX.pid)\" 2>/dev/null; then printf \"Monitor: running (PID %s)\\n\" \"\$(cat /tmp/coderabbit-review-queue-OpenTubeX__OpenTubeX.pid)\"; else printf \"Monitor: stopped\\n\"; fi; /home/alarm/.local/bin/coderabbit-review-queue --repo OpenTubeX/OpenTubeX --status'\''"'
alias crq-order-push='scp ~/.local/state/coderabbit-review-queue/OpenTubeX__OpenTubeX-order.txt pi:/home/alarm/.local/state/coderabbit-review-queue/OpenTubeX__OpenTubeX-order.txt.tmp && ssh pi "mv /home/alarm/.local/state/coderabbit-review-queue/OpenTubeX__OpenTubeX-order.txt.tmp /home/alarm/.local/state/coderabbit-review-queue/OpenTubeX__OpenTubeX-order.txt"'

# Do a dummy git commit to trigger the PGP sign modal
alias dummygc="mkdir ~/testgit && cd ~/testgit && git init && touch a && git add a && git commit -m 'a' && cd ~ && rm -rf ~/testgit"

# SSH_TTY can be missing in reused remote terminals such as tmux sessions.
gpg-unlock() {
    local gpg_ssh_tty="${SSH_TTY:-}"
    if [[ -z "$gpg_ssh_tty" && ( -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" ) ]]; then
        gpg_ssh_tty=remote
    fi
    SSH_TTY="$gpg_ssh_tty" command "$HOME/.local/bin/gpg-unlock" "$@"
}

# Load machine-local credentials when available.
[[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/claudex/secrets.zsh" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/claudex/secrets.zsh"

# Launch Claude Code with GPT-5.6 Sol through the local Codex bridge.
alias claudex='ANTHROPIC_BASE_URL=http://127.0.0.1:8317 ANTHROPIC_AUTH_TOKEN="${CODEX_BRIDGE_TOKEN:?Set CODEX_BRIDGE_TOKEN in ~/.config/claudex/secrets.zsh}" CLAUDE_CODE_SUBAGENT_MODEL=gpt-5.6-sol CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3 ENABLE_TOOL_SEARCH=false claude --dangerously-skip-permissions --model gpt-5.6-sol'
