if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
#source "$ZDOTDIR/.zprezto/runcoms/zlogout"
if [[ -s ~/.zlogout ]]; then source ~/.zlogout; fi
