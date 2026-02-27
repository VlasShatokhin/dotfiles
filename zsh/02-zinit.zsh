# Zinit — plugin manager
# `zinit update` to update plugins, `zinit self-update` for zinit itself.
# Auto-update runs weekly (deferred, silent) — see bottom of file.
[[ -t 1 ]] || return

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

# Synchronous — must be available before later modules (08-work uses it)
zinit light romkatv/zsh-defer

# Prompt — oh-my-posh (cached init)
if (( $+commands[oh-my-posh] )); then
    # Cached init + native zsh timing
    zmodload zsh/datetime
    local _omp_cache="$HOME/.cache/zsh/init/oh-my-posh.zsh"
    if [[ ! -f "$_omp_cache" ]] || [[ "$(command -v oh-my-posh)" -nt "$_omp_cache" ]]; then
        mkdir -p "${_omp_cache:h}"
        oh-my-posh init zsh --config "$HOME/.config/ohmyposh/zen.toml" > "$_omp_cache"
        local _omp_real=("$HOME"/.cache/oh-my-posh/init.*.zsh(N))
        if [[ ${#_omp_real[@]} -gt 0 ]]; then
            sed -i '' 's#\$(\$_omp_executable get millis)#$(( ${EPOCHREALTIME/\%.*} * 1000 + ${${EPOCHREALTIME\#*.}[1,3]} ))#g' "${_omp_real[1]}"
        fi
    fi
    source "$_omp_cache"
fi

# Turbo — loads after prompt renders
zinit ice wait lucid; zinit light zsh-users/zsh-completions
zinit ice wait lucid; zinit light zsh-users/zsh-autosuggestions
zinit ice wait lucid; zinit light Aloxaf/fzf-tab
zinit ice wait lucid; zinit light zdharma-continuum/fast-syntax-highlighting
zinit ice wait lucid; zinit snippet OMZP::git
zinit ice wait lucid; zinit snippet OMZP::command-not-found

# Weekly auto-update (background, non-blocking)
local _zinit_update_stamp="$ZINIT_HOME/.last_auto_update"
if [[ ! -f "$_zinit_update_stamp" || -n "$_zinit_update_stamp"(#qN.md+7) ]]; then
    ( zinit self-update &>/dev/null; zinit update --parallel &>/dev/null; touch "$_zinit_update_stamp" ) &!
fi

# Daily snapshot cleanup (keep 10 most recent)
local _snap_dir="$HOME/.claude/shell-snapshots"
local _snap_stamp="$_snap_dir/.last_cleanup"
if [[ -d "$_snap_dir" ]] && [[ ! -f "$_snap_stamp" || -n "$_snap_stamp"(#qN.md+1) ]]; then
    ( cd "$_snap_dir" && ls -t snapshot-*.sh 2>/dev/null | tail -n +11 | xargs rm -f; touch "$_snap_stamp" ) &!
fi
