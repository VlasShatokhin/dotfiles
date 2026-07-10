if [[ ! -t 1 ]]; then
    compdef() { }  # stub so downstream modules don't break
    return
fi

autoload -Uz compinit
# Full compinit (with audit) once per day; -C trusts the dump otherwise
if _stale ~/.zcompdump 24; then compinit -i; else compinit -C; fi
(( $+functions[zinit] )) && zinit cdreplay -q

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
