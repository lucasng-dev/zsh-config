### check ###
if [[ -z "${ZDOTDIR:-}" ]]; then
  return 1
fi

### prezto: https://github.com/sorin-ionescu/prezto/blob/master/runcoms/zprofile ###
source "$ZDOTDIR/.zprezto/runcoms/zprofile"

### project ###
# remove '-X' option added by prezto's 'zprofile' (restore: mouse-wheel + screen clearing)
export LESS="${LESS/-X/}"

### local ###
if [[ -s "$HOME/.zprofile" ]]; then
  source "$HOME/.zprofile"
fi
