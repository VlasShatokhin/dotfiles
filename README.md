# dotfiles

> Lightspeed zsh — sub-50ms startup, equally fast for humans and AI coding agents.

A small, fast, modern zsh setup that's safe to drop onto a fresh machine *or* one that
already has a shell you care about.

## Features

- **Agent-aware** — non-TTY shells (Claude Code & friends) skip interactive-only modules and load a clean, deterministic environment
- **Fast** — tool init is cached to `~/.cache/zsh/init/`, so there are no per-shell process spawns
- **Auto dark/light prompt** — follows the macOS appearance (oh-my-posh), with an exit-code-aware `❯`
- **Modern tools** — eza, fd, bat, delta, zoxide, fzf (Ctrl-T file preview, Ctrl-R history), syntax highlighting, autosuggestions, prefix history search
- **Universal installer** — detects oh-my-zsh / powerlevel10k / starship / asdf (and nvm/pyenv/conda), keeps your existing prompt if you have one, and backs up anything it would replace

## Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/vlasshatokhin/dotfiles/main/install.sh)
```

Everything is opt-in and interactive — press Enter to accept defaults. Missing Homebrew is
offered for install. Want to look before you leap?

```bash
# review the script first
curl -fsSL https://raw.githubusercontent.com/vlasshatokhin/dotfiles/main/install.sh | less

# or preview exactly what it would change, without touching anything
bash <(curl -fsSL https://raw.githubusercontent.com/vlasshatokhin/dotfiles/main/install.sh) --dry-run
```

## What it installs (all opt-in)

`mise` · `fzf` · `zoxide` · `bat` · `eza` · `fd` · `delta` · `oh-my-posh` — chosen interactively,
via Homebrew.

## Existing setup

Already have a shell you like? The installer adapts:

- Detects **oh-my-zsh / powerlevel10k / starship** and keeps your existing prompt
- Flags **asdf / nvm / pyenv / conda** init so you can carry it into `~/.zshrc.local`
- Backs up any file it would replace to `~/.dotfiles-backup/<timestamp>/`

## Customize

```bash
# interactive shells: aliases, functions, prompt tweaks
~/.zshrc.local

# all shells incl. agents: PATH and env vars
~/.env.zsh
```

## Platforms

macOS first-class; Linux best-effort for agent shells. See [CLAUDE.md](CLAUDE.md) for module
load order, dependencies, and architecture.

## Forking

Change `SLUG` at the top of `install.sh` and the install URL above to point at your fork.
