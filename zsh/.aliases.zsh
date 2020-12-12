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
alias mv="mv -i -v"
alias cp="cp -v"
alias rm="rm -i -v"
alias mkdir="mkdir -v"
alias chmod="chmod -v"
alias chown="chown -v"
alias upload="curl --upload-file"
alias sxconf="$EDITOR ~/.config/sxhkd/sxhkdrc"
alias bconf="$EDITOR ~/.config/bspwm/bspwmrc"
alias scs="mon2cam -m 0"
alias rrsync="rsync -uvrP"
alias sstart="sudo systemctl start"
alias sstop="sudo systemctl stop"
alias ga="git add"
alias gc="git commit -v"
alias gp="git push"
alias ":q"="exit"
alias yay-devel="yay -Syu --devel"
alias type-clipboard='sh -c "sleep 0.5; xdotool type \"$(xclip -o -selection clipboard)\""'
