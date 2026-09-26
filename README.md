# Portable dotfiles

A lightweight interactive CLI setup for macOS Zsh and Linux Bash. It keeps the operating system's existing shell startup files and adds a small source block. Shared configuration and Vim are linked to this repository, so `git pull` updates them in place.

## Files

| File | Purpose |
| --- | --- |
| `AGENTS.md` | Automatically loaded repo guidance for local Codex |
| `setup.sh` | Install or verify the configuration |
| `shell/common.sh` | Editor and portable `ls`, `ll`, `la`, `l`, and `vi` aliases |
| `shell/bash.sh`, `shell/zsh.sh` | Separate shell history settings |
| `vim/vimrc` | Consistent, modest Vim defaults |
| `tests/test.sh` | Installer regression checks in a temporary home |

## Install

Clone this repository anywhere in your home directory and **keep the clone at that path**:

```sh
git clone https://github.com/opexception/shell.files.git ~/dotfiles
cd ~/dotfiles
sh setup.sh
```

The installer links the three shell files in `~/.config/shell/`, links `~/.vimrc`, and appends a marked block to `~/.bashrc` and `~/.zshrc` when those shells are installed. Existing `~/.vimrc` is moved to a timestamped backup. Existing startup files get a timestamped backup before the first change. It does not invoke `sudo`, install software, or alter `/etc`.

Start a new terminal session to load the settings. To inspect an installation without changing it:

```sh
sh setup.sh --check
```

To update, run `git pull` in the clone. Run `sh setup.sh` again if you move the clone or update the installer's managed block. If `.bashrc` or `.zshrc` is symlinked to another file, the installer declines to edit it; inspect that setup and add the source block yourself.

## Behavior

- `ls` adds `-G` on macOS and `--color=auto` on Linux. The native `ls` remains in use; GNU coreutils are not required. `ll` is `ls -lh`, `la` is `ls -A`, and `l` is `ls -CF`.
- `EDITOR` and `VISUAL` point to `vim` when installed; `vi` aliases to `vim` in interactive shells.
- The Vim configuration adds syntax highlighting, line numbers, search conveniences, a status bar, and familiar backspace behavior. It does not force tabs/spaces, mouse behavior, or disable Vim recovery files.
- Only interactive shells load these aliases and history settings. Aliases do not affect scripts or commands invoked through `sudo`.

## Working with local Codex

Open a terminal in the clone and start `codex`. Codex reads the root `AGENTS.md` automatically. Example requests:

```text
Make ll show dotfiles as well, and update the tests and README.
Review setup.sh for portability on macOS, RHEL, Ubuntu, Fedora, and SLES.
Add a new alias that works with native BSD and GNU tools; run the repo checks.
```

Run checks directly with `sh tests/test.sh`. The test suite installs only into temporary home directories. `git diff --check` catches whitespace issues. On a Mac, `zsh -n shell/common.sh shell/zsh.sh` also validates the Zsh files. Actual cross-OS compatibility needs a run on each target OS (or suitable containers/VMs); tests on one OS do not establish that the other OS's utility options behave identically.

Keep secrets, SSH private keys, tokens, machine-specific environment variables, and local histories out of this repository. When publishing to GitHub, review `git status` and the staged diff first.
