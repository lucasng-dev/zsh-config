if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
source "$ZDOTDIR/.zprezto/runcoms/zshrc"

# >>> begin >>>

# history
export HISTFILE=/dev/null

# zsh
setopt nobeep nolistbeep nohistbeep histignoredups

# list
if command -v eza &>/dev/null; then
  alias eza='eza --color=auto --group-directories-first --binary --header --icons --group --octal-permissions'
  alias ls='eza'
  alias l='eza -1a'
  alias ll='eza -l'
  alias la='eza -la'
elif command -v exa &>/dev/null; then
  alias exa='exa --color=auto --group-directories-first --binary --header --icons --group --octal-permissions'
  alias ls='exa'
  alias l='exa -1a'
  alias ll='exa -l'
  alias la='exa -la'
else
  alias ls='ls --color=auto --group-directories-first --kibibytes --human-readable'
  alias l='ls -1A'
  alias ll='ls -l'
  alias la='ls -lA'
fi

# concat / pager
if command -v bat &>/dev/null; then
  alias less='bat'
  alias cat='bat'
  alias p='bat'
else
  alias cat='less'
  alias p='less'
fi

# editor / visual
if command -v nvim &>/dev/null; then
  alias vim='nvim'
  alias vi='nvim'
  alias v='nvim'
  alias e='nvim'
elif command -v vim &>/dev/null; then
  alias vi='vim'
  alias v='vim'
  alias e='vim'
else
  alias vim='vi'
  alias v='vi'
  alias e='vi'
fi

# finder
if command -v fzf &>/dev/null; then
  f() { if [[ $# -gt 0 ]]; then fzf --bind "enter:become($* {+})"; else fzf; fi; }
fi

# opener
if command -v xdg-open &>/dev/null; then
  alias o='xdg-open'
fi

# env
env() { if [[ $# -gt 0 ]]; then command env "$@"; else command env | sort -f | { bat -l ini -p 2>/dev/null || less; }; fi; }
printenv() { if [[ $# -gt 0 ]]; then command printenv "$@"; else command printenv | sort -f | { bat -l ini -p 2>/dev/null || less; }; fi; }

# ssh
alias ssh='ssh -t'
alias s='ssh'

# network
alias ping='ping -O'
if command -v mtr &>/dev/null; then
  alias mtr='mtr -b -y 2'
  alias traceroute='mtr'
fi

# disk usage
if command -v ncdu &>/dev/null; then
  alias ncdu='ncdu -x'
  alias du='ncdu'
fi

# file manager
if command -v mc &>/dev/null; then
  alias mc='mc -u'
fi

# calculator
if command -v bc &>/dev/null; then
  alias bc='bc -q'
fi

# help / manual
h() { "$@" --help 2>&1 | { bat -l help -p 2>/dev/null || less; }; }
m() { tldr "$@" 2>/dev/null || man "$@" 2>/dev/null || h "$@"; }

# terminal
alias c='clear'
alias x='exit'
detach() {
  nohup "$@" </dev/null &>/dev/null &
  disown
}
if command -v cmatrix &>/dev/null; then
  alias cmatrix='cmatrix -b'
fi

# containers
if ! command -v docker &>/dev/null && command -v podman &>/dev/null; then
  alias docker='podman'
fi
if ! command -v docker-compose &>/dev/null && command -v podman-compose &>/dev/null; then
  alias docker-compose='podman-compose'
fi
if { [[ -f /run/.containerenv ]] || [[ -f /.dockerenv ]]; } && ! command -v distrobox; then
  alias distrobox='/usr/bin/distrobox-host-exec distrobox'
fi

# git
alias g='git'

# <<< end <<<

if [[ -s ~/.zshrc ]]; then source ~/.zshrc; fi
