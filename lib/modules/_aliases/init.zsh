alias c='clear'

alias @zshup='git -C "$ZDOTDIR/.." pull >/dev/null; zsh "$ZDOTDIR/../install.zsh"'

function @upgrade() {
  if command -v rpm-ostree &>/dev/null; then
    echo && echo "### RPM-OSTREE ###" && sudo rpm-ostree upgrade
  elif command -v dnf &>/dev/null; then
    echo && echo "### DNF ###" && sudo dnf upgrade && sudo dnf autoremove -y
  elif command -v apt &>/dev/null; then
    echo && echo "### APT ###" && sudo apt update && sudo apt upgrade && sudo apt autoremove -y
  elif command -v pacman &>/dev/null; then
    echo && echo "### PACMAN ###" && sudo pacman -Syu && { sudo pacman -Qtdq | sudo pacman --noconfirm -Rns - &>/dev/null || true; }
  fi
  if command -v flatpak &>/dev/null; then
    echo && echo "### FLATPAK ###" && sudo flatpak update && sudo flatpak uninstall --unused -y
  fi
}
