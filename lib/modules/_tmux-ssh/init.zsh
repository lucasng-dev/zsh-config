if command -v tmux &>/dev/null && tty -s && [[ -z "$TMUX" ]] && [[ -n "$TERM" ]] && [[ -n "$SSH_TTY" ]]; then
  if tmux has-session -t SSH &>/dev/null; then
    exec tmux attach-session -t SSH
  else
    exec tmux new-session -s SSH
  fi
fi
