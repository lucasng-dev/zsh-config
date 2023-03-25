### check ###
if [[ -z "${ZDOTDIR:-}" ]]; then
  return 1
fi

### prezto: https://github.com/sorin-ionescu/prezto/blob/master/runcoms/zshrc ###
source "$ZDOTDIR/.zprezto/runcoms/zshrc"

### project ###
#...

### local ###
if [[ -s "$HOME/.zshrc" ]]; then
  source "$HOME/.zshrc"
fi
