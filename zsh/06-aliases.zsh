alias ..="cd .."
alias c="clear && exec zsh"
alias l="ls -lahFG"

if (( $+commands[bat] )); then
    alias cat="bat --paging=never"
    alias catp="bat --plain"
fi

alias g-="git checkout -"
alias g--="git checkout main && git pull"
alias gs="git status"
