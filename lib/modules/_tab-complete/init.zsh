[[ -n "${ZDOTDIR:-}" ]] || return 1

function __tab_complete() {
	# https://unix.stackexchange.com/a/32426
	if [[ "$BUFFER" =~ ^\\s*$ ]]; then
		BUFFER='cd '
		# shellcheck disable=SC2034
		CURSOR=3
	fi
	# https://github.com/sorin-ionescu/prezto/blob/master/modules/editor/init.zsh
	expand-or-complete-with-indicator
}
zle -N __tab_complete
bindkey '^I' __tab_complete
