### check ###
if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi

### prezto: https://github.com/sorin-ionescu/prezto/blob/master/runcoms/zlogout ###
source "$ZDOTDIR/.zprezto/runcoms/zlogout"

### project ###
#...

### local ###
if [[ -s ~/.zlogout ]]; then source ~/.zlogout; fi
