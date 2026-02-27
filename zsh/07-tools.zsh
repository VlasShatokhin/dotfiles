(( $+commands[mise] )) && eval "$(mise activate zsh)"

[[ -t 1 ]] && eval "$(fzf --zsh)"
