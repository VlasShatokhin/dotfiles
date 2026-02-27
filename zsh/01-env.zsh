typeset -U path

# Fallback for interactive subshells (login shells get this from .zprofile)
[[ -z "$HOMEBREW_PREFIX" ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

export HOMEBREW_NO_ENV_HINTS=1
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-vim}"

[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

# User overrides (not in repo)
[[ -f ~/.env.zsh ]] && source ~/.env.zsh
