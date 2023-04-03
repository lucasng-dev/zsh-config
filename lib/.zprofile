### check ###
if [[ -z "${ZDOTDIR:-}" ]]; then
  return 1
fi

### prezto: https://github.com/sorin-ionescu/prezto/blob/master/runcoms/zprofile ###
source "$ZDOTDIR/.zprezto/runcoms/zprofile"

### project ###
#...

### local ###
if [[ -s "$HOME/.zprofile" ]]; then
  source "$HOME/.zprofile"
fi
