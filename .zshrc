# ~/.zshrc — Module orchestrator
# Source all modules in sorted order. Finds repo via symlink target.

DOTFILES_DIR="${${(%):-%x}:A:h}"
# symlink resolution above normally wins; fallback covers a copied (non-symlinked) .zshrc
# keep paths in sync with install.sh DOTFILES / DOTFILES_FALLBACK
[[ -d "$DOTFILES_DIR/zsh" ]] || for d in "$HOME/dotfiles" "$HOME/.dotfiles"; do
    [[ -d "$d/zsh" ]] && DOTFILES_DIR="$d" && break
done

for config in "$DOTFILES_DIR/zsh"/*.zsh(N); do
    source "$config"
done

# User overrides — one file for all personal config (not in repo)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
