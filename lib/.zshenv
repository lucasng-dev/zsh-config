[[ -n "${ZDOTDIR:-}" ]] || return 1
# source "$ZDOTDIR/.zprezto/runcoms/zshenv"

# >>> begin >>>

# zsh doesn't source '.zprofile' for non-login sessions, enable it
if [[ ! -o login ]] && [[ -s "$ZDOTDIR/.zprofile" ]]; then
	source "$ZDOTDIR/.zprofile"
fi

# <<< end <<<
