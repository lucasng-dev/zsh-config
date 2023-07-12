# shellcheck disable=SC2154
export STARSHIP_CONFIG=$ZDOTDIR/starship.toml
alias starship='"$ZDOTDIR/.starship/starship"'
eval "$(starship init zsh)"
