if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
#source "$ZDOTDIR/.zprezto/runcoms/zprofile"

# >>> begin >>>

# history
export HISTFILE=/dev/null

# path
# shellcheck disable=SC2034
typeset -gU cdpath fpath mailpath path
# shellcheck disable=SC2206
__path=(
  ~/.local/bin
  ~/bin
  /opt/homebrew/bin
  /var/lib/snapd/snap/bin
  /snap/bin
  /usr/local/bin
  /usr/local/sbin
  /usr/bin
  /usr/sbin
  /bin
  /sbin
  $path
)
path=()
for __path_item in "${__path[@]}"; do
  [[ ! -d "$__path_item/" ]] && continue
  case "$__path_item" in
  /snap/bin) [[ "$__path_item" -ef /var/lib/snapd/snap/bin ]] && continue ;;
  /bin) [[ "$__path_item" -ef /usr/bin ]] && continue ;;
  /sbin) [[ "$__path_item" -ef /usr/sbin ]] && continue ;;
  esac
  path+=("$__path_item")
done
unset __path __path_item
export PATH

# user
if command -v id &>/dev/null; then
  if [[ -z "$USER" ]]; then USER=$(id -nu) && export USER; fi
  if [[ -z "$LOGNAME" ]]; then LOGNAME=$USER && export LOGNAME; fi
  if [[ -z "$EUID" ]]; then EUID=$(id -u) && export EUID; fi
  if [[ -z "$UID" ]]; then UID=$(id -ru) && export UID; fi
  if [[ -z "$GID" ]]; then GID=$(id -rg) && export GID; fi
fi

# hostname
if [[ -z "${HOSTNAME:-}" ]]; then
  HOSTNAME=$(hostnamectl --transient 2>/dev/null || hostname 2>/dev/null || uname -n >2/dev/null || true) && export HOSTNAME
fi

# lang
if [[ -z "${LANG:-}" ]]; then
  export LANG='en_US.UTF-8'
fi
if [[ "$(LANG=C locale 2>&1)" == *'Cannot set LC_ALL'* ]]; then
  export LC_ALL='C.UTF-8'
fi

# concat / pager
export LESS='-cgiKQnR --no-vbell +p0'
export LESSHISTFILE='-'
if command -v bat &>/dev/null; then
  export PAGER=bat
  export BAT_PAGER="less -L $LESS"
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
if [[ -z "${BROWSER:-}" ]]; then
  if command -v xdg-open &>/dev/null; then
    export BROWSER=xdg-open
  elif command -v open &>/dev/null && [[ "${OSTYPE:-}" == darwin* ]]; then
    export BROWSER=open
  fi
fi

# <<< end <<<

if [[ -s ~/.profile ]]; then emulate sh -c '. ~/.profile'; fi
if [[ -s ~/.zprofile ]]; then source ~/.zprofile; fi
