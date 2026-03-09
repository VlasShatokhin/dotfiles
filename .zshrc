# ~/.zshrc — Module orchestrator
# Source all modules in sorted order. Finds repo via symlink target.

DOTFILES_DIR="${${(%):-%x}:A:h}"
[[ -d "$DOTFILES_DIR/zsh" ]] || DOTFILES_DIR="$HOME/dotfiles"

for config in "$DOTFILES_DIR/zsh"/*.zsh(N); do
    source "$config"
done

# User overrides — one file for all personal config (not in repo)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
