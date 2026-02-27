# zoxide — smarter cd (must be the last shell integration to properly wrap cd)
[[ -t 1 ]] && eval "$(zoxide init --cmd cd zsh)"
