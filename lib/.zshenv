### check ###
if [[ -z "${ZDOTDIR:-}" ]]; then
  return 1
fi

### prezto: https://github.com/sorin-ionescu/prezto/blob/master/runcoms/zshenv ###
source "$ZDOTDIR/.zprezto/runcoms/zshenv"

### project ###

# PATH
typeset -gU path
path=(
  ~/.local/bin(N)
  /usr/local/bin(N)
  /usr/local/sbin(N)
  /usr/bin(N)
  /usr/sbin(N)
  $path
)
export PATH

### local ###
# cannot source, it is already loaded
