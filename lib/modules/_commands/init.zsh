alias @zshup='git -C "$ZDOTDIR/.." pull >/dev/null; zsh "$ZDOTDIR/../install.zsh"'

alias c='clear'
alias x='exit'
alias s='ssh'
alias g='git'

alias ping='ping -O'

if command -v bat &>/dev/null; then
  alias cat='bat'
fi

if command -v exa &>/dev/null; then
  alias ls='exa --color=always --icons --group-directories-first --group --header --octal-permissions'
  alias l='ls -1a'
  alias ll='ls -l'
  alias la='ls -la'
fi

if ! command -v docker &>/dev/null && command -v podman &>/dev/null; then
  alias docker='podman'
fi
if ! command -v docker-compose &>/dev/null && command -v podman-compose &>/dev/null; then
  alias docker-compose='podman-compose'
fi

function @upgrade() {
  if command -v rpm-ostree &>/dev/null; then
    echo && echo '### RPM-OSTREE ###' && sudo rpm-ostree upgrade
  elif command -v dnf &>/dev/null; then
    echo && echo '### DNF ###' && sudo dnf upgrade && sudo dnf autoremove -y
  elif command -v yum &>/dev/null; then
    echo && echo '### YUM ###' && sudo yum upgrade && sudo yum autoremove -y
  elif command -v apt &>/dev/null; then
    echo && echo '### APT ###' && sudo apt update && sudo apt upgrade && sudo apt autoremove -y
  elif command -v pacman &>/dev/null; then
    echo && echo '### PACMAN ###' && sudo pacman -Syu && { sudo pacman -Qtdq | sudo pacman --noconfirm -Rns - &>/dev/null || true; }
  fi
  if command -v flatpak &>/dev/null; then
    echo && echo '### FLATPAK ###' && sudo flatpak update && sudo flatpak uninstall --unused -y
  fi
  if command -v snap &>/dev/null; then
    echo && echo '### SNAP ###' && sudo snap refresh && (
      # shellcheck disable=SC2034
      LANG=C snap list --all |
        while read -r name version rev tracking publisher notes; do
          if [[ "$notes" == *disabled* ]]; then
            sudo snap remove "$name" --revision="$rev"
          fi
        done
    )
  fi
}
