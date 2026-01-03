[[ -n "${ZDOTDIR:-}" ]] || return 1
source "$ZDOTDIR/.zprezto/runcoms/zshrc"

# >>> begin >>>

# history
export HISTFILE='/dev/null'

# zsh options
setopt nobeep nolistbeep nohistbeep histignoredups

# list
if whence -p eza &>/dev/null; then
	alias eza='eza --color=auto --group-directories-first --binary --header --icons --group --octal-permissions'
	alias ls='eza'
else
	alias ls='ls --color=auto --group-directories-first --kibibytes --human-readable'
fi
alias l='ls -1A'
alias ll='ls -l'
alias la='ls -lA'

# concat / pager
if [[ "${PAGER:-}" == bat* ]]; then
	alias bat="$PAGER --color=auto --wrap=never"
	alias less='bat'
	alias more='bat'
	alias cat='bat'
	alias p='bat'
else
	alias more='less'
	alias cat='less'
	alias p='less'
fi

# editor / visual
alias edit="${EDITOR:-}"
alias e="${EDITOR:-}"
alias _edit='sudoedit'
alias _e='sudoedit'
alias v="${VISUAL:-}"
alias _v='sudoedit'
if whence -p nvim &>/dev/null; then
	alias vim='nvim'
	alias vi='nvim'
elif whence -p vim &>/dev/null; then
	alias vi='vim'
elif whence -p vi &>/dev/null; then
	alias vim='vi'
fi

# su
alias _='sudo'

# find / replace
alias grep='grep --color=auto'

# opener
if whence -p xdg-open &>/dev/null; then
	alias open='xdg-open'
	alias o='xdg-open'
elif [[ "${OSTYPE:-}" == darwin* ]] && whence -p open &>/dev/null; then
	alias o='open'
fi

# env
function env() {
	if [[ $# -gt 0 ]]; then
		command env "$@"
	elif [[ "${PAGER:-}" == bat* ]]; then
		command env | command sort -f | bat -l ini -p
	else
		command env | command sort -f | command less
	fi
}
function printenv() {
	if [[ $# -gt 0 ]]; then
		command printenv "$@"
	elif [[ "${PAGER:-}" == bat* ]]; then
		command printenv | command sort -f | bat -l ini -p
	else
		command printenv | command sort -f | command less
	fi
}

# network
alias ssh='ssh -t'
alias s='ssh'
alias ping='ping -O'
if whence -p mtr &>/dev/null; then
	alias mtr='mtr -b -y 2'
	alias traceroute='mtr'
fi
if whence -p ip &>/dev/null; then
	alias ip='ip -color=auto'
	alias ifconfig='ip address'
fi
if whence -p ss &>/dev/null; then
	alias netstat='ss'
fi

# filesystem
if whence -p df &>/dev/null; then
	alias df='df -kh'
fi
if whence -p ncdu &>/dev/null; then
	alias ncdu='ncdu -x'
	alias du='ncdu'
elif whence -p du &>/dev/null; then
	alias du='du -kh'
fi

# file manager
if whence -p mc &>/dev/null; then
	alias mc='mc -u'
fi

# help / manual
function help() {
	if [[ "${PAGER:-}" == bat* ]]; then
		"$@" --help 2>&1 | bat -l help -p
	else
		"$@" --help 2>&1 | command less
	fi
}
alias h='help'
function manual() {
	command tldr "$@" 2>/dev/null || command man "$@" 2>/dev/null || help "$@"
}
alias m='manual'

# terminal
alias @shell='clear; exec zsh'
alias c='clear'
alias x='exit'
function detach() {
	(
		nohup "$@" </dev/null &>/dev/null &
		disown &>/dev/null || true
	)
}
if whence -p fastfetch &>/dev/null; then
	alias fastfetch='fastfetch --config paleofetch'
	alias neofetch='fastfetch'
fi
if whence -p cmatrix &>/dev/null; then
	alias cmatrix='cmatrix -b'
fi

# git
if whence -p git &>/dev/null; then
	if whence -p lazygit &>/dev/null; then
		function git() {
			if [[ $# -eq 0 ]] || { [[ $# -eq 1 ]] && [[ "$1" =~ ^(status|branch|log|stash)$ ]]; }; then
				lazygit "$@"
			else
				command git "$@"
			fi
		}
	fi
	alias g='git'
fi

# containers
if ! whence -p docker &>/dev/null && whence -p podman &>/dev/null; then
	alias docker='podman'
fi
if whence -p docker-compose &>/dev/null; then
	docker-compose() { UID="${UID:-}" GID="${GID:-}" TZ="${TZ:-$(timedatectl show --property='Timezone' --value 2>/dev/null || echo 'UTC')}" command docker-compose "$@"; }
	if whence -p docker &>/dev/null; then
		docker() { case "${1:-}" in compose) shift 1 && docker-compose "$@" ;; *) command docker "$@" ;; esac }
	fi
fi
if whence -p podman-compose &>/dev/null; then
	podman-compose() { UID="${UID:-}" GID="${GID:-}" TZ="${TZ:-$(timedatectl show --property='Timezone' --value 2>/dev/null || echo 'UTC')}" command podman-compose "$@"; }
	if ! whence docker-compose &>/dev/null; then
		alias docker-compose='podman-compose'
	fi
	if whence -p podman &>/dev/null; then
		podman() { case "${1:-}" in compose) shift 1 && podman-compose "$@" ;; *) command podman "$@" ;; esac }
	fi
fi
if [[ -n "${CONTAINER_ID:-}" ]] && ! whence -p distrobox &>/dev/null; then
	alias distrobox='/usr/bin/distrobox-host-exec distrobox'
fi

# fpath
if [[ -n "${CONTAINER_ID:-${container:-}}" ]] && [[ -d /run/host/usr/share/zsh/site-functions/ ]]; then
	fpath=("${fpath[@]}" /run/host/usr/share/zsh/site-functions)
fi

# <<< end <<<

[[ ! -s "$ZDOTDIR/../custom/.zshrc" ]] || source "$ZDOTDIR/../custom/.zshrc"
