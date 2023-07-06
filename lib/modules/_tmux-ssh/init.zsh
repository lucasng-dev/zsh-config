# shellcheck shell=bash

if command -v tmux &>/dev/null && tty -s && [[ -z "$TMUX" ]] && [[ -n "$TERM" ]] && [[ -n "$SSH_TTY" ]]; then
  session_name=$(id -nu)
  if tmux has-session -t "$session_name" &>/dev/null; then
    exec tmux attach-session -t "$session_name"
  else
    exec tmux new-session -s "$session_name"
  fi
  unset session_name
fi
