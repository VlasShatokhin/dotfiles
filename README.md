# dotfiles

Lightspeed zsh shell for interactive use and Claude Code agents.

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/vlasshatokhin/dotfiles/main/install.sh)
```

Requires [Homebrew](https://brew.sh).

## User overrides (not in repo)

| File | Sourced by | Purpose |
|------|-----------|---------|
| `~/.env.zsh` | 01-env | Custom env vars, PATH, editor |
| `~/.aliases.zsh` | 06-aliases | Custom aliases |
| `~/.functions.zsh` | 06-aliases | Custom functions |

## Structure

See [CLAUDE.md](CLAUDE.md) for module load order and dependencies.
