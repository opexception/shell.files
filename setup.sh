#!/bin/sh
# Install the repo-managed shell and Vim configuration for the current user.
set -eu

REPO_DIR=$(CDPATH= cd -P "$(dirname "$0")" && pwd)
CONFIG_DIR=$HOME/.config/shell
BEGIN='# >>> portable-dotfiles >>>'
END='# <<< portable-dotfiles <<<'

say() { printf '%s\n' "$*"; }
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

case ${HOME:-} in
    /*) ;;
    *) fail 'HOME must be an absolute path' ;;
esac

case ${1:-} in
    '') MODE=install ;;
    --check) MODE=check ;;
    *) fail 'Usage: sh setup.sh [--check]' ;;
esac
[ "$#" -le 1 ] || fail 'Usage: sh setup.sh [--check]'

for source_file in shell/common.sh shell/bash.sh shell/zsh.sh vim/vimrc; do
    [ -f "$REPO_DIR/$source_file" ] || fail "Missing $REPO_DIR/$source_file"
done

unique_backup() {
    backup=$1.backup.$(date +%Y%m%d-%H%M%S)
    suffix=1
    while [ -e "$backup" ] || [ -L "$backup" ]; do
        backup=$1.backup.$(date +%Y%m%d-%H%M%S).$suffix
        suffix=$((suffix + 1))
    done
}

check_link() {
    target=$1 source_file=$2
    [ -L "$target" ] && [ "$(readlink "$target")" = "$REPO_DIR/$source_file" ] || {
        say "Needs link: $target -> $REPO_DIR/$source_file"
        return 1
    }
    say "OK link: $target"
}

install_link() {
    target=$1 source_file=$2
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$REPO_DIR/$source_file" ]; then
        say "Already linked: $target"
        return
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
        [ ! -d "$target" ] || fail "Directory in the way: $target"
        unique_backup "$target"
        mv "$target" "$backup"
        say "Backed up: $target -> $backup"
    fi
    ln -s "$REPO_DIR/$source_file" "$target"
    say "Linked: $target"
}

block() {
    shell_name=$1
    printf '%s\n' "$BEGIN"
    cat <<'EOF'
case $- in
    *i*)
        if [ -f "$HOME/.config/shell/common.sh" ]; then
            . "$HOME/.config/shell/common.sh"
        fi
EOF
    printf '        if [ -f "$HOME/.config/shell/%s.sh" ]; then\n' "$shell_name"
    printf '            . "$HOME/.config/shell/%s.sh"\n' "$shell_name"
    printf '        fi\n        ;;\nesac\n%s\n' "$END"
}

validate_rc() {
    rc_file=$1
    [ ! -L "$rc_file" ] || fail "Startup file is a symlink; inspect manually: $rc_file"
    [ ! -d "$rc_file" ] || fail "Directory in the way: $rc_file"
    if [ -f "$rc_file" ]; then
        starts=$(grep -Fxc "$BEGIN" "$rc_file" || :)
        ends=$(grep -Fxc "$END" "$rc_file" || :)
        [ "$starts" = "$ends" ] && [ "$starts" -le 1 ] || fail "Malformed managed block: $rc_file"
        if [ "$starts" -eq 1 ]; then
            awk -v begin="$BEGIN" -v end="$END" '
                $0 == begin { inside = 1 }
                $0 == end && !inside { bad = 1 }
                $0 == end { inside = 0 }
                END { if (inside || bad) exit 1 }
            ' "$rc_file" || fail "Malformed managed block: $rc_file"
        fi
    fi
}

check_rc() {
    rc_file=$1 shell_name=$2
    if [ ! -f "$rc_file" ] || [ -L "$rc_file" ]; then
        say "Needs startup block: $rc_file"
        return 1
    fi
    validate_rc "$rc_file"
    [ "$(grep -Fxc "$BEGIN" "$rc_file" || :)" -eq 1 ] || {
        say "Needs startup block: $rc_file"
        return 1
    }
    # Verify the full managed text so a changed or outdated block is reported.
    actual=$(awk -v begin="$BEGIN" -v end="$END" '
        $0 == begin { inside = 1 }
        inside { print }
        $0 == end { inside = 0 }
    ' "$rc_file")
    desired=$(block "$shell_name")
    # Command substitution strips trailing newlines from both strings.
    [ "$actual" = "$desired" ] || {
        say "Needs startup block update: $rc_file"
        return 1
    }
    say "OK startup block: $rc_file"
}

install_rc() {
    rc_file=$1 shell_name=$2
    validate_rc "$rc_file"
    if [ -f "$rc_file" ] && check_rc "$rc_file" "$shell_name" >/dev/null; then
        say "Already configured: $rc_file"
        return
    fi
    temp_file=$(mktemp "$rc_file.tmp.XXXXXXXX") || fail "Cannot create temp file for $rc_file"
    if [ -f "$rc_file" ]; then
        cp -p "$rc_file" "$temp_file"
        awk -v begin="$BEGIN" -v end="$END" '
            $0 == begin { inside = 1; next }
            $0 == end { inside = 0; next }
            !inside { print }
        ' "$rc_file" > "$temp_file"
        unique_backup "$rc_file"
        cp -p "$rc_file" "$backup"
        say "Backed up: $rc_file -> $backup"
    fi
    printf '\n' >> "$temp_file"
    block "$shell_name" >> "$temp_file"
    mv "$temp_file" "$rc_file"
    say "Configured: $rc_file"
}

if [ "$MODE" = check ]; then
    status=0
    check_link "$CONFIG_DIR/common.sh" shell/common.sh || status=1
    check_link "$CONFIG_DIR/bash.sh" shell/bash.sh || status=1
    check_link "$CONFIG_DIR/zsh.sh" shell/zsh.sh || status=1
    check_link "$HOME/.vimrc" vim/vimrc || status=1
    if command -v bash >/dev/null 2>&1; then
        check_rc "$HOME/.bashrc" bash || status=1
    fi
    if command -v zsh >/dev/null 2>&1; then
        check_rc "$HOME/.zshrc" zsh || status=1
    fi
    exit "$status"
fi

# Refuse unexpected startup-file layouts before making any changes.
if command -v bash >/dev/null 2>&1; then validate_rc "$HOME/.bashrc"; fi
if command -v zsh >/dev/null 2>&1; then validate_rc "$HOME/.zshrc"; fi
[ ! -L "$CONFIG_DIR" ] || fail "Config directory is a symlink: $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"
install_link "$CONFIG_DIR/common.sh" shell/common.sh
install_link "$CONFIG_DIR/bash.sh" shell/bash.sh
install_link "$CONFIG_DIR/zsh.sh" shell/zsh.sh
install_link "$HOME/.vimrc" vim/vimrc
if command -v bash >/dev/null 2>&1; then install_rc "$HOME/.bashrc" bash; fi
if command -v zsh >/dev/null 2>&1; then install_rc "$HOME/.zshrc" zsh; fi
say 'Done. Start a new interactive shell, or run: sh setup.sh --check'
