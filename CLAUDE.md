# Dotfiles

Lightspeed zsh shell for interactive use and Claude Code agents.
Numbered modules in `zsh/`, sourced by `~/.zshrc` in order.

Two modes: interactive (TTY) loads everything; agent shells (~15ms) skip what they don't need. Modules use `[[ -t 1 ]]` guards, `.zprofile` uses `CLAUDECODE=1`.

## Dependencies

| Tool | Role |
|------|------|
| [oh-my-posh](https://github.com/JanDeDobbeleer/oh-my-posh) | Prompt engine (`zen.toml`). Transient prompt, contextual tooltips |
| [zinit](https://github.com/zdharma-continuum/zinit) | Plugin manager. Turbo-loads after prompt renders. Weekly auto-update |
| [zsh-defer](https://github.com/romkatv/zsh-defer) | Deferred sourcing. Heavy init runs after prompt (~200ms) |
| [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) | Command syntax coloring |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Inline history suggestions |
| [fzf-tab](https://github.com/Aloxaf/fzf-tab) | Fuzzy completion menu |
| [zsh-completions](https://github.com/zsh-users/zsh-completions) | Extra completions |
| [mise](https://github.com/jdx/mise) | Tool version manager. Active in all shells (agents need correct paths) |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart `cd` replacement |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder (Ctrl-R history, Ctrl-T files) |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting. Aliased as `cat`, guarded |

Git performance: `core.fsmonitor` + `core.untrackedcache` globally (background daemon instead of scanning).

## Module load order

Scope: **all** = every shell; **tty** = interactive only.

| Module           | Scope | What it does                                               |
|------------------|-------|------------------------------------------------------------|
| 01-env           | all   | PATH, brew, editor, user overrides (`~/.env.zsh`)          |
| 02-zinit         | tty   | plugin manager, prompt (oh-my-posh), zsh-defer             |
| 03-completions   | tty   | compinit (cached daily), fzf-tab config                    |
| 04-history       | tty   | 50k shared history                                         |
| 05-keybindings   | tty   | Option+arrow word navigation                               |
| 06-aliases       | all   | shell aliases, user overrides (`~/.aliases.zsh`, `~/.functions.zsh`) |
| 07-tools         | mixed | mise (all); fzf (tty)                                      |
| 99-zoxide        | tty   | smart cd (must be last)                                    |

## Adding config

- Env/PATH for agents: `01-env.zsh`
- Interactive-only: `[[ -t 1 ]] || return` at top
- Heavy init: `zsh-defer source <script>` (requires 02-zinit loaded)
- Brew exists in both `.zprofile` and `01-env.zsh` — intentional (login vs subshell), both guarded

## Known issues

- oh-my-posh streaming mode breaks stderr (`_omp_start_streaming()` redirects FD2 to /dev/null). Keep streaming disabled.
