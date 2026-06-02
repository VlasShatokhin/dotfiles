# Dotfiles

Lightspeed zsh shell for interactive use and Claude Code agents.
Numbered modules in `zsh/`, sourced by `~/.zshrc` in order.

Two modes: interactive (TTY) loads everything; agent shells skip the TTY-only modules and start faster - both well under 50ms. Modules guard with `[[ -t 1 ]]`; `.zprofile` early-returns on `CLAUDECODE=1`.

## Dependencies

| Tool | Role |
|------|------|
| [oh-my-posh](https://github.com/JanDeDobbeleer/oh-my-posh) | Prompt engine. Auto-selects `prompt.toml`/`prompt-light.toml` from macOS appearance (`AppleInterfaceStyle`; defaults to dark elsewhere, override with `$DOTFILES_APPEARANCE`). Transient prompt, exit-code-aware `❯`, contextual tooltips |
| [zinit](https://github.com/zdharma-continuum/zinit) | Plugin manager. Turbo-loads plugins after the prompt renders. Weekly auto-update (background, logged to `~/.cache/zsh/init/zinit-update.log`) |
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | Command syntax coloring |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Inline history suggestions |
| [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | Type a prefix, ↑/↓ walks matching history |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | Fuzzy completion menu |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | Extra completions |
| [mise](https://github.com/jdx/mise) | Tool version manager. Active in all shells (agents need correct paths) |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart `cd` replacement |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder (Ctrl-R history, Ctrl-T files with bat preview) |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting. Aliased as `cat` (interactive only) |
| [eza](https://github.com/eza-community/eza) | Modern `ls`. Aliased as `l`/`lt` (interactive only) |
| [fd](https://github.com/sharkdp/fd) | Fast `find`; backs fzf's Ctrl-T file search |
| [delta](https://github.com/dandavison/delta) | Syntax-highlighted git diffs (configured by the installer) |

The OMZP `git` plugin (turbo-loaded) provides the standard `g`/`gst`/`gco`/`gd`/… alias set in interactive shells; `06-aliases.zsh` adds only a few personal extras.

Git config (set by the installer, only when unset): `core.fsmonitor` + `core.untrackedcache` (background daemon instead of scanning) and `delta` as the diff pager. For large repos, enable `git maintenance start` per-repo.

## Module load order

Scope: **all** = every shell; **tty** = interactive only.

| Module           | Scope | What it does                                               |
|------------------|-------|------------------------------------------------------------|
| 01-env           | all   | PATH, brew, editor, `NO_COLOR` for agents                  |
| 02-zinit         | tty   | plugin manager, prompt (oh-my-posh), turbo plugins         |
| 03-completions   | tty   | compinit (cached daily), fzf-tab config                    |
| 04-history       | tty   | 50k shared history                                         |
| 05-keybindings   | tty   | Option+arrow word nav, Ctrl-X Ctrl-E edits line in $EDITOR |
| 06-aliases       | tty   | interactive aliases (eza, bat, git, nav, confirm-on-clobber) |
| 07-tools         | mixed | mise (all); fzf + Ctrl-T preview (tty). Cached init in `~/.cache/zsh/init/` |
| 99-zoxide        | tty   | smart cd (must be last)                                    |

Aliases are interactive-only by design: agents issue full commands, so `06-aliases` (and the `cat`→bat alias) never load in non-TTY shells.

## Performance

Tool init scripts (brew, oh-my-posh, mise, fzf, zoxide) are cached to `~/.cache/zsh/init/` — avoids ~78ms of process spawns per shell. Caches auto-regenerate when the binary changes. To force: `rm ~/.cache/zsh/init/*`.

Homebrew env is detected once by the installer and cached to `~/.cache/zsh/init/brew.zsh` — works on both Apple Silicon and Intel Macs (~41ms saved vs `eval "$(brew shellenv)"`).

Agent shells get brew/mise/PATH from Claude Code's shell snapshot (replayed from a full shell run). There is intentionally no `.zshenv`; a bare `zsh -c` with no snapshot and no prior interactive shell has no brew/mise. Regenerate via any interactive shell if a snapshot goes stale.

## Customization

User config goes in `~/.zshrc.local` — sourced last (interactive shells). One file for everything: aliases, functions, env vars, secrets.

For env vars that agent (non-TTY) shells also need (PATH, tool config): use `~/.env.zsh` — sourced early by `01-env.zsh` in all shells.

Force prompt appearance regardless of OS setting: `export DOTFILES_APPEARANCE=dark` (or `light`) in `~/.zshrc.local`.

## Adding modules

- Interactive-only: `[[ -t 1 ]] || return` at top
- Heavy/optional init: turbo-load via `zinit ice wait lucid; zinit light <plugin>` (loads after the prompt renders)
- Brew exists in both `.zprofile` and `01-env.zsh` — intentional (login vs subshell), both guarded

## Platforms

macOS is first-class. Linux is best-effort for agent (non-TTY) shells — modules source cleanly, but prompt appearance detection, Option-key bindings, and brew-prefix fallbacks are macOS-oriented. The Docker test harness (Debian) exercises installer logic and the agent-shell load path.

## Known issues

- oh-my-posh streaming mode breaks stderr (`_omp_start_streaming()` redirects FD2 to /dev/null). Keep streaming disabled.
