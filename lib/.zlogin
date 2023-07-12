if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
source "$ZDOTDIR/.zprezto/runcoms/zlogin"
if [[ -s ~/.zlogin ]]; then source ~/.zlogin; fi
