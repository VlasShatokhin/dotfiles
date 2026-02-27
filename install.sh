#!/bin/bash
set -e

# =============================================================================
# Config
# =============================================================================

REPO="https://github.com/vlasshatokhin/dotfiles.git"
DOTFILES="$HOME/dotfiles"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# =============================================================================
# UI helpers
# =============================================================================

# Colors — reuse zen.toml palette where possible
bold='\033[1m'
yellow='\033[33m'
green='\033[38;2;123;155;142m'  # #7B9B8E — zen path green
grey='\033[38;2;85;85;85m'      # #555555 — zen transient grey
reset='\033[0m'

ask() {
    local prompt="$1" default="$2" reply
    printf "%b%s%b " "$bold" "$prompt" "$reset"
    read -r reply
    reply="${reply:-$default}"
    [[ "$reply" =~ ^[Yy]$ ]]
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
        echo "Install it first: https://brew.sh"
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo ""
        echo "Then re-run this installer."
        exit 1
    fi

    warnings=()
    prompt_default="Y"

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        warnings+=("  oh-my-zsh detected — this replaces it with zinit (lighter, faster)")
    fi

    if [[ -f "$HOME/.p10k.zsh" ]] || [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
        warnings+=("  powerlevel10k detected — keeping your existing prompt")
        prompt_default="N"
    fi

    if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" ]]; then
        warnings+=("  starship detected — keeping your existing prompt")
        prompt_default="N"
    fi

    existing=()
    for f in .zshrc .zprofile .hushlogin; do
        if [[ -e "$HOME/$f" || -L "$HOME/$f" ]]; then
            # Skip if already symlinked to our dotfiles
            if [[ -L "$HOME/$f" ]] && [[ "$(readlink "$HOME/$f")" == *dotfiles/"$f" ]]; then
                continue
            fi
            existing+=("$f")
        fi
    done
    if [[ -e "$HOME/.config/ohmyposh/zen.toml" ]]; then
        if ! [[ -L "$HOME/.config/ohmyposh/zen.toml" ]] || \
           [[ "$(readlink "$HOME/.config/ohmyposh/zen.toml")" != *dotfiles/ohmyposh/zen.toml ]]; then
            existing+=(".config/ohmyposh/zen.toml")
        fi
    fi

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
    info "mise — tool version manager"
    info "fzf — fuzzy finder"
    info "zoxide — smart cd"
    info "bat — cat with syntax highlighting"
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

    # Git performance
    echo ""
    echo -e "${bold}Enable git performance?${reset}"
    info "fsmonitor + untrackedcache — background daemon instead of scanning"
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

    [[ $opt_tools  -eq 1 ]] && ok "Install mise, fzf, zoxide, bat" || skip "Skip dev tools"
    [[ $opt_prompt -eq 1 ]] && ok "Install oh-my-posh + prompt theme" || skip "Skip prompt (keep existing)"
    [[ $opt_git    -eq 1 ]] && ok "Enable git fsmonitor + untrackedcache" || skip "Skip git performance"

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

    # Clone or update — avoid clobbering an existing unrelated dotfiles dir
    if [[ -d "$DOTFILES/.git" ]]; then
        local remote
        remote=$(git -C "$DOTFILES" remote get-url origin 2>/dev/null || true)
        if [[ "$remote" == *vlasshatokhin/dotfiles* ]]; then
            log "Updating dotfiles..."
            git -C "$DOTFILES" pull --ff-only 2>/dev/null || true
        else
            DOTFILES="$HOME/.zsh-dotfiles"
            log "~/dotfiles belongs to another repo, using $DOTFILES instead"
            if [[ ! -d "$DOTFILES" ]]; then
                git clone "$REPO" "$DOTFILES"
            else
                git -C "$DOTFILES" pull --ff-only 2>/dev/null || true
            fi
        fi
    elif [[ -d "$DOTFILES" ]]; then
        DOTFILES="$HOME/.zsh-dotfiles"
        log "~/dotfiles exists but is not a git repo, using $DOTFILES instead"
        if [[ ! -d "$DOTFILES" ]]; then
            git clone "$REPO" "$DOTFILES"
        else
            git -C "$DOTFILES" pull --ff-only 2>/dev/null || true
        fi
    else
        log "Cloning dotfiles..."
        git clone "$REPO" "$DOTFILES"
    fi

    # Brew packages
    if [[ $opt_tools -eq 1 ]]; then
        log "Installing dev tools..."
        brew install mise fzf zoxide bat 2>/dev/null || true
    fi

    if [[ $opt_prompt -eq 1 ]]; then
        log "Installing oh-my-posh..."
        brew install oh-my-posh 2>/dev/null || true
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
        ln -sf "$DOTFILES/ohmyposh/zen.toml" ~/.config/ohmyposh/zen.toml
    fi

    # Git performance
    if [[ $opt_git -eq 1 ]]; then
        log "Enabling git performance..."
        git config --global core.fsmonitor true
        git config --global core.untrackedcache true
    fi

    streak
    echo ""
    [[ ${#existing[@]} -gt 0 ]] && info "Backups saved to $BACKUP"
    info "Open a new tab to load the new config"
    echo ""
    info "Custom env vars, aliases, functions? Add to:"
    info "  ~/.env.zsh  ~/.aliases.zsh  ~/.functions.zsh"
}

# =============================================================================
# Phase 5: Dry-run preview
# =============================================================================

preview() {
    echo ""
    info "File tree (dry run — no changes made)"
    echo ""

    node "~/"
    node "├── .zshrc → ~/dotfiles/.zshrc"
    node "├── .zprofile → ~/dotfiles/.zprofile"
    node "├── .hushlogin → ~/dotfiles/.hushlogin"

    if [[ $opt_prompt -eq 1 ]]; then
        node "├── .config/"
        node "│   └── ohmyposh/"
        node "│       └── zen.toml → ~/dotfiles/ohmyposh/zen.toml"
    fi

    if [[ ${#existing[@]} -gt 0 ]]; then
        local last="${existing[${#existing[@]}-1]}"
        node "├── .dotfiles-backup/$(date +%Y%m%d-%H%M%S)/"
        for f in "${existing[@]}"; do
            if [[ "$f" == "$last" ]]; then
                node "│   └── $f (backed up)"
            else
                node "│   ├── $f (backed up)"
            fi
        done
    fi

    if [[ $opt_tools -eq 1 ]] || [[ $opt_prompt -eq 1 ]]; then
        echo ""
        info "Brew packages"
        [[ $opt_tools  -eq 1 ]] && node "  mise, fzf, zoxide, bat"
        [[ $opt_prompt -eq 1 ]] && node "  oh-my-posh"
    fi

    if [[ $opt_git -eq 1 ]]; then
        echo ""
        info "Git config (global)"
        node "  core.fsmonitor = true"
        node "  core.untrackedcache = true"
    fi

    streak
    echo ""
    info "Run without --dry-run to apply, then open a new tab"
}

# =============================================================================
# Main
# =============================================================================

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

echo ""
echo -e "${bold}Dotfiles installer${reset}"
[[ $DRY_RUN -eq 1 ]] && echo -e "${grey}  (dry run)${reset}"
echo ""

detect
choose

if [[ $DRY_RUN -eq 1 ]]; then
    preview
else
    summarize
    execute
fi
