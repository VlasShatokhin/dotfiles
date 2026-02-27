alias ..="cd .."
alias c="clear && source ~/.zshrc"
alias l="ls -lahFG"

if (( $+commands[bat] )); then
    alias cat="bat --paging=never"
    alias catp="bat --plain"
fi

alias g-="git checkout -"
alias g--="git checkout main && git pull"
alias gs="git status"

# User overrides (not in repo)
[[ -f ~/.aliases.zsh ]] && source ~/.aliases.zsh
[[ -f ~/.functions.zsh ]] && source ~/.functions.zsh
