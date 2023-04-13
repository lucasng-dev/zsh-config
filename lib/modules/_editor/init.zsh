# console mode
if command -v vim &>/dev/null; then
  export EDITOR="$(command -v vim)"
elif command -v nano &>/dev/null; then
  export EDITOR="$(command -v nano)"
fi

# gui mode
if [[ -n "$DISPLAY" ]]; then
  if command -v gnome-text-editor &>/dev/null; then
    export EDITOR="$(command -v gnome-text-editor) -s"
  elif command -v gedit &>/dev/null; then
    export EDITOR="$(command -v gedit) -s"
  fi
fi

export VISUAL="$EDITOR"
