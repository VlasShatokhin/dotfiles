# dotfiles

> Fast universal zsh - one config for humans and AI agents.

## Features

- Interactive: oh-my-posh prompt, syntax highlighting, autosuggestions, fzf-tab, prefix history search
- Agent shells (non-TTY): skip interactive modules, `NO_COLOR`, ~20ms startup
- Auto dark/light prompt from macOS appearance (cached, background-refreshed)
- Prompt statuses: git, exit code, python venv, SSH host, exec time, contextual tooltips
- Cached tool init in `~/.cache/zsh/init/` - fzf, zoxide, brew
- eza · fd · bat · delta · zoxide · fzf (Ctrl-T preview, Ctrl-R history)
- Universal installer - detects oh-my-zsh / p10k / starship / asdf / nvm / pyenv / conda, keeps the existing prompt, backs up what it replaces

## Install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/vlasshatokhin/dotfiles/main/install.sh)"
```

Preview without changes:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/vlasshatokhin/dotfiles/main/install.sh)" -- --dry-run
```

Opt-in via Homebrew: `fzf` · `zoxide` · `bat` · `eza` · `fd` · `delta` · `oh-my-posh`

## Existing setup

- Keeps oh-my-zsh / powerlevel10k / starship prompts
- Flags asdf / nvm / pyenv / conda init for `~/.zshrc.local`
- Backs up replaced files to `~/.dotfiles-backup/<timestamp>/`

## Customize

| File | Scope |
|------|-------|
| `~/.zshrc.local` | interactive shells - aliases, functions, secrets |
| `~/.env.zsh` | all shells incl. agents - PATH, env vars |
| `DOTFILES_APPEARANCE=dark\|light` | force prompt palette |

## Platforms

- macOS first-class; Linux best-effort for agent shells
- Architecture: [CLAUDE.md](CLAUDE.md)

## Fork

- Change `SLUG` in `install.sh` and the install URL above
