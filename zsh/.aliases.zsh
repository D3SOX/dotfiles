# Move wget hosts file
alias wget="wget --hsts-file ~/.config/wget-hsts"
alias yt2mp3="yt-dlp -i --extract-audio --audio-format mp3 --embed-thumbnail --add-metadata -o '%(title)s.%(ext)s'"
alias ytdl="yt-dlp -i -f 'bestvideo[ext!=webm]+bestaudio[ext!=webm]/best[ext!=webm]'"

if [ "$TERM_PROGRAM" != "vscode" ]; then
    alias clear="clear && fastfetch -c pfetch"
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
alias flatpak=rpak

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
