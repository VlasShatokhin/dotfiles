# Prompt + zinit plugin manager
# `zinit update` to update plugins, `zinit self-update` for zinit itself.
# Auto-update runs weekly (background, logged) - see bottom of file.
[[ -t 1 ]] || return

# Prompt — oh-my-posh. Independent of zinit: stays up even if plugin bootstrap fails.
if (( $+commands[oh-my-posh] )); then
    # Appearance: $DOTFILES_APPEARANCE wins; else cached macOS detection, refreshed in
    # the background - a system dark/light toggle lands one shell later. Keeps the
    # ~18ms `defaults read` off the startup path.
    local _omp_appearance="$DOTFILES_APPEARANCE"
    if [[ -z "$_omp_appearance" ]] && (( $+commands[defaults] )); then
        local _appearance_cache="$HOME/.cache/zsh/init/appearance"
        [[ -f "$_appearance_cache" ]] && _omp_appearance="$(<"$_appearance_cache")"
        if [[ -z "$_omp_appearance" ]]; then
            [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]] \
                && _omp_appearance=dark || _omp_appearance=light
            mkdir -p "${_appearance_cache:h}"
            print -r -- "$_omp_appearance" >| "$_appearance_cache"
        else
            ( [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]] \
                && print -r -- dark >| "$_appearance_cache" \
                || print -r -- light >| "$_appearance_cache" ) &>/dev/null &!
        fi
    fi
    [[ -z "$_omp_appearance" ]] && _omp_appearance=dark
    local _omp_config="$HOME/.config/ohmyposh/prompt.toml"
    if [[ "$_omp_appearance" == "light" && -f "$HOME/.config/ohmyposh/prompt-light.toml" ]]; then
        _omp_config="$HOME/.config/ohmyposh/prompt-light.toml"
    fi
    # Run init live per shell - do not cache it. oh-my-posh v29 binds the theme to a
    # per-invocation session id, so a replayed cached init resolves to the default theme.
    eval "$(oh-my-posh init zsh --config "$_omp_config")"
fi

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
# Offline or failed clone: skip plugins, keep the shell (and prompt) usable
[[ -r "$ZINIT_HOME/zinit.zsh" ]] || return
source "$ZINIT_HOME/zinit.zsh"

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

# Weekly auto-update (background; log keeps last run only)
if _stale "$ZINIT_HOME/.last_auto_update" 168; then
    mkdir -p "$HOME/.cache/zsh/init"
    ( zinit self-update && zinit update --parallel && touch "$ZINIT_HOME/.last_auto_update" ) \
        &>| "$HOME/.cache/zsh/init/zinit-update.log" &!
fi
