# Interactive aliases - agents use full commands, so this module is tty-only
[[ -t 1 ]] || return

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

alias c="clear && exec zsh"

if (( $+commands[eza] )); then
    alias l="eza -lah --git --group-directories-first"
    alias lt="eza --tree --level=2 --group-directories-first"
else
    alias l="ls -lahF --color=auto"
fi

if (( $+commands[bat] )); then
    alias cat="bat --paging=never"
    alias catp="bat --plain"
fi

# Confirm before clobbering
alias rm="rm -i"
alias cp="cp -i"
alias mv="mv -i"

# Personal git shortcuts (full g* set comes from OMZP::git)
alias g-="git checkout -"
alias g--="git checkout main && git pull"
alias gs="git status"
