typeset -U PATH path
export PNPM_HOME="$HOME/.local/share/pnpm"
path=(
    "$PNPM_HOME"
    "$HOME/.local/bin"
    $path
    "$HOME/.yarn/bin"
    "$HOME/.local/share/cargo/bin"
    "$HOME/Flutter/flutter/bin"
    "$HOME/Android/Sdk/cmdline-tools/latest/bin"
)
export PATH

export LANG=en_US.UTF-8

# Android Studio's SDK, the one with accepted licences
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
# The Android CLI behind sdkmanager uploads usage metrics and ignores the
# ~/.android/analytics.settings opt-out; point its uploads at a closed port
export ANDROID_CLI_ANALYTICS_URL=http://127.0.0.1:9
export ANDROID_CLI_CRASH_URL=http://127.0.0.1:9

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
export GOBIN="$GOPATH/bin"
# bat theme
export BAT_THEME="TwoDark"

# Agent shells (started via agent-run): pass unmatched globs through and split
# unquoted variables like bash, since agents write bash-style commands.
[[ -n $AGENT_RUN && ! -o interactive ]] && setopt no_nomatch sh_word_split
