if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
source "$ZDOTDIR/.zprezto/runcoms/zprofile"

# >>> begin >>>

# path
# shellcheck disable=SC2034
typeset -gU cdpath fpath mailpath path
# shellcheck disable=SC1036,SC2206
path=(
  ~/.local/bin(N)
  /opt/homebrew/{,s}bin(N)
  /var/lib/snapd/snap/bin(N)
  /var/lib/flatpak/exports/bin(N)
  /opt/local/{,s}bin(N)
  /usr/local/{,s}bin(N)
  /usr/{,s}bin(N)
  /{,s}bin(N)
  $path
)

# lang
if locale 2>&1 | grep 'Cannot set LC_ALL' >/dev/null; then
  export LC_ALL='C.UTF-8'
fi

# editor
if command -v nvim &>/dev/null; then
  export EDITOR=nvim
elif command -v vim &>/dev/null; then
  export EDITOR=vim
else
  export EDITOR=vi
fi
export VISUAL=$EDITOR

# pager
export LESS='-Rcq --no-vbell'
export LESSHISTFILE='-'
if command -v bat &>/dev/null; then
  export PAGER=bat
  export BAT_PAGER="less $LESS"
  export MANPAGER='bat -l man -p'
else
  export PAGER=less
fi

# browser
if [[ -z "$BROWSER" ]]; then
  if command -v xdg-open &>/dev/null; then
    export BROWSER=xdg-open
  fi
fi

# <<< end <<<

if [[ -s ~/.profile ]]; then emulate sh -c 'source ~/.profile'; fi
if [[ -s ~/.zprofile ]]; then source ~/.zprofile; fi
