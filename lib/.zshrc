if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
source "$ZDOTDIR/.zprezto/runcoms/zshrc"

# >>> begin >>>

unsetopt BEEP LIST_BEEP HIST_BEEP

alias @zshup='git -C "$ZDOTDIR/.." pull >/dev/null; zsh "$ZDOTDIR/../install.zsh"'

# shellcheck disable=SC2154
alias e='$EDITOR'
# shellcheck disable=SC2154
alias v='$PAGER'
alias p='$PAGER'
# shellcheck disable=SC2154
alias b='$BROWSER'
if command -v xdg-open &>/dev/null; then
  alias o='xdg-open'
fi
alias c='clear'
alias x='exit'
alias q='exit'
alias r='ssh'
alias s='sudo'
alias g='git'

function m() { tldr "$@" 2>/dev/null || man "$@"; }
function h() {
  if command -v bat &>/dev/null; then
    "$@" --help 2>&1 | bat -l help -p
  else
    "$@" --help 2>&1 | less
  fi
}

if command -v bat &>/dev/null; then
  alias cat='bat'
fi

if command -v nvim &>/dev/null; then
  alias vim='nvim'
  alias vi='nvim'
elif command -v vim &>/dev/null; then
  alias vi='vim'
elif command -v vi &>/dev/null; then
  alias vim='vi'
fi

if command -v exa &>/dev/null; then
  alias exa='exa --color=always --icons --group-directories-first --group --header --octal-permissions'
  alias ls='exa'
  alias l='exa -1a'
  alias ll='exa -l'
  alias la='exa -la'
fi

if command -v ncdu &>/dev/null; then
  alias du='ncdu -x'
fi

if command -v fzf &>/dev/null; then
  alias f=fzf
fi

if command -v mc &>/dev/null; then
  alias mc='mc -u'
fi

if command -v jq &>/dev/null; then
  alias jq='jq -C'
fi
if command -v yq &>/dev/null; then
  alias yq='yq -C'
fi

alias ping='ping -O'

if ! command -v docker &>/dev/null && command -v podman &>/dev/null; then
  alias docker='podman'
fi
if ! command -v docker-compose &>/dev/null && command -v podman-compose &>/dev/null; then
  alias docker-compose='podman-compose'
fi

function detach() {
  "$@" </dev/null &>/dev/null &
  disown
}

# <<< end <<<

if [[ -s ~/.zshrc ]]; then source ~/.zshrc; fi
