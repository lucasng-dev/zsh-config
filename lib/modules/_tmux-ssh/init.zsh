[[ -n "${ZDOTDIR:-}" ]] || return 1

if whence -p tmux &>/dev/null; then
	if [[ -n "${CONTAINER_ID:-}" ]]; then
		export TMUX_TMPDIR="${XDG_CACHE_HOME:-$HOME/.cache}/$CONTAINER_ID/tmux"
		command mkdir -p "$TMUX_TMPDIR"
	fi
	if [[ -o interactive ]] && [[ -n "${SSH_TTY:-}" ]] && [[ -z "${TMUX:-}" ]]; then
		session_id=$(command tmux list-sessions -F '#{session_id}' -f '#{==:#{session_attached},0}' 2>/dev/null | command tail -n 1)
		if [[ -n "$session_id" ]]; then
			exec tmux attach-session -t "$session_id" -d
		else
			exec tmux new-session
		fi
	fi
fi
