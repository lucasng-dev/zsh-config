if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
#source "$ZDOTDIR/.zprezto/runcoms/zlogout"

# shellcheck disable=SC1091
if [[ -s "$ZDOTDIR/../custom/.zlogout" ]]; then source "$ZDOTDIR/../custom/.zlogout"; fi
