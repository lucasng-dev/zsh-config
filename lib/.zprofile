if [[ -z "${ZDOTDIR:-}" ]]; then return 1; fi
source "$ZDOTDIR/.zprezto/runcoms/zprofile"

# >>> begin >>>

# editors
if command -v nvim &>/dev/null; then
  export EDITOR=nvim
elif command -v vim &>/dev/null; then
  export EDITOR=vim
elif command -v nano &>/dev/null; then
  export EDITOR=nano
fi
export VISUAL=$EDITOR

# paths
# shellcheck disable=SC2034
typeset -gU cdpath fpath mailpath path
# shellcheck disable=SC1036,SC2206
path=(
  ~/.local/bin(N)
  /opt/homebrew/{,s}bin(N)
  /var/lib/snapd/snap/bin(N)
  /var/lib/flatpak/exports/bin(N)
  /opt/local/{,s}bin(N)
  /usr/local/{,s}bin(N)
  /usr/{,s}bin(N)
  /{,s}bin(N)
  $path
)

# less
export LESS=${LESS/-X/} # restore mouse-wheel + screen clearing
export LESSHISTFILE='-' # disable history

# <<< end <<<

_src_user_profile() { emulate -L ksh && if [[ -s ~/.profile ]]; then source ~/.profile; fi; }
_src_user_profile
unset -f _src_user_profile
if [[ -s ~/.zprofile ]]; then source ~/.zprofile; fi
