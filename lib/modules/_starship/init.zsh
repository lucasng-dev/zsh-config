[[ -n "${ZDOTDIR:-}" ]] || return 1

export STARSHIP_CONFIG="$ZDOTDIR/config/starship/starship.toml"
if whence -p starship &>/dev/null; then
	eval "$(command starship init zsh)"
elif [[ -x "$ZDOTDIR/.starship/starship" ]]; then
	eval "$("$ZDOTDIR/.starship/starship" init zsh)"
	alias starship="$ZDOTDIR/.starship/starship"
fi
