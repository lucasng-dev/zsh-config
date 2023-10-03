DBX_CONTAINER_MANAGER=docker
if [[ -z "${CONTAINER_ID:-}" ]]; then
  if zsh -c 'command -v podman' &>/dev/null; then DBX_CONTAINER_MANAGER=podman; fi
else
  if /usr/bin/distrobox-host-exec zsh -c 'command -v podman' &>/dev/null; then DBX_CONTAINER_MANAGER=podman; fi
fi
export DBX_CONTAINER_MANAGER

function @box() {
  case "${1:-}" in
  help | --help | -h) __box_help ;;
  exists) __box_exists ;;
  create) __box_create ;;
  run) shift 1 && __box_run "$@" ;;
  enter) __box_enter ;;
  stats) __box_stats ;;
  logs) __box_logs ;;
  stop) __box_stop ;;
  rm) __box_rm ;;
  upgrade) __box_upgrade ;;
  *) if [[ $# -gt 0 ]]; then __box_run "$@"; else __box_enter; fi ;;
  esac
}

function @host() {
  case "${1:-}" in
  help | --help | -h) __host_help ;;
  run) shift 1 && __host_run "$@" ;;
  enter) __host_enter ;;
  logs) __host_logs ;;
  upgrade) __host_upgrade ;;
  *) if [[ $# -gt 0 ]]; then __host_run "$@"; else __host_enter; fi ;;
  esac
}

function __box_help() {
  command cat <<EOF
Run commands on distrobox container.

If the shell script '~/.box' exists, it is used for provisioning the container during
'@box create' or '@box upgrade' commands, allowing to add any extra package or feature.

Usage:
  @box [ACTION | COMMANDS...]

Actions:
  @box [COMMANDS...]        run a command on container or open an interactive shell
  @box create               create and provision the container
  @box enter                open an interactive shell on container
  @box exists               check if the container exists, shows an error message if not
  @box help                 show this help
  @box logs                 show the container logs
  @box rm                   remove the container
  @box run [COMMANDS...]    run a command on container
  @box stats                show the container stats
  @box stop                 stop the container
  @box upgrade              upgrade and run the ~/.box provision script on container

See also:
  @host [COMMANDS...]       run a command on host when inside the container
EOF
}

function __host_help() {
  command cat <<EOF
Run commands on host.

If the shell script '~/.host' exists, it is used for provisioning the host during
'@host upgrade' command.

Usage:
  @host [ACTION | COMMANDS...]

Actions:
  @host [COMMANDS...]       run a command on host or open an interactive shell
  @host help                show this help
  @host logs                show the host logs
  @host run [COMMANDS...]   run a command on host
  @host upgrade             upgrade and run the ~/.host provision script on host

See also:
  @box [COMMANDS...]        run a command inside the container when on host
EOF
}

function __box_exists() {
  if [[ -z "${CONTAINER_ID:-}" ]]; then
    "$DBX_CONTAINER_MANAGER" container inspect distrobox &>/dev/null ||
      { echo "Container 'distrobox' does not exist!" 1>&2 && return 1; }
  else
    return 0
  fi
}

function __box_create() {
  echo && echo '### BOX CREATE ###' && echo
  if [[ -z "${CONTAINER_ID:-}" ]]; then
    __box_exists &>/dev/null && echo 'Container already exists!' 1>&2 && return 1
    local image=quay.io/toolbx-images/archlinux-toolbox:latest
    local env_path="$HOME/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"
    local restart_policy=no
    if [[ "$DBX_CONTAINER_MANAGER" == 'podman' ]]; then
      restart_policy=unless-stopped
    fi
    local base_packages='base-devel bat git less lesspipe neovim zsh'
    distrobox-create --yes --no-entry --name distrobox \
      --pull --image "$image" \
      --additional-flags "--env 'PATH=$env_path' --hostname '$HOSTNAME' --restart '$restart_policy'" \
      --additional-packages "$base_packages" &&
      { "$DBX_CONTAINER_MANAGER" image prune --force &>/dev/null || true; } &&
      __box_upgrade &&
      __box_enter
  else
    echo "Command 'create' unavailable inside the distrobox container!" 1>&2 && return 126
  fi
}

function __box_run() {
  if [[ -z "${CONTAINER_ID:-}" ]]; then
    __box_exists && distrobox-enter --name distrobox -- "$@"
  else
    "$@"
  fi
}

function __host_run() {
  if [[ -n "${CONTAINER_ID:-}" ]]; then
    /usr/bin/distrobox-host-exec "$@"
  else
    "$@"
  fi
}

function __box_enter() {
  if [[ -z "${CONTAINER_ID:-}" ]]; then
    __box_run /usr/bin/zsh -l
  else
    return 0
  fi
}

function __host_enter() {
  if [[ -n "${CONTAINER_ID:-}" ]]; then
    __host_run zsh -l
  else
    return 0
  fi
}

function __box_stats() {
  __host_run watch "$DBX_CONTAINER_MANAGER" container stats --no-stream distrobox
}

function __box_logs() {
  __host_run "$DBX_CONTAINER_MANAGER" container logs --follow distrobox
}

function __host_logs() {
  __host_run journalctl -xef
}

function __box_stop() {
  echo && echo '### BOX STOP ###' && echo
  if [[ -z "${CONTAINER_ID:-}" ]]; then
    distrobox-stop --yes --name distrobox
  else
    echo "Command 'stop' unavailable inside the distrobox container!" 1>&2 && return 126
  fi
}

function __box_rm() {
  echo && echo '### BOX REMOVE ###' && echo
  if [[ -z "${CONTAINER_ID:-}" ]]; then
    __box_stop &>/dev/null || true
    distrobox-rm --force `#--name` distrobox
  else
    echo "Command 'rm' unavailable inside the distrobox container!" 1>&2 && return 126
  fi
}

function __box_upgrade() {
  if [[ -z "${CONTAINER_ID:-}" ]]; then
    __box_run /usr/bin/zsh -i -c __box_upgrade
    return $?
  fi
  echo && echo '### BOX UPGRADE ###' && echo
  (
    set -eu -o pipefail

    echo '*** ZSH ***'
    /usr/bin/sudo usermod --shell /usr/bin/zsh "$(id -nu)"
    echo '>>> OK <<<' && echo

    echo '*** PACMAN ***'
    /usr/bin/sudo pacman-key --init
    /usr/bin/sudo sed -i '/^\(Color\|ILoveCandy\)\s*$/d' /etc/pacman.conf
    /usr/bin/sudo sed -i 's/^\(#\s*Misc options\s*\)$/\1\nColor\nILoveCandy/g' /etc/pacman.conf
    echo '>>> OK <<<' && echo

    echo '*** YAY ***'
    local builddir=~/.cache/yay
    mkdir -p "$builddir"
    if ! /usr/bin/zsh -c 'command -v yay' &>/dev/null; then
      rm -rf "$builddir/yay-bin"
      git clone https://aur.archlinux.org/yay-bin.git "$builddir/yay-bin"
      /usr/bin/zsh -c "cd '$builddir/yay-bin' && makepkg -si --noconfirm --needed --clean --cleanbuild --skippgpcheck"
    fi
    rm -f ~/.config/yay/config.json
    yay -Y --save --needed --devel --builddir "$builddir" --batchinstall --nocombinedupgrade --cleanafter --removemake \
      --nocleanmenu --answerclean A --nodiffmenu --answerdiff N --editmenu --answeredit A --editor /usr/bin/nvim \
      --mflags '--noconfirm --needed --clean --cleanbuild --skippgpcheck'
    echo '>>> OK <<<' && echo

    echo '*** BASE PACKAGES ***'
    yay -Syu --noconfirm
    yay -S --noconfirm --needed --repo \
      bat bc bind btop cmatrix curl direnv eza fd ffmpeg fzf git git-lfs htop imagemagick inetutils inxi iperf3 jq less lesspipe \
      mc mtr ncdu neofetch neovim net-tools onefetch openssl p7zip rsync shellcheck shfmt speedtest-cli tldr tmux traceroute tree \
      unarchiver unrar unzip xclip xsel wget whois wl-clipboard yq zip
    echo '>>> OK <<<' && echo

    echo '*** REDIRECT HOST COMMANDS ***'
    /usr/bin/distrobox-host-exec --yes true # download host-spawn
    local host_cmd
    for host_cmd in xdg-open docker docker-compose podman podman-compose flatpak snap; do
      if __host_run zsh -c "command -v '$host_cmd'" &>/dev/null; then
        echo "command: $host_cmd"
        /usr/bin/sudo ln -sfT /usr/bin/distrobox-host-exec "/usr/local/bin/$host_cmd"
      fi
    done
    echo 'command: sudo (wrapper)'
    /usr/bin/sudo tee /usr/local/bin/sudo >/dev/null <<EOF
#!/usr/bin/zsh
host_bin=\$(echo "\${1:-}" | sed 's|^/usr/local/bin/||')
if [[ -n "\$(find /usr/local/bin/ -mindepth 1 -maxdepth 1 -name "\$host_bin" -lname /usr/bin/distrobox-host-exec 2>/dev/null)" ]]; then
  shift 1 && exec /usr/bin/distrobox-host-exec sudo -p "[sudo] password for \$(id -nu) (host): " "\$host_bin" "\$@" # host sudo
fi
exec /usr/bin/sudo "\$@" # container sudo
EOF
    /usr/bin/sudo chmod +x /usr/local/bin/sudo
    echo '>>> OK <<<' && echo

    if [[ -s ~/.box ]]; then
      echo '*** PROVISIONING SCRIPT ***'
      /usr/bin/zsh -eu -o pipefail ~/.box
      echo '>>> OK <<<' && echo
    fi

    echo '*** CLEANUP ***'
    { yay -Qtdq | yay -Rns --noconfirm - &>/dev/null || true; }
    yay -Sc --noconfirm >/dev/null
    echo '>>> OK <<<' && echo
  )
}

function __host_upgrade() {
  if [[ -n "${CONTAINER_ID:-}" ]]; then
    __host_run zsh -i -c __host_upgrade
    return $?
  fi
  echo && echo '### HOST UPGRADE ###' && echo
  (
    set -eu -o pipefail

    if command -v rpm-ostree &>/dev/null; then
      echo '*** UPGRADE: RPM-OSTREE ***' && sudo rpm-ostree upgrade && echo '>>> OK <<<' && echo
    elif command -v dnf &>/dev/null; then
      echo '*** UPGRADE: DNF ***' && sudo dnf upgrade -y && echo '>>> OK <<<' && echo
    elif command -v yum &>/dev/null; then
      echo '*** UPGRADE: YUM ***' && sudo yum upgrade -y && echo '>>> OK <<<' && echo
    elif command -v apt &>/dev/null; then
      echo '*** UPGRADE: APT ***' && sudo apt update && sudo apt upgrade -y && echo '>>> OK <<<' && echo
    elif command -v yay &>/dev/null; then
      echo '*** UPGRADE: YAY ***' && yay -Syu --noconfirm && echo '>>> OK <<<' && echo
    elif command -v pacman &>/dev/null; then
      echo '*** UPGRADE: PACMAN ***' && sudo pacman -Syu --noconfirm && echo '>>> OK <<<' && echo
    fi
    if command -v flatpak &>/dev/null; then
      echo '*** UPGRADE: FLATPAK ***' && sudo flatpak update -y && echo '>>> OK <<<' && echo
    fi
    if command -v snap &>/dev/null; then
      echo '*** UPGRADE: SNAP ***' && sudo snap refresh && echo '>>> OK <<<' && echo
    fi

    if [[ -s ~/.host ]]; then
      echo '*** PROVISIONING SCRIPT ***'
      zsh -eu -o pipefail ~/.host
      echo '>>> OK <<<' && echo
    fi

    if command -v rpm-ostree &>/dev/null; then
      echo '*** CLEANUP: RPM-OSTREE ***' && true && echo '>>> OK <<<' && echo
    elif command -v dnf &>/dev/null; then
      echo '*** CLEANUP: DNF ***' && sudo dnf autoremove -y && echo '>>> OK <<<' && echo
    elif command -v yum &>/dev/null; then
      echo '*** CLEANUP: YUM ***' && sudo yum autoremove -y && echo '>>> OK <<<' && echo
    elif command -v apt &>/dev/null; then
      echo '*** CLEANUP: APT ***' && sudo apt autoremove -y && echo '>>> OK <<<' && echo
    elif command -v yay &>/dev/null; then
      echo '*** CLEANUP: YAY ***' && { yay -Qtdq | yay -Rns --noconfirm - 2>/dev/null || true; } && yay -Sc --noconfirm && echo '>>> OK <<<' && echo
    elif command -v pacman &>/dev/null; then
      echo '*** CLEANUP: PACMAN ***' && { sudo pacman -Qtdq | sudo pacman -Rns --noconfirm - 2>/dev/null || true; } && sudo pacman -Sc --noconfirm && echo '>>> OK <<<' && echo
    fi
    if command -v flatpak &>/dev/null; then
      echo '*** CLEANUP: FLATPAK ***' && sudo flatpak uninstall --unused -y && echo '>>> OK <<<' && echo
    fi
    if command -v snap &>/dev/null; then
      echo '*** CLEANUP: SNAP ***' && (
        local name version rev tracking publisher notes
        # shellcheck disable=SC2034
        while read -r name version rev tracking publisher notes; do
          if [[ "$notes" == *disabled* ]]; then
            sudo snap remove "$name" --revision="$rev"
          fi
        done < <(LANG=C snap list --all)
      ) && echo '>>> OK <<<' && echo
    fi
  )
}
