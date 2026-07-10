#!/bin/bash
set -eo pipefail

# =============================================================================
# Config
# =============================================================================

# Forking? Change SLUG (and the install URL in README.md).
SLUG="vlasshatokhin/dotfiles"
REPO="https://github.com/$SLUG.git"
DOTFILES="$HOME/dotfiles"
DOTFILES_FALLBACK="$HOME/.dotfiles"   # used when ~/dotfiles is taken by another repo
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# True when the dir at $1 is a checkout of our repo (origin matches SLUG, any casing)
_is_our_repo() {
    [[ -d "$1/.git" ]] && [[ "$(git -C "$1" remote get-url origin 2>/dev/null | tr '[:upper:]' '[:lower:]')" == *"$SLUG"* ]]
}

# =============================================================================
# UI helpers
# =============================================================================

# Colors — reuse prompt.toml palette where possible
bold='\033[1m'
yellow='\033[33m'
green='\033[38;2;123;155;142m'  # #7B9B8E — prompt path green
grey='\033[38;2;85;85;85m'      # #555555 — prompt transient grey
reset='\033[0m'

ask() {
    local prompt="$1" default="$2" reply
    printf "%b%s%b " "$bold" "$prompt" "$reset"
    read -r reply
    reply="${reply:-$default}"
    [[ "${reply:0:1}" =~ ^[Yy]$ ]]
}

info()  { echo -e "  ${grey}$1${reset}"; }
log()   { echo -e "  ${grey}$1${reset}"; }
ok()    { echo -e "  ${green}+ $1${reset}"; }
skip()  { echo -e "  ${grey}- $1${reset}"; }
node()  { echo -e "    ${green}$1${reset}"; }

streak() {
    echo ""
    local t=""
    for d in .06 .06 .05 .05 .04 .04 .03 .03 .03 .025 .025 .02 .02 .02 .015 .015 .015 .01 .01 .01 .01 .008 .008 .008 .008 .006 .006 .006 .006 .006 .005 .005 .005 .005 .005 .005 .004 .004 .004 .004; do
        t="${t}─"
        printf "\r  ${green}${t}${bold}❯${reset}"
        sleep "$d"
    done
    sleep .15
    printf "\r  ${green}${t} ${green}${bold}✔${reset} ${1:-}\n"
}

# =============================================================================
# Phase 1: Detect existing setup
# =============================================================================

detect() {
    if [[ "$(id -u)" -eq 0 ]]; then
        echo -e "${yellow}Do not run as root/sudo.${reset}"
        echo "Run directly: bash install.sh"
        exit 1
    fi

    if ! command -v brew &>/dev/null; then
        echo -e "${yellow}Homebrew not found.${reset}"
        if ask "Install Homebrew now? [Y/n]" "Y"; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            # Load brew into this session (Apple Silicon or Intel)
            if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -x /usr/local/bin/brew ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi
        fi
        if ! command -v brew &>/dev/null; then
            echo -e "${yellow}Homebrew still unavailable - install it, then re-run: https://brew.sh${reset}"
            exit 1
        fi
    fi

    warnings=()
    prompt_default="Y"

    if [[ -f "$HOME/.zshenv" ]]; then
        warnings+=("  .zshenv found — it runs before our config and may conflict")
    fi

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        warnings+=("  oh-my-zsh detected — this replaces it with zinit (lighter, faster)")
        warnings+=("  ~/.oh-my-zsh/ will remain on disk — safe to remove after install")
    fi

    if [[ -f "$HOME/.p10k.zsh" ]] || [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
        warnings+=("  powerlevel10k detected — keeping your existing prompt")
        prompt_default="N"
    fi

    if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" ]]; then
        warnings+=("  starship detected — keeping your existing prompt")
        prompt_default="N"
    fi

    if [[ -d "$HOME/.asdf" ]] || command -v asdf &>/dev/null; then
        warnings+=("  asdf detected — mise replaces it; both can conflict on PATH")
    fi

    # Tool init in the user's live shell config that our setup won't carry over
    local _live_tools=""
    _scan_tool() { if grep -qE "$2" "$HOME/.zshrc" "$HOME/.zshenv" 2>/dev/null; then _live_tools+="$1 "; fi; }
    _scan_tool nvm   'NVM_DIR|nvm\.sh'
    _scan_tool pyenv 'PYENV_ROOT|pyenv init'
    _scan_tool conda '__conda_setup|conda\.sh|conda activate'
    _scan_tool rbenv 'RBENV_ROOT|rbenv init'
    if [[ -n "$_live_tools" ]]; then
        warnings+=("  ${_live_tools% } init found in your shell config — back up, then re-add to ~/.zshrc.local")
    fi

    existing=()
    _is_ours() {
        [[ -L "$1" ]] && [[ "$(readlink "$1")" == "$DOTFILES/"* || "$(readlink "$1")" == "$DOTFILES_FALLBACK/"* ]]
    }
    for f in .zshrc .zprofile .hushlogin \
             .config/ohmyposh/prompt.toml .config/ohmyposh/prompt-light.toml; do
        if [[ -e "$HOME/$f" || -L "$HOME/$f" ]]; then
            _is_ours "$HOME/$f" && continue
            existing+=("$f")
        fi
    done

    if [[ ${#existing[@]} -gt 0 ]]; then
        warnings+=("  existing configs will be backed up: ${existing[*]}")
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo -e "${yellow}Detected:${reset}"
        for w in "${warnings[@]}"; do
            echo -e "${yellow}$w${reset}"
        done
        echo ""
    fi
}

# =============================================================================
# Phase 2: Interactive choices
# =============================================================================

choose() {
    echo -e "${grey}Press Enter to accept defaults${reset}"

    # Tools
    echo ""
    echo -e "${bold}Install dev tools?${reset}"
    info "fzf — fuzzy finder"
    info "zoxide — smart cd"
    info "bat — cat with syntax highlighting"
    info "eza — modern ls"
    info "fd — fast find / fzf backend"
    info "delta — syntax-highlighted git diffs"
    ask "[Y/n]" "Y" && opt_tools=1 || opt_tools=0

    # Prompt
    echo ""
    echo -e "${bold}Install prompt theme?${reset}"
    info "oh-my-posh — transient prompt, git status, contextual tooltips"
    echo ""
    echo -e "  \033[1;38;2;123;155;142m~/projects/myapp\033[0m \033[90mmain *\033[0m"
    echo -e "  \033[38;2;204;204;204m❯\033[0m git commit -m \"feat: add auth\"                 \033[90m12.4s\033[0m"
    echo -e "  \033[90m❯\033[0m \033[90m(previous commands collapse to this)\033[0m"
    echo ""
    if [[ "$prompt_default" == "Y" ]]; then
        ask "[Y/n]" "Y" && opt_prompt=1 || opt_prompt=0
    else
        ask "[y/N]" "N" && opt_prompt=1 || opt_prompt=0
    fi

    # Git config
    echo ""
    echo -e "${bold}Configure git?${reset}"
    info "fsmonitor + untrackedcache — background daemon instead of scanning"
    info "delta — syntax-highlighted diffs (only if delta is installed)"
    ask "[Y/n]" "Y" && opt_git=1 || opt_git=0
}

# =============================================================================
# Phase 3: Summary + confirm
# =============================================================================

summarize() {
    echo ""
    echo -e "${bold}Summary${reset}"

    ok  "Clone dotfiles to $DOTFILES"
    ok  "Symlink .zshrc, .zprofile, .hushlogin"

    [[ $opt_tools  -eq 1 ]] && ok "Install fzf, zoxide, bat, eza, fd, delta" || skip "Skip dev tools"
    [[ $opt_prompt -eq 1 ]] && ok "Install oh-my-posh + prompt theme" || skip "Skip prompt (keep existing)"
    [[ $opt_git    -eq 1 ]] && ok "Configure git (fsmonitor, untrackedcache, delta)" || skip "Skip git config"

    [[ ${#existing[@]} -gt 0 ]] && ok "Back up existing configs to $BACKUP"
    echo ""

    ask "Proceed? [y/N]" "N" || exit 0
}

# =============================================================================
# Phase 4: Execute
# =============================================================================

execute() {
    echo ""

    # Generate brew env cache (detected once, sourced forever — avoids ~41ms per shell)
    local brew_prefix
    brew_prefix="$(brew --prefix)"
    local brew_cache="$HOME/.cache/zsh/init/brew.zsh"
    mkdir -p "$(dirname "$brew_cache")"
    cat > "$brew_cache" <<BREW
export HOMEBREW_PREFIX="$brew_prefix"
export HOMEBREW_CELLAR="$brew_prefix/Cellar"
export HOMEBREW_REPOSITORY="$brew_prefix"
export PATH="$brew_prefix/bin:$brew_prefix/sbin:\$PATH"
export MANPATH="$brew_prefix/share/man:\${MANPATH:-}"
export INFOPATH="$brew_prefix/share/info:\${INFOPATH:-}"
fpath=($brew_prefix/share/zsh/site-functions \$fpath)
BREW
    log "Detected Homebrew at $brew_prefix"

    # DOTFILES path already resolved by resolve_dotfiles (in main)
    if _is_our_repo "$DOTFILES"; then
        log "Updating dotfiles..."
        git -C "$DOTFILES" pull --ff-only || echo -e "  ${yellow}Could not fast-forward $DOTFILES (local changes or diverged branch) - using existing checkout${reset}"
    else
        log "Cloning dotfiles..."
        git clone "$REPO" "$DOTFILES"
    fi

    # Brew packages — show errors, don't silently swallow
    if [[ $opt_tools -eq 1 ]]; then
        log "Installing dev tools..."
        brew install fzf zoxide bat eza fd delta || echo -e "  ${yellow}Some packages failed — you can retry with: brew install fzf zoxide bat eza fd delta${reset}"
    fi

    if [[ $opt_prompt -eq 1 ]]; then
        log "Installing oh-my-posh..."
        brew install oh-my-posh || echo -e "  ${yellow}Failed — retry with: brew install oh-my-posh${reset}"
    fi

    # Backup existing configs (skip symlinks — those are ours)
    if [[ ${#existing[@]} -gt 0 ]]; then
        mkdir -p "$BACKUP"
        for f in "${existing[@]}"; do
            mkdir -p "$BACKUP/$(dirname "$f")"
            mv "$HOME/$f" "$BACKUP/$f"
        done
        log "Backed up existing configs to $BACKUP"
    fi

    # Symlinks
    ln -sf "$DOTFILES/.zshrc" ~/.zshrc
    ln -sf "$DOTFILES/.zprofile" ~/.zprofile
    ln -sf "$DOTFILES/.hushlogin" ~/.hushlogin

    if [[ $opt_prompt -eq 1 ]]; then
        mkdir -p ~/.config/ohmyposh
        ln -sf "$DOTFILES/ohmyposh/prompt.toml" ~/.config/ohmyposh/prompt.toml
        ln -sf "$DOTFILES/ohmyposh/prompt-light.toml" ~/.config/ohmyposh/prompt-light.toml
    fi

    # Git config — only set what isn't already configured (respects existing setups)
    if [[ $opt_git -eq 1 ]]; then
        log "Configuring git..."
        [[ -z "$(git config --global core.fsmonitor)" ]] && git config --global core.fsmonitor true
        [[ -z "$(git config --global core.untrackedcache)" ]] && git config --global core.untrackedcache true
        if command -v delta &>/dev/null && [[ -z "$(git config --global core.pager)" ]]; then
            git config --global core.pager delta
            git config --global interactive.diffFilter "delta --color-only"
            git config --global delta.navigate true
            git config --global delta.line-numbers true
            git config --global delta.side-by-side true
        fi
    fi

    streak
    echo ""
    if [[ ${#existing[@]} -gt 0 ]]; then
        info "Backed up to $BACKUP:"
        for f in "${existing[@]}"; do
            info "  $f"
        done
        # Warn if backed up files contained tool init blocks
        local found_tools=()
        for f in "${existing[@]}"; do
            local bf="$BACKUP/$f"
            [[ -f "$bf" ]] || continue
            grep -q 'conda init\|conda activate\|__conda_setup' "$bf" 2>/dev/null && found_tools+=("conda")
            grep -q 'nvm.sh\|NVM_DIR' "$bf" 2>/dev/null && found_tools+=("nvm")
            grep -q 'pyenv init\|PYENV_ROOT' "$bf" 2>/dev/null && found_tools+=("pyenv")
            grep -q 'rbenv init\|RBENV_ROOT' "$bf" 2>/dev/null && found_tools+=("rbenv")
            grep -q 'asdf.sh\|ASDF_DIR' "$bf" 2>/dev/null && found_tools+=("asdf")
        done
        if [[ ${#found_tools[@]} -gt 0 ]]; then
            echo ""
            info "Your backup contains ${found_tools[*]} init blocks."
            info "Add them to ~/.zshrc.local to keep using these tools."
        fi
    fi
    info "Open a new tab to load the new config"
    echo ""
    info "Personal config can be added to ~/.zshrc.local"
}

# =============================================================================
# Phase 5: Dry-run preview
# =============================================================================

preview() {
    local df="${DOTFILES/#$HOME/~}"   # home-relative display of the resolved repo path
    echo ""
    info "File tree (dry run — no changes made)"
    echo ""

    node "~/"
    node "├── .zshrc → $df/.zshrc"
    node "├── .zprofile → $df/.zprofile"
    node "├── .hushlogin → $df/.hushlogin"

    if [[ $opt_prompt -eq 1 ]]; then
        node "├── .config/"
        node "│   └── ohmyposh/"
        node "│       ├── prompt.toml → $df/ohmyposh/prompt.toml"
        node "│       └── prompt-light.toml → $df/ohmyposh/prompt-light.toml"
    fi

    if [[ ${#existing[@]} -gt 0 ]]; then
        local last="${existing[${#existing[@]}-1]}"
        node "├── ${BACKUP#"$HOME"/}/"
        for f in "${existing[@]}"; do
            if [[ "$f" == "$last" ]]; then
                node "│   └── $f (backed up)"
            else
                node "│   ├── $f (backed up)"
            fi
        done
    fi

    echo ""
    info "Always written"
    node "  ~/.cache/zsh/init/brew.zsh (regenerated)"

    if [[ $opt_tools -eq 1 ]] || [[ $opt_prompt -eq 1 ]]; then
        echo ""
        info "Brew packages"
        [[ $opt_tools  -eq 1 ]] && node "  fzf, zoxide, bat, eza, fd, delta"
        [[ $opt_prompt -eq 1 ]] && node "  oh-my-posh"
    fi

    if [[ $opt_git -eq 1 ]]; then
        echo ""
        info "Git config (global)"
        [[ -n "$(git config --global core.fsmonitor)" ]] && node "  core.fsmonitor (already set, skipping)" || node "  core.fsmonitor = true"
        [[ -n "$(git config --global core.untrackedcache)" ]] && node "  core.untrackedcache (already set, skipping)" || node "  core.untrackedcache = true"
        if command -v delta &>/dev/null; then
            [[ -n "$(git config --global core.pager)" ]] && node "  core.pager (already set, skipping delta)" || node "  core.pager = delta (+ navigate, line-numbers, side-by-side)"
        fi
    fi

    streak
    echo ""
    info "Run without --dry-run to apply, then open a new tab"
}

# =============================================================================
# Resolve repo location (fall back to ~/.dotfiles when ~/dotfiles is foreign)
# =============================================================================

resolve_dotfiles() {
    if [[ -d "$DOTFILES" ]] && ! _is_our_repo "$DOTFILES"; then
        if [[ -e "$DOTFILES_FALLBACK" ]] && ! _is_our_repo "$DOTFILES_FALLBACK"; then
            echo -e "  ${yellow}Both ~/dotfiles and ~/.dotfiles already exist and aren't ours.${reset}"
            echo -e "  ${yellow}Move or remove one, then re-run.${reset}"
            exit 1
        fi
        DOTFILES="$DOTFILES_FALLBACK"
    fi
}

# =============================================================================
# Main — wrapped in a function and called on the last line, so a partial
# download (truncated mid-stream) never executes: bash parses the whole string
# before main() is reached, and a cut-off script never reaches the call.
# =============================================================================

main() {
    local DRY_RUN=0
    [[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

    # Prompts read from the terminal. `bash <(curl ...)` already provides one; a bare
    # `curl | bash` puts the script itself on stdin, so reattach to the terminal when we
    # can (else the prompts get answered by the script's own lines). With no terminal at
    # all (CI, piped answers), fall through and read whatever is on stdin.
    [[ ! -t 0 ]] && { : </dev/tty; } 2>/dev/null && exec </dev/tty

    echo ""
    echo -e "${bold}Dotfiles installer${reset}"
    [[ $DRY_RUN -eq 1 ]] && echo -e "${grey}  (dry run)${reset}"
    echo ""

    detect
    choose
    resolve_dotfiles

    if [[ $DRY_RUN -eq 1 ]]; then
        preview
    else
        summarize
        execute
    fi
}

main "$@"
