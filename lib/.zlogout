[[ -n "${ZDOTDIR:-}" ]] || return 1
# source "$ZDOTDIR/.zprezto/runcoms/zlogout"
[[ ! -s "$ZDOTDIR/../custom/.zlogout" ]] || source "$ZDOTDIR/../custom/.zlogout"
