# Claude Code agent shells get env from snapshots — skip redundant work
[[ -n "$CLAUDECODE" ]] && return

eval "$(/opt/homebrew/bin/brew shellenv)"

