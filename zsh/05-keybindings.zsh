# Key bindings
[[ -t 1 ]] || return

bindkey "^[[1;3C" forward-word      # Option+Right
bindkey "^[[1;3D" backward-word     # Option+Left
bindkey "^[^[[C" forward-word       # Alternative Option+Right
bindkey "^[^[[D" backward-word      # Alternative Option+Left

# Ctrl-X Ctrl-E — edit the current command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M emacs "^X^E" edit-command-line
bindkey -M viins "^X^E" edit-command-line
bindkey -M vicmd "^X^E" edit-command-line
