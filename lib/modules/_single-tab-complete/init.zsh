function single-tab-complete() {
  # https://unix.stackexchange.com/a/32426
  if [[ "$BUFFER" =~ ^\\s*$ ]]; then
    BUFFER="cd "
    CURSOR=3
  fi
  # https://github.com/sorin-ionescu/prezto/blob/master/modules/editor/init.zsh
  expand-or-complete-with-indicator
}
zle -N single-tab-complete
bindkey '^I' single-tab-complete
