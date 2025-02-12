# If not running interactively, don't do anything
[[ $- != *i* ]] && return


# Enable colors and change prompt:
autoload -U colors && colors

# History in cache directory:
HISTSIZE=1000
SAVEHIST=$HISTSIZE
HISTFILE=~/.cache/zsh/history
HISTDUP=erase

# Basic auto/tab complete:
autoload -U compinit && compinit
#zstyle ':completion:*' menu select
# Auto complete with case insenstivity
#zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# Auto complete color
#zstyle ':completion:*:default' list-colors \
#  "di=1;36" "ln=35" "so=32" "pi=33" "ex=31" "bd=34;46" "cd=34;43" \
#  "su=30;41" "sg=30;46" "tw=30;42" "ow=30;43"
# Add description to auto completions
#zstyle ':completion:*:descriptions'    format $'%{\e[0;31m%}completing %B%d%b%{\e[0m%}'
# Ignore duplicate entries
#zstyle ':completion:*:history-words'   remove-all-dups yes
#zstyle ':completion:*:history-words'   stop yes

zstyle ':completion:*' menu no
# Auto complete with case insenstivity
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# Auto complete color
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# Add directory preview for cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 -hg --color=always --group-directories-first --icons $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 -hg --color=always --group-directories-first --icons $realpath'

zmodload zsh/complist

# Enable searching through history
bindkey '^R' history-incremental-pattern-search-backward
# Enable moving by word with ctrl + arrow keys
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Options

# ignore duplicates in history
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
# save each command's beginning timestamp and the duration to the history file
setopt extended_history
# remove command lines from the history list when the first character on the
# line is a space
setopt hist_ignore_space
# share history between all sessions
setopt sharehistory
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
# Add local yarn packages to $PATH
export PATH="$PATH:$HOME/.yarn/bin/"
# Add local cargo packages to $PATH
export PATH="$PATH:$HOME/.local/share/cargo/bin"

# Plugins
source /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source /usr/share/zsh/plugins/zsh-fzf-plugin/fzf.plugin.zsh
source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.plugin.zsh

# Shell integrations

# Zoxide
eval "$(zoxide init zsh)"
# Oh my posh
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"

if [ "$TERM_PROGRAM" != "vscode" ]; then
    pfetch
fi

# bun completions
[ -s "/home/nico/.bun/_bun" ] && source "/home/nico/.bun/_bun"

# Bun
export BUN_INSTALL="/home/nico/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


# Use beam shape cursor on startup.
echo -ne '\e[5 q'

# Use beam shape cursor for each new prompt.
preexec() { echo -ne '\e[5 q' ;}

# pnpm
export PNPM_HOME="/home/nico/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
