if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
source "$ZDOTDIR/.zprezto/runcoms/zshrc"
if [[ -s ~/.zshrc ]]; then source ~/.zshrc; fi
