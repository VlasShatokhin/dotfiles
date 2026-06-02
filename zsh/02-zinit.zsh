# Zinit — plugin manager
# `zinit update` to update plugins, `zinit self-update` for zinit itself.
# Auto-update runs weekly (background, logged) - see bottom of file.
[[ -t 1 ]] || return

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

# Prompt — oh-my-posh. Appearance: $DOTFILES_APPEARANCE wins; else macOS dark/light; else dark.
if (( $+commands[oh-my-posh] )); then
    local _omp_appearance="${DOTFILES_APPEARANCE:-dark}"
    if [[ -z "$DOTFILES_APPEARANCE" ]] && (( $+commands[defaults] )); then
        [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]] || _omp_appearance="light"
    fi
    local _omp_config="$HOME/.config/ohmyposh/prompt.toml"
    if [[ "$_omp_appearance" == "light" ]] && [[ -f "$HOME/.config/ohmyposh/prompt-light.toml" ]]; then
        _omp_config="$HOME/.config/ohmyposh/prompt-light.toml"
    fi
    local _omp_cache="$HOME/.cache/zsh/init/oh-my-posh-${_omp_appearance}.zsh"
    # Per-appearance cache; `>` truncates and the -nt guard handles binary upgrades,
    # so dark and light caches coexist (no thrash when toggling appearance).
    if [[ ! -f "$_omp_cache" ]] || [[ "$(command -v oh-my-posh)" -nt "$_omp_cache" ]]; then
        mkdir -p "${_omp_cache:h}"
        oh-my-posh init zsh --config "$_omp_config" > "$_omp_cache"
    fi
    source "$_omp_cache"
fi

# Turbo — loads after prompt renders
zinit ice wait lucid; zinit light zsh-users/zsh-completions
zinit ice wait lucid; zinit light zsh-users/zsh-autosuggestions
zinit ice wait lucid; zinit light Aloxaf/fzf-tab
zinit ice wait lucid; zinit light zdharma-continuum/fast-syntax-highlighting
# Type a prefix, press Up/Down to walk matching history (binds once widgets exist)
zinit ice wait lucid atload'bindkey "^[[A" history-substring-search-up; bindkey "^[[B" history-substring-search-down; bindkey "^[OA" history-substring-search-up; bindkey "^[OB" history-substring-search-down'
zinit light zsh-users/zsh-history-substring-search
zinit ice wait lucid; zinit snippet OMZP::git
zinit ice wait lucid; zinit snippet OMZP::command-not-found

# Weekly auto-update (background, non-blocking)
local _zinit_update_stamp="$ZINIT_HOME/.last_auto_update"
if [[ ! -f "$_zinit_update_stamp" || -n "$_zinit_update_stamp"(#qN.md+7) ]]; then
    ( zinit self-update && zinit update --parallel && touch "$_zinit_update_stamp" ) &>> "$HOME/.cache/zsh/init/zinit-update.log" &!
fi

# Daily snapshot cleanup (keep 10 most recent)
local _snap_dir="$HOME/.claude/shell-snapshots"
local _snap_stamp="$_snap_dir/.last_cleanup"
if [[ -d "$_snap_dir" ]] && [[ ! -f "$_snap_stamp" || -n "$_snap_stamp"(#qN.md+1) ]]; then
    ( snaps=( "$_snap_dir"/snapshot-*.sh(Nom) ); (( ${#snaps} > 10 )) && rm -f "${(@)snaps[11,-1]}"; touch "$_snap_stamp" ) &!
fi
