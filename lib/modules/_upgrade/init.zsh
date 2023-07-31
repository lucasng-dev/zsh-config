function @upgrade() {
  if [[ -f /run/.containerenv ]] || [[ -f /.dockerenv ]]; then
    echo && echo '### DISTROBOX ###' && @box upgrade
    return $?
  fi
  if command -v rpm-ostree &>/dev/null; then
    echo && echo '### RPM-OSTREE ###' && sudo rpm-ostree upgrade
  elif command -v dnf &>/dev/null; then
    echo && echo '### DNF ###' && sudo dnf upgrade && sudo dnf autoremove -y
  elif command -v yum &>/dev/null; then
    echo && echo '### YUM ###' && sudo yum upgrade && sudo yum autoremove -y
  elif command -v apt &>/dev/null; then
    echo && echo '### APT ###' && sudo apt update && sudo apt upgrade && sudo apt autoremove -y
  elif command -v yay &>/dev/null; then
    echo && echo '### YAY ###' && yay -Syu && { yay -Qtdq | yay -Rns --noconfirm - &>/dev/null || true; }
  elif command -v pacman &>/dev/null; then
    echo && echo '### PACMAN ###' && sudo pacman -Syu && { sudo pacman -Qtdq | sudo pacman -Rns --noconfirm - &>/dev/null || true; }
  fi
  if command -v flatpak &>/dev/null; then
    echo && echo '### FLATPAK ###' && sudo flatpak update && sudo flatpak uninstall --unused -y
  fi
  if command -v snap &>/dev/null; then
    echo && echo '### SNAP ###' && sudo snap refresh && (
      local name version rev tracking publisher notes
      # shellcheck disable=SC2034
      while read -r name version rev tracking publisher notes; do
        if [[ "$notes" == *disabled* ]]; then
          sudo snap remove "$name" --revision="$rev"
        fi
      done < <(LANG=C snap list --all)
    )
  fi
}
