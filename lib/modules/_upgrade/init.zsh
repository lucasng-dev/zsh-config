function @zshup() {
  # shellcheck disable=SC2154
  git -C "$ZDOTDIR/.." pull >/dev/null && zsh "$ZDOTDIR/../install.zsh"
}

function @upgrade() {
  (
    set -eu -o pipefail
    @zshup
    @host upgrade
    if @box exists &>/dev/null; then
      @box upgrade
    fi
  )
}
