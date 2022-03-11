typeset -U PATH path

export LANG=en_US.UTF-8

# XDG paths
export XDG_DATA_HOME=${XDG_DATA_HOME:="$HOME/.local/share"}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:="$HOME/.cache"}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:="$HOME/.config"}

# Set manpager
export MANPAGER="nvim -c 'Man!' -"
# Set default apps
export EDITOR="nvim"
export VISUAL="${EDITOR}"
export TERMINAL="konsole"
export BROWSER="firefox"
export READER="okular"
export VIDEO="mpv"
export IMAGE="gwenview"
export COLORTERM="truecolor"
export OPENER="xdg-open"
export PAGER="less"
# Disable less history file
export LESSHISTFILE="-"
# Disable node history file
export NODE_REPL_HISTORY=""
# Other config moves
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export GOPATH="$XDG_DATA_HOME/go"
# bat theme
export BAT_THEME="TwoDark"
