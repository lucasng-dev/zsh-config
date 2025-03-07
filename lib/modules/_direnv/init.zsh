[[ -n "${ZDOTDIR:-}" ]] || return 1

if whence -p direnv &>/dev/null; then
	eval "$(command direnv hook zsh)"
fi
