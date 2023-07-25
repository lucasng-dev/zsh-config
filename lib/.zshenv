if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
SHLVL=1 source "$ZDOTDIR/.zprezto/runcoms/zshenv"
