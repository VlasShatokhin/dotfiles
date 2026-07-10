# Dotfiles

Universal zsh for interactive use and Claude Code agents. Numbered modules in `zsh/`, sourced by `~/.zshrc` in order.

## Modes

| Mode | Trigger | Behavior |
|------|---------|----------|
| Interactive | TTY | all modules, ~70ms |
| Agent | non-TTY / `CLAUDECODE=1` | TTY modules skipped (`[[ -t 1 ]]` guards), `.zprofile` early-return, `NO_COLOR=1`, ~20ms |

## Module load order

| Module | Scope | Does |
|--------|-------|------|
| 01-env | all | PATH, brew, editor, `_stale` helper, `NO_COLOR` for agents |
| 02-zinit | tty | oh-my-posh prompt (first - survives zinit failure), zinit bootstrap, turbo plugins, weekly auto-update |
| 03-completions | tty | compinit (`-C` fast path, full `-i` audit daily), fzf-tab styles |
| 04-history | tty | 50k shared history |
| 05-keybindings | tty | Option+arrow word nav, path-friendly `WORDCHARS`, Ctrl-X Ctrl-E edit in `$EDITOR` |
| 06-aliases | tty | eza/bat/git/nav aliases, `interactive_comments`, confirm-on-clobber |
| 07-tools | mixed | `_cached_init` (all), fzf + Ctrl-T preview (tty), snapshot cleanup |
| 99-zoxide | tty | smart cd - must be last |

## Prompt

- oh-my-posh, `ohmyposh/prompt.toml` (dark) / `prompt-light.toml` (light), transient prompt, exit-code-aware `❯`
- Appearance: `$DOTFILES_APPEARANCE` wins; else cached macOS detection with background refresh - a system toggle lands one shell later
- Left: SSH `user@host`, path, git (`*` dirty, `⇣⇡` behind/ahead), jobs `&N`
- Rprompt: `✗<code>` on failure, active python venv, exec time >5s
- Tooltips (typed-command context): kubectl, terraform, aws, go, java, python, docker, node
- Init runs live per shell (`eval`) - NEVER cache it: oh-my-posh v29 binds the theme to a per-invocation session id; a replayed cached init falls back to the default theme

## Invariants

- `_stale <file> <hours>` (01-env) is the only correct stamp check - `(#q...)` glob qualifiers silently never match without `extended_glob`, which is not set globally
- `_cached_init` (07-tools): atomic temp+rename write; only for tools whose init output is invocation-independent (fzf, zoxide - NOT oh-my-posh)
- Brew env cached by installer to `~/.cache/zsh/init/brew.zsh` (Apple Silicon + Intel)
- Agent shells get brew/PATH from Claude Code's shell snapshot; intentionally no `.zshenv`
- Brew init in both `.zprofile` and `01-env.zsh` - intentional (login vs subshell), both guarded
- zinit auto-update: weekly, background, log `~/.cache/zsh/init/zinit-update.log` keeps last run only
- Force cache regen: `rm ~/.cache/zsh/init/*`

## Dependencies

| Tool | Role |
|------|------|
| [oh-my-posh](https://github.com/JanDeDobbeleer/oh-my-posh) | prompt engine |
| [zinit](https://github.com/zdharma-continuum/zinit) | plugin manager, turbo-loads after prompt |
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | command coloring |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | inline history suggestions |
| [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search) | prefix + ↑/↓ history walk |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | fuzzy completion menu |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | extra completions |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | smart `cd` |
| [fzf](https://github.com/junegunn/fzf) | Ctrl-R history, Ctrl-T files with bat preview |
| [bat](https://github.com/sharkdp/bat) | `cat` alias (tty only) |
| [eza](https://github.com/eza-community/eza) | `l`/`lt` aliases (tty only) |
| [fd](https://github.com/sharkdp/fd) | backs fzf Ctrl-T |
| [delta](https://github.com/dandavison/delta) | git diff pager (set by installer) |

- OMZP `git` plugin: standard `g*` alias set; `06-aliases` adds personal extras only
- Installer git config (when unset): `core.fsmonitor`, `core.untrackedcache`, delta pager; large repos: `git maintenance start`

## Customization

| File | Scope |
|------|-------|
| `~/.zshrc.local` | interactive, sourced last |
| `~/.env.zsh` | all shells incl. agents, sourced early by 01-env |
| `DOTFILES_APPEARANCE=dark\|light` | force prompt palette |

## Adding modules

- Interactive-only: `[[ -t 1 ]] || return` at top
- Heavy/optional init: `zinit ice wait lucid; zinit light <plugin>`
- Stamp checks: use `_stale`, never inline `(#q...)` qualifiers

## Platforms

- macOS first-class; Linux best-effort (modules source cleanly; appearance detection, Option-key bindings, brew fallbacks are macOS-oriented)
- Docker test harness (Debian): installer logic + agent-shell load path

## Known issues

- oh-my-posh streaming mode breaks stderr (`_omp_start_streaming()` redirects FD2 to /dev/null) - keep streaming disabled
