# Shared interactive Bash/Zsh settings. Sourced from the managed rc block.

if command -v vim >/dev/null 2>&1; then
    export EDITOR=vim VISUAL=vim
    alias vi='vim'
fi

# Ensure $HOME/bin is on PATH if it exists
if [ -d "$HOME/bin" ]; then
    case ":${PATH}:" in
        *:"$HOME/bin":*) ;;
        *) PATH="$PATH:$HOME/bin" ;;
    esac
fi

case "$(uname -s)" in
    Darwin) alias ls='ls -G' ;;
    Linux)  alias ls='ls --color=auto' ;;
esac

alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
