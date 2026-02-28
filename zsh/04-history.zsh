# Shell history
[[ -t 1 ]] || return

HISTSIZE=50000
HISTFILE="${HISTFILE:-$HOME/.zsh_history}"
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups
