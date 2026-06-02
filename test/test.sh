#!/bin/bash
set -e

cd "$(dirname "$0")/.."

IMAGE="dotfiles-test-$$"
PASS=0
FAIL=0

cleanup() { docker rmi "$IMAGE" &>/dev/null || true; }
trap cleanup EXIT

pass() { echo "  ✔ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✘ $1"; FAIL=$((FAIL + 1)); }

# Assert the captured $out matches (or does not match) an extended regex
assert_contains() { grep -qE -- "$2" <<<"$out" && pass "$1" || fail "$1"; }
assert_absent()   { ! grep -qE -- "$2" <<<"$out" && pass "$1" || fail "$1"; }

run() {
    docker run --rm -i --entrypoint /bin/bash "$IMAGE" -c "$1" 2>&1
}

echo "Building test image..."
docker build -f test/Dockerfile -t "$IMAGE" . -q >/dev/null

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 1: Default install + shell loads end-to-end"
# ─────────────────────────────────────────────────────────
out=$(printf '\n\n\ny\n' | run '
    echo "# old" > ~/.zshrc
    /home/tester/dotfiles/install.sh
    echo "---VERIFY---"
    readlink ~/.zshrc
    readlink ~/.zprofile
    readlink ~/.hushlogin
    readlink ~/.config/ohmyposh/prompt.toml
    readlink ~/.config/ohmyposh/prompt-light.toml
    head -1 ~/.cache/zsh/init/brew.zsh 2>/dev/null
    git config --global core.fsmonitor
    echo "---SMOKE---"
    zsh -c "source ~/.zshrc; echo SHELL_LOADED" 2>/tmp/serr
    echo "SMOKE_STDERR=[$(cat /tmp/serr)]"
    zsh -n ~/.cache/zsh/init/brew.zsh && echo "BREWCACHE_OK"
')

assert_contains "Symlink .zshrc"          'dotfiles/\.zshrc'
assert_contains "Symlink .zprofile"       'dotfiles/\.zprofile'
assert_contains "Symlink .hushlogin"      'dotfiles/\.hushlogin'
assert_contains "Symlink prompt.toml"     'ohmyposh/prompt\.toml'
assert_contains "Symlink prompt-light.toml" 'ohmyposh/prompt-light\.toml'
assert_contains "Brew cache generated"    'HOMEBREW_PREFIX'
assert_contains "Git fsmonitor enabled"   'true'
assert_contains "Shell sources cleanly"    'SHELL_LOADED'
assert_contains "Shell load has no stderr" 'SMOKE_STDERR=\[\]'
assert_contains "Brew cache is valid zsh"  'BREWCACHE_OK'

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 2: Backup existing configs + flag tool-init for migration"
# ─────────────────────────────────────────────────────────
out=$(printf '\n\n\ny\n' | run '
    echo "export NVM_DIR=$HOME/.nvm" > ~/.zshrc
    echo "# old zprofile" > ~/.zprofile
    /home/tester/dotfiles/install.sh
    echo "---VERIFY---"
    find ~/.dotfiles-backup -type f 2>/dev/null
')

assert_contains "Backed up .zshrc"     'dotfiles-backup.*\.zshrc'
assert_contains "Backed up .zprofile"  'dotfiles-backup.*\.zprofile'
assert_contains "nvm flagged before confirm" 'nvm.*init found in your shell config'

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 3: Skip prompt when starship detected"
# ─────────────────────────────────────────────────────────
out=$(printf '\n\n\ny\n' | run '
    mkdir -p ~/.config && touch ~/.config/starship.toml
    /home/tester/dotfiles/install.sh
    echo "---VERIFY---"
    test -L ~/.config/ohmyposh/prompt.toml && echo "SYMLINKED" || echo "SKIPPED"
')

assert_contains "Prompt skipped"   'SKIPPED'
assert_contains "Starship warning" 'starship detected'

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 4: Dry run makes no changes"
# ─────────────────────────────────────────────────────────
out=$(printf '\n\n\n' | run '
    echo "# original" > ~/.zshrc
    /home/tester/dotfiles/install.sh --dry-run
    echo "---VERIFY---"
    cat ~/.zshrc
    test -d ~/.dotfiles-backup && echo "BACKUP_EXISTS" || echo "NO_BACKUP"
    test -f ~/.cache/zsh/init/brew.zsh && echo "CACHE_EXISTS" || echo "NO_CACHE"
')

assert_contains "zshrc unchanged"          '# original'
assert_contains "No backup created"        'NO_BACKUP'
assert_contains "No cache created"         'NO_CACHE'
assert_contains "Preview lists prompt-light" 'prompt-light\.toml'

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 5: Sudo rejected"
# ─────────────────────────────────────────────────────────
out=$(docker run --rm -i --user root --entrypoint /bin/bash "$IMAGE" -c '
    /home/tester/dotfiles/install.sh 2>&1; echo "EXIT=$?"
')

assert_contains "Exits with error" 'EXIT=1'
assert_contains "Shows warning"    'Do not run as root'

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 6: Brew cache has correct detected prefix"
# ─────────────────────────────────────────────────────────
out=$(printf '\n\n\ny\n' | run '
    /home/tester/dotfiles/install.sh
    echo "---VERIFY---"
    cat ~/.cache/zsh/init/brew.zsh
')

assert_contains "Uses detected prefix" '/home/tester/brew'

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 7: Re-run is idempotent (no duplicate backups)"
# ─────────────────────────────────────────────────────────
out=$(printf '\n\n\ny\n\n\n\ny\n' | run '
    echo "# old" > ~/.zshrc
    /home/tester/dotfiles/install.sh   # run 1: real file backed up, symlinks created
    /home/tester/dotfiles/install.sh   # run 2: symlinks are ours -> no new backup
    echo "---VERIFY---"
    echo "BACKUP_DIRS=$(ls -1d ~/.dotfiles-backup/*/ 2>/dev/null | wc -l | tr -d " ")"
    readlink ~/.zshrc
')

assert_contains "Exactly one backup after two runs" 'BACKUP_DIRS=1'
assert_contains "zshrc still ours after re-run"      'dotfiles/\.zshrc'

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 8: Detection paths (p10k / oh-my-zsh / asdf)"
# ─────────────────────────────────────────────────────────
out=$(printf '\n\n\ny\n' | run '
    touch ~/.p10k.zsh
    /home/tester/dotfiles/install.sh
    echo "---VERIFY---"
    test -L ~/.config/ohmyposh/prompt.toml && echo "SYMLINKED" || echo "SKIPPED"
')

assert_contains "p10k: prompt skipped"   'SKIPPED'
assert_contains "p10k: detected warning" 'powerlevel10k detected'

out=$(printf '\n\n\ny\n' | run '
    mkdir -p ~/.oh-my-zsh ~/.asdf
    /home/tester/dotfiles/install.sh
    echo "---VERIFY---"
    echo done
')

assert_contains "oh-my-zsh warning" 'replaces it with zinit'
assert_contains "asdf warning"      'asdf detected'

# ─────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
