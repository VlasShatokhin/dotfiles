# Tool init — cached to avoid process spawns. Only for tools whose init output is
# invocation-independent (not oh-my-posh: its theme binds to a per-invocation session id).
# Regenerate: rm ~/.cache/zsh/init/*

_cached_init() {
    local cmd="$1" args="$2"
    local cache="$HOME/.cache/zsh/init/${cmd}.zsh"
    if [[ ! -f "$cache" ]] || [[ "$(command -v "$cmd")" -nt "$cache" ]]; then
        mkdir -p "${cache:h}"
        # Write via temp + rename - concurrent shells must never source a torn cache
        "$cmd" $=args > "$cache.$$" 2>/dev/null \
            && command mv -f "$cache.$$" "$cache" \
            || { command rm -f "$cache.$$"; return 1 }
    fi
    source "$cache"
}

if [[ -t 1 ]] && (( $+commands[fzf] )); then
    _cached_init fzf "--zsh"
    # Preview files on Ctrl-T (no forced colors - terminal palette is honored)
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null || ls {}'"
    if (( $+commands[fd] )); then
        export FZF_DEFAULT_COMMAND="fd --type f --hidden --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# Daily cleanup of Claude Code shell snapshots (keep 10 newest)
if [[ -t 1 ]]; then
    local _snap_dir="$HOME/.claude/shell-snapshots"
    if [[ -d "$_snap_dir" ]] && _stale "$_snap_dir/.last_cleanup" 24; then
        ( snaps=( "$_snap_dir"/snapshot-*.sh(Nom) ); (( ${#snaps} > 10 )) && command rm -f "${(@)snaps[11,-1]}"; touch "$_snap_dir/.last_cleanup" ) &!
    fi
fi
