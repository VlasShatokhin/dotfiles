# dotfiles

> Lightspeed zsh — sub-50ms startup, equally fast for humans and AI agents.

## Features

- Agent-aware — non-TTY shells skip interactive-only modules
- Cached tool init (`~/.cache/zsh/init/`) — no per-shell process spawns
- Auto dark/light prompt (oh-my-posh), exit-code-aware `❯`
- eza · fd · bat · delta · zoxide · fzf (Ctrl-T preview, Ctrl-R history)
- Syntax highlighting · autosuggestions · prefix history search
- Universal installer — detects oh-my-zsh / p10k / starship / asdf / nvm / pyenv / conda, keeps the existing prompt, backs up what it replaces

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/vlasshatokhin/dotfiles/main/install.sh)
```

Interactive, opt-in. `--dry-run` previews without changes. Missing Homebrew is offered for install.

## Installs (opt-in, via Homebrew)

`fzf` · `zoxide` · `bat` · `eza` · `fd` · `delta` · `oh-my-posh`

## Existing setup

- Keeps oh-my-zsh / powerlevel10k / starship prompts
- Flags asdf / nvm / pyenv / conda init for `~/.zshrc.local`
- Backs up replaced files to `~/.dotfiles-backup/<timestamp>/`

## Customize

- `~/.zshrc.local` — interactive: aliases, functions, prompt tweaks
- `~/.env.zsh` — all shells incl. agents: PATH, env vars

## Platforms

macOS first-class; Linux best-effort for agent shells. Architecture → [CLAUDE.md](CLAUDE.md).

## Fork

Change `SLUG` in `install.sh` and the install URL above.
