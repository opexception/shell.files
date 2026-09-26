# Dotfiles project instructions

This repo supplies a small, consistent interactive shell and Vim environment for macOS (Zsh), RHEL/Rocky/AlmaLinux, Ubuntu/Debian, and future Linux distributions such as Fedora and SLES. Preserve native system startup behavior.

## Layout

- `setup.sh`: POSIX shell installer and read-only `--check` mode.
- `shell/common.sh`: shared Bash/Zsh interactive aliases and editor variables.
- `shell/bash.sh`, `shell/zsh.sh`: shell-specific interactive settings.
- `vim/vimrc`: portable Vim settings.
- `tests/test.sh`: isolated installation and regression checks.

## Working rules

- Keep `shell/common.sh` valid when sourced by both Bash and Zsh. Use shell-specific syntax only in the matching file.
- Use native macOS/BSD utilities on macOS; do not require Homebrew or GNU coreutils. Use standard POSIX tools in the installer and tests where possible. Do not add platform branches without a demonstrated difference.
- Preserve existing `~/.bashrc` and `~/.zshrc`; change only the marked managed block. Make repeated setup runs safe, and back up any existing `~/.vimrc` before replacing it. Treat an unexpected or malformed managed block as an error, never silently discard user settings.
- `setup.sh --check` must make no changes. Tests must use a temporary `HOME` and must never install into the developer's real home directory.
- Do not overwrite `/etc` files, change the login shell, install packages, commit secrets, or change a user's actual home directory while verifying a change.
- Keep Vim useful on stock installations without plugins or opinionated global indentation settings. Document behavior changes in `README.md`.

## Verification

Run `sh -n setup.sh shell/common.sh tests/test.sh`, `bash -n shell/common.sh shell/bash.sh`, and `sh tests/test.sh` after changes. If Zsh is present, also run `zsh -n shell/common.sh shell/zsh.sh`. Use `shellcheck` when available. For platform-specific changes, explain which OS/shell was actually exercised and which remain untested.

## Review

Inspect `git diff --check` and the relevant diff. Pay special attention to quoting, paths with spaces, broken symlinks, backups, installer idempotence, startup in interactive vs noninteractive shells, and BSD/GNU option differences. Add a regression check when fixing a demonstrated installer bug.
