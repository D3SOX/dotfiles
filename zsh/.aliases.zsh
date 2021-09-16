# Move wget hosts file
alias wget="wget --hsts-file ~/.config/wget-hsts"
alias yt2mp3="youtube-dl -i --extract-audio --audio-format mp3 --embed-thumbnail --add-metadata -o '%(title)s.%(ext)s'"
alias ytdl="youtube-dl -i -f 'bestvideo[ext!=webm]+bestaudio[ext!=webm]/best[ext!=webm]'"

if [ "$TERM_PROGRAM" != "vscode" ]; then
    alias clear="clear && pfetch"
fi

alias ls="exa -lhg --color=always --group-directories-first --icons"
alias dke="docker exec"
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
alias scs="VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/amd_pro_icd64.json progl /usr/bin/mon2cam -e vdpau -m 0 -f 30"
alias rrsync="rsync -uvrP"
alias sstart="sudo systemctl start"
alias sstop="sudo systemctl stop"
alias ga="git add"
alias gc="git commit -v"
alias gp="git push"
alias gsu="git submodule update --init --recursive"
alias ":q"="exit"
alias yay-devel="paru -Syu --devel"
alias type-clipboard='sh -c "sleep 3; xdotool type \"$(xclip -o -selection clipboard)\""'
alias reboot-windows="sudo grub-reboot 'Windows Boot Manager (on /dev/nvme0n1p1)'"
alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"
