if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
source "$ZDOTDIR/.zprezto/runcoms/zprofile"

# >>> begin >>>

# history
export HISTFILE=/dev/null

# path
# shellcheck disable=SC2034
typeset -gU cdpath fpath mailpath path
# shellcheck disable=SC1036,SC2206
path=(
  ~/.local/bin(N)
  /opt/homebrew/{,s}bin(N)
  {,/var/lib/snapd}/snap/bin(N)
  /opt/local/{,s}bin(N)
  /usr/local/{,s}bin(N)
  /usr/{,s}bin(N)
  /{,s}bin(N)
  $path
)
for __path in "${path[@]}"; do
  if [[ ! -d "$__path/" ]]; then
    path=("${path[@]:#$__path}") # remove
  fi
done
unset __path
export PATH

# lang
if [[ "$(locale 2>&1)" == *'Cannot set LC_ALL'* ]]; then
  export LC_ALL='C.UTF-8'
fi

# concat / pager
export LESS='-cgiKQnR --no-vbell'
export LESSHISTFILE='-'
if command -v bat &>/dev/null; then
  export PAGER=bat
  export BAT_PAGER="less $LESS -L"
  export MANPAGER='bat -l man -p'
else
  export PAGER=less
  export MANPAGER=less
fi

# editor / visual
if command -v nvim &>/dev/null; then
  export EDITOR=nvim
elif command -v vim &>/dev/null; then
  export EDITOR=vim
else
  export EDITOR=vi
fi
export VISUAL=$EDITOR

# finder
if command -v fzf &>/dev/null; then
  export FZF_DEFAULT_OPTS='--multi --layout=reverse'
  if command -v bat &>/dev/null; then
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --preview='bat --color=always -p {}'"
  else
    export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --preview='cat {}'"
  fi
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
  fi
fi

# browser
if [[ -z "$BROWSER" ]]; then
  if command -v xdg-open &>/dev/null; then
    export BROWSER=xdg-open
  fi
fi

# <<< end <<<

if [[ -s ~/.profile ]]; then emulate sh -c '. ~/.profile'; fi
if [[ -s ~/.zprofile ]]; then source ~/.zprofile; fi
