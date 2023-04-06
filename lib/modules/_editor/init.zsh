if [[ -n "$DISPLAY" ]]; then
  # gui mode
  if command -v gnome-text-editor &>/dev/null; then
    export EDITOR="$(command -v gnome-text-editor) -s"
    export VISUAL="$EDITOR"
  elif command -v gedit &>/dev/null; then
    export EDITOR="$(command -v gedit) -s"
    export VISUAL="$EDITOR"
  fi
else
  # console mode
  if command -v vim &>/dev/null; then
    export EDITOR="$(command -v vim)"
    export VISUAL="$EDITOR"
  elif command -v nano &>/dev/null; then
    export EDITOR="$(command -v nano)"
    export VISUAL="$EDITOR"
  fi
fi
