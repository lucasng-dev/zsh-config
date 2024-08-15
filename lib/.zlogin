if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
source "$ZDOTDIR/.zprezto/runcoms/zlogin"

# shellcheck disable=SC1091
if [[ -s "$ZDOTDIR/../custom/.zlogin" ]]; then source "$ZDOTDIR/../custom/.zlogin"; fi
