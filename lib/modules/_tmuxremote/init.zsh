if command -v tmux &>/dev/null && tty -s && [[ -z "$TMUX" && -n "$TERM" && -n "$SSH_TTY" ]]; then
  if tmux ls | grep "^$USER:" &>/dev/null; then
    exec tmux attach -t "$USER"
  else
    exec tmux new -s "$USER"
  fi
fi
