#!/bin/bash
set -e

cd "$(dirname "$0")/.."

IMAGE="dotfiles-test-$$"
PASS=0
FAIL=0

cleanup() { docker rmi "$IMAGE" &>/dev/null || true; }
trap cleanup EXIT

check() {
    local desc="$1" result="$2"
    if [[ "$result" == "0" ]]; then
        echo "  ✔ $desc"
        PASS=$((PASS + 1))
    else
        echo "  ✘ $desc"
        FAIL=$((FAIL + 1))
    fi
}

run() {
    docker run --rm -i --entrypoint /bin/bash "$IMAGE" -c "$1" 2>&1
}

echo "Building test image..."
docker build -f test/Dockerfile -t "$IMAGE" . -q >/dev/null

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 1: Default install (tools=y, prompt=y, git=y)"
# ─────────────────────────────────────────────────────────
out=$(printf '\n\n\ny\n' | run '
    echo "# old" > ~/.zshrc
    /home/tester/dotfiles/install.sh
    echo "---VERIFY---"
    readlink ~/.zshrc
    readlink ~/.zprofile
    readlink ~/.hushlogin
    readlink ~/.config/ohmyposh/zen.toml
    cat ~/.cache/zsh/init/brew.zsh 2>/dev/null | head -1
    git config --global core.fsmonitor
')

check "Symlink .zshrc"        "$(echo "$out" | grep -c 'dotfiles/.zshrc'    | grep -qc 1 && echo 0 || echo 1)"
check "Symlink .zprofile"     "$(echo "$out" | grep -c 'dotfiles/.zprofile' | grep -qc 1 && echo 0 || echo 1)"
check "Symlink .hushlogin"    "$(echo "$out" | grep -c 'dotfiles/.hushlogin'| grep -qc 1 && echo 0 || echo 1)"
check "Symlink zen.toml"      "$(echo "$out" | grep -c 'ohmyposh/zen.toml'  | grep -qc 1 && echo 0 || echo 1)"
check "Brew cache generated"  "$(echo "$out" | grep -qc 'HOMEBREW_PREFIX'   && echo 0 || echo 1)"
check "Git fsmonitor enabled" "$(echo "$out" | grep -qc 'true'              && echo 0 || echo 1)"

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 2: Backup existing configs"
# ─────────────────────────────────────────────────────────
out=$(printf '\n\n\ny\n' | run '
    echo "# old zshrc" > ~/.zshrc
    echo "# old zprofile" > ~/.zprofile
    /home/tester/dotfiles/install.sh
    echo "---VERIFY---"
    find ~/.dotfiles-backup -type f 2>/dev/null
')

check "Backed up .zshrc"    "$(echo "$out" | grep -qc 'dotfiles-backup.*\.zshrc'    && echo 0 || echo 1)"
check "Backed up .zprofile"  "$(echo "$out" | grep -qc 'dotfiles-backup.*\.zprofile' && echo 0 || echo 1)"

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 3: Skip prompt when starship detected"
# ─────────────────────────────────────────────────────────
out=$(printf '\n\n\ny\n' | run '
    mkdir -p ~/.config && touch ~/.config/starship.toml
    /home/tester/dotfiles/install.sh
    echo "---VERIFY---"
    test -L ~/.config/ohmyposh/zen.toml && echo "SYMLINKED" || echo "SKIPPED"
')

check "Prompt skipped" "$(echo "$out" | grep -qc 'SKIPPED' && echo 0 || echo 1)"
check "Starship warning" "$(echo "$out" | grep -qc 'starship detected' && echo 0 || echo 1)"

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

check "zshrc unchanged"  "$(echo "$out" | grep -qc '# original'  && echo 0 || echo 1)"
check "No backup created" "$(echo "$out" | grep -qc 'NO_BACKUP'  && echo 0 || echo 1)"
check "No cache created"  "$(echo "$out" | grep -qc 'NO_CACHE'   && echo 0 || echo 1)"

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 5: Sudo rejected"
# ─────────────────────────────────────────────────────────
out=$(docker run --rm -i --user root --entrypoint /bin/bash "$IMAGE" -c '
    /home/tester/dotfiles/install.sh 2>&1; echo "EXIT=$?"
')

check "Exits with error" "$(echo "$out" | grep -qc 'EXIT=1'          && echo 0 || echo 1)"
check "Shows warning"    "$(echo "$out" | grep -qc 'Do not run as root' && echo 0 || echo 1)"

# ─────────────────────────────────────────────────────────
echo ""
echo "Test 6: Brew cache has correct detected prefix"
# ─────────────────────────────────────────────────────────
out=$(printf '\n\n\ny\n' | run '
    /home/tester/dotfiles/install.sh
    echo "---VERIFY---"
    cat ~/.cache/zsh/init/brew.zsh
')

check "Uses detected prefix" "$(echo "$out" | grep -qc '/home/tester/brew' && echo 0 || echo 1)"

# ─────────────────────────────────────────────────────────
echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
