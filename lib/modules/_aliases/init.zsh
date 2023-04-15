alias c='clear'

alias @zshup='git -C "$ZDOTDIR/.." pull >/dev/null; zsh "$ZDOTDIR/../install.zsh"'

function __upgrade() {
  if command -v rpm-ostree &>/dev/null; then
    echo && echo "### RPM-OSTREE ###" && rpm-ostree upgrade
  elif command -v dnf &>/dev/null; then
    echo && echo "### DNF ###" && sudo dnf upgrade && sudo dnf autoremove -y
  elif command -v apt-get &>/dev/null; then
    echo && echo "### APT ###" && sudo apt-get update && sudo apt-get upgrade && sudo apt-get autoremove -y
  elif command -v pacman &>/dev/null; then
    echo && echo "### PACMAN ###" && sudo pacman -Syu && { sudo pacman -Qtdq | sudo pacman --noconfirm -Rns - &>/dev/null || true; }
  fi
  if command -v flatpak &>/dev/null; then
    echo && echo "### FLATPAK ###" && flatpak update && flatpak uninstall --unused -y
  fi
}
alias @upgrade="__upgrade"
