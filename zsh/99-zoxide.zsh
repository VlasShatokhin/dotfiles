# zoxide — smarter cd (must be the last shell integration to properly wrap cd)
if [[ -t 1 ]] && (( $+commands[zoxide] )); then
    _cached_init zoxide "init --cmd cd zsh"
fi
