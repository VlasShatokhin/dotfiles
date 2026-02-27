# Key bindings
[[ -t 1 ]] || return

bindkey "^[[1;3C" forward-word      # Option+Right
bindkey "^[[1;3D" backward-word     # Option+Left
bindkey "^[^[[C" forward-word       # Alternative Option+Right
bindkey "^[^[[D" backward-word      # Alternative Option+Left
