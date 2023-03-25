### check ###
if [[ -z "${ZDOTDIR:-}" ]]; then
  return 1
fi

### prezto: https://github.com/sorin-ionescu/prezto/blob/master/runcoms/zshenv ###
source "$ZDOTDIR/.zprezto/runcoms/zshenv"

### project ###
#...

### local ###
# cannot source, it is already loaded
