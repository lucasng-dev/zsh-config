### check ###
if [[ -z "${ZDOTDIR:-}" ]]; then
  return 1
fi

### prezto: https://github.com/sorin-ionescu/prezto/blob/master/runcoms/zlogin ###
source "$ZDOTDIR/.zprezto/runcoms/zlogin"

### project ###
#...

### local ###
if [[ -s "$HOME/.zlogin" ]]; then
  source "$HOME/.zlogin"
fi
