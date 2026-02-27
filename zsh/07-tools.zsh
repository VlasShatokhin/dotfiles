# Tool init — cached to avoid process spawns (~25ms saved)
# Regenerate: rm ~/.cache/zsh/init/*

_cached_init() {
    local cmd="$1" args="$2"
    local cache="$HOME/.cache/zsh/init/${cmd}.zsh"
    if [[ ! -f "$cache" ]] || [[ "$(command -v "$cmd")" -nt "$cache" ]]; then
        mkdir -p "${cache:h}"
        "$cmd" $=args > "$cache" 2>/dev/null || return
    fi
    source "$cache"
}

(( $+commands[mise] )) && _cached_init mise "activate zsh"
[[ -t 1 ]] && (( $+commands[fzf] )) && _cached_init fzf "--zsh"
