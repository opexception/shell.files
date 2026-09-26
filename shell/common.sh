# Shared interactive Bash/Zsh settings. Sourced from the managed rc block.

if command -v vim >/dev/null 2>&1; then
    export EDITOR=vim VISUAL=vim
    alias vi='vim'
fi

case "$(uname -s)" in
    Darwin) alias ls='ls -G' ;;
    Linux)  alias ls='ls --color=auto' ;;
esac

alias ll='ls -lh'
alias la='ls -A'
alias l='ls -CF'
