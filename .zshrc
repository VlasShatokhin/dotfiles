# ~/.zshrc — Module orchestrator
# Source all modules from ~/dotfiles/zsh/ in sorted order.
# Modules are numbered (01-*, 02-*, ...) to control load sequence.

for config in "$HOME/dotfiles/zsh"/*.zsh(N); do
    source "$config"
done
