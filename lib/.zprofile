[[ -n "${ZDOTDIR:-}" ]] || return 1
# source "$ZDOTDIR/.zprezto/runcoms/zprofile"

# >>> begin >>>

# history
export HISTFILE='/dev/null'

# zsh options
# shellcheck disable=SC2034
typeset -gU path fpath manpath cdpath mailpath

# dev tools
export CARGO_HOME="$HOME/.cargo"
for GOPATH in "$HOME/go" "$HOME/.go"; do
	[[ -d "$GOPATH/" ]] && break
done
export GOPATH
export NPM_CONFIG_PREFIX="$HOME/.npm"
export NPM_CONFIG_USERCONFIG="$HOME/.npmrc"
export NODE_REPL_HISTORY=''
export MAVEN_REPOSITORY="$HOME/.m2/repository"
for ANDROID_HOME in "$HOME/Android/Sdk" "$HOME/Library/Android/sdk" "$HOME/.android/sdk"; do
	[[ -d "$ANDROID_HOME/" ]] && break
done
export ANDROID_HOME
export ANDROID_USER_HOME="$HOME/.android"

# path / manpath
if [[ -o interactive ]]; then
	__path=() && __manpath=()
	for __path_item in \
		"$HOME/.local/bin" "$HOME/bin" \
		"$CARGO_HOME/bin" \
		"$GOPATH/bin" \
		"$NPM_CONFIG_PREFIX/bin" \
		"$HOME/.dotnet/tools" \
		"$ANDROID_HOME"/{tools,tools/bin,platform-tools}; do
		[[ -d "$__path_item/" ]] && __path+=("$__path_item")
	done
	path=("${__path[@]}" "${path[@]}")
	manpath=("${__manpath[@]}" "${manpath[@]}")
	unset __path __path_item __manpath
fi

# concat / pager
export LESS='-cgiKQnR'
if command less --help | command grep -q 'no-vbell'; then
	export LESS="$LESS --no-vbell"
fi
export LESSHISTFILE='-'
__lesspipe_cmd="$(whence -p lesspipe.sh 2>/dev/null || whence -p lesspipe 2>/dev/null || true)"
if [[ -n "$__lesspipe_cmd" ]]; then
	export LESSOPEN="|$__lesspipe_cmd %s"
fi
unset __lesspipe_cmd
export PAGER='less'
export MANPAGER='less'
export SYSTEMD_PAGER='less'
export SYSTEMD_LESS="$LESS"
export GIT_PAGER='less'
for __bat_cmd in batcat bat; do
	if whence -p "$__bat_cmd" &>/dev/null; then
		export PAGER="$__bat_cmd"
		export MANPAGER="$__bat_cmd -l man -p"
		export SYSTEMD_PAGER="$__bat_cmd -l log -p"
		export GIT_PAGER="$__bat_cmd -p"
		export BAT_PAGER="less -L $LESS"
		export BAT_STYLE='header-filename,header-filesize,rule,numbers,snip'
		break
	fi
done
unset __bat_cmd
if whence -p delta &>/dev/null; then
	export DELTA_PAGER="$GIT_PAGER"
	export GIT_PAGER='delta --line-numbers --side-by-side'
fi

# editor / visual
for __editor in micro nano nvim vim vi; do
	if whence -p "$__editor" &>/dev/null; then
		export EDITOR="$__editor"
		export VISUAL="$__editor"
		export SUDO_EDITOR="$__editor"
		break
	fi
done
unset __editor

# browser
if [[ -z "${BROWSER:-}" ]]; then
	if whence -p xdg-open &>/dev/null; then
		export BROWSER='xdg-open'
	elif [[ "${OSTYPE:-}" == darwin* ]] && whence -p open &>/dev/null; then
		export BROWSER='open'
	fi
fi

# git
if [[ -n "${SSH_CLIENT:-}" ]] && [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
	export GIT_SSH_COMMAND="ssh -o IdentityAgent='$SSH_AUTH_SOCK'"
fi

# containers
export PODMAN_USERNS='keep-id'
if ! whence -p docker &>/dev/null && whence -p podman &>/dev/null && [[ -z "${DOCKER_HOST:-}" ]] && [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
	export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
fi

# hostname
if [[ -z "${HOSTNAME:-}" ]]; then
	HOSTNAME="$(hostnamectl --transient 2>/dev/null || hostname 2>/dev/null || uname -n 2>/dev/null || true)" && export HOSTNAME
fi

# lang
if [[ -z "${LANG:-}" ]]; then
	export LANG='en_US.UTF-8'
fi

# user / group
if [[ -z "${UID:-}" ]]; then
	UID="$(id -ru)" && export UID
fi
if [[ -z "${GID:-}" ]]; then
	GID="$(id -rg)" && export GID
fi

# <<< end <<<

[[ ! -s "$ZDOTDIR/../custom/.zprofile" ]] || source "$ZDOTDIR/../custom/.zprofile"
