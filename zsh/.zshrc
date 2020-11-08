# If not running interactively, don't do anything
[[ $- != *i* ]] && return


# Enable colors and change prompt:
autoload -U colors && colors

# History in cache directory:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.cache/zsh/history

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
# Auto complete with case insenstivity
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# Auto complete color
zstyle ':completion:*:default' list-colors \
  "di=1;36" "ln=35" "so=32" "pi=33" "ex=31" "bd=34;46" "cd=34;43" \
  "su=30;41" "sg=30;46" "tw=30;42" "ow=30;43"
# Add description to auto completions
zstyle ':completion:*:descriptions'    format $'%{\e[0;31m%}completing %B%d%b%{\e[0m%}'
# Ignore duplicate entries
zstyle ':completion:*:history-words'   remove-all-dups yes
zstyle ':completion:*:history-words'   stop yes

zmodload zsh/complist
compinit -d ~/.cache/zsh/zcompdump-$ZSH_VERSION

# Enable searching through history
bindkey '^R' history-incremental-pattern-search-backward
# Enable moving by word with ctrl + arrow keys
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Plugins
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /usr/share/zsh/plugins/zsh-you-should-use/you-should-use.plugin.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh

# Theme
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# Options

# ignore duplicates in history
setopt histignoredups
# save each command's beginning timestamp and the duration to the history file
setopt extended_history
# remove command lines from the history list when the first character on the
# line is a space
setopt histignorespace
# if a command is issued that can't be executed as a normal command, and the
# command is the name of a directory, perform the cd command to that directory.
setopt auto_cd
# in order to use #, ~ and ^ for filename generation grep word
# *~(*.gz|*.bz|*.bz2|*.zip|*.Z) -> searches for word not in compressed files
# don't forget to quote '^', '~' and '#'!
setopt extended_glob
# display PID when suspending processes as well
setopt longlistjobs
# report the status of backgrounds jobs immediately
setopt notify
# whenever a command completion is attempted, make sure the entire command path
# is hashed first.
setopt hash_list_all
# not just at the end
setopt completeinword
# Don't send SIGHUP to background processes when the shell exits.
setopt nohup
# make cd push the old directory onto the directory stack.
setopt auto_pushd
# avoid "beep"ing
setopt nobeep
# don't push the same dir twice.
setopt pushd_ignore_dups
# * shouldn't match dotfiles. ever.
setopt noglobdots
# use zsh style word splitting
setopt noshwordsplit
# don't error out when unset parameters are used
setopt unset

# Keybindings
source ~/.bindings.zsh
# Aliases
source ~/.aliases.zsh

# Add ~/.local/bin to $PATH
export PATH="$PATH:$HOME/.local/bin/"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if [ "$TERM_PROGRAM" != "vscode" ]; then
    pfetch
fi
