# Tool init — cached to avoid process spawns
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

if [[ -t 1 ]] && (( $+commands[fzf] )); then
    _cached_init fzf "--zsh"
    # Preview files on Ctrl-T (no forced colors - terminal palette is honored)
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null || ls {}'"
    if (( $+commands[fd] )); then
        export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi
