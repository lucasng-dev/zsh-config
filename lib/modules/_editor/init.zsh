# console mode
if command -v vim &>/dev/null; then
  export EDITOR=vim
elif command -v nano &>/dev/null; then
  export EDITOR=nano
fi

# gui mode
if [[ -n "$DISPLAY" ]]; then
  if command -v gnome-text-editor &>/dev/null; then
    export EDITOR='gnome-text-editor -s'
  elif command -v gedit &>/dev/null; then
    export EDITOR='gedit -s'
  fi
fi

export VISUAL=$EDITOR
