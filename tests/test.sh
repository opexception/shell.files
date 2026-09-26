#!/bin/sh
set -eu

REPO_DIR=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd)
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles test.XXXXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM
export HOME=$TEST_DIR/home
mkdir -p "$HOME"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
expect_count() {
    actual=$(grep -Fc "$1" "$2" || :)
    [ "$actual" -eq "$3" ] || fail "Expected $3 occurrences of $1 in $2; got $actual"
}

printf '# keep my prompt\n' > "$HOME/.bashrc"
printf '# keep my zsh settings\n' > "$HOME/.zshrc"
printf '" keep my vim settings\n' > "$HOME/.vimrc"

if sh "$REPO_DIR/setup.sh" --check > "$TEST_DIR/precheck.log"; then
    fail '--check accepted an uninstalled home'
fi
[ ! -e "$HOME/.config" ] || fail '--check modified the home directory'

sh "$REPO_DIR/setup.sh" > "$TEST_DIR/install.log"
sh "$REPO_DIR/setup.sh" --check > "$TEST_DIR/check.log" || fail '--check failed after install'
expect_count 'keep my prompt' "$HOME/.bashrc" 1
expect_count 'keep my zsh settings' "$HOME/.zshrc" 1
expect_count '# >>> portable-dotfiles >>>' "$HOME/.bashrc" 1
[ -L "$HOME/.vimrc" ] || fail 'vimrc was not symlinked'
ls "$HOME"/.vimrc.backup.* >/dev/null 2>&1 || fail 'vimrc was not backed up'

before=$(find "$HOME" -type f -exec cksum {} + | sort)
before_links=$(find "$HOME" -type l -exec ls -l {} + | sort)
sh "$REPO_DIR/setup.sh" > "$TEST_DIR/reinstall.log"
sh "$REPO_DIR/setup.sh" --check > /dev/null || fail '--check failed after reinstall'
after=$(find "$HOME" -type f -exec cksum {} + | sort)
after_links=$(find "$HOME" -type l -exec ls -l {} + | sort)
[ "$before" = "$after" ] && [ "$before_links" = "$after_links" ] || fail 'Repeated install changed files'
expect_count '# >>> portable-dotfiles >>>' "$HOME/.bashrc" 1

printf '\n# custom user setting\n' >> "$HOME/.bashrc"
sh "$REPO_DIR/setup.sh" --check > /dev/null || fail 'Unrelated user setting caused --check failure'
expect_count '# custom user setting' "$HOME/.bashrc" 1

if command -v bash >/dev/null 2>&1; then
    # Invoke an interactive shell with this test's isolated startup file.
    output=$(bash --noprofile --rcfile "$HOME/.bashrc" -ic 'alias ll; alias ls' 2>/dev/null)
    printf '%s\n' "$output" | grep -q "alias ll='ls -lh'" || fail 'Bash did not load ll'
    printf '%s\n' "$output" | grep -q 'alias ls=' || fail 'Bash did not load platform ls'
fi

if command -v zsh >/dev/null 2>&1; then
    output=$(zsh -f -ic 'source "$HOME/.zshrc"; alias ll; alias ls')
    printf '%s\n' "$output" | grep -q "ll='ls -lh'" || fail 'Zsh did not load ll'
fi

printf '%s\n' '# <<< portable-dotfiles <<<' >> "$HOME/.bashrc"
if sh "$REPO_DIR/setup.sh" > /dev/null 2>&1; then
    fail 'Installer accepted a malformed managed block'
fi

printf 'PASS: isolated install, backups, check, idempotence, shell load, malformed block\n'
