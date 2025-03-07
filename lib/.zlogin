[[ -n "${ZDOTDIR:-}" ]] || return 1
source "$ZDOTDIR/.zprezto/runcoms/zlogin"
[[ ! -s "$ZDOTDIR/../custom/.zlogin" ]] || source "$ZDOTDIR/../custom/.zlogin"
