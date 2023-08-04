# detect: host or container
if [[ ! -f /run/.containerenv ]] && [[ ! -f /.dockerenv ]]; then __is_host=true; else __is_host=''; fi

# @box
function @box() {
  case "${1:-}" in
  help) __box_help ;;
  exists) __box_exists ;;
  create) __box_create ;;
  enter) __box_enter ;;
  run) shift 1 && __box_run "$@" ;;
  stats) __box_stats ;;
  logs) __box_logs ;;
  stop) __box_stop ;;
  rm) __box_rm ;;
  upgrade) __box_upgrade ;;
  *) if [[ $# -gt 0 ]]; then __box_run "$@"; else __box_enter; fi ;;
  esac
}

# @host
if [[ -n "$__is_host" ]]; then
  function @host() { "$@"; }
else
  function @host() { /usr/bin/distrobox-host-exec "$@"; }
fi

# detect: container manager
if @host zsh -c 'command -v podman' &>/dev/null; then __is_podman=true; else __is_podman=''; fi

# __box_help
function __box_help() {
  command cat <<EOF
Create a distrobox container using some opinionated defaults.

If the shell script '~/.box' exists, it is used for provisioning the container during
create/upgrade processes, allowing to add any extra package or feature.

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
  @box upgrade              upgrade and provision the container

Extras:
  @host [COMMANDS...]       run a command on host when inside the container
EOF
}

# __box_exists
if [[ -n "$__is_podman" ]]; then
  function __box_exists() { @host podman container exists distrobox &>/dev/null || { echo 'Container does not exist!' 1>&2 && return 1; }; }
else
  function __box_exists() { @host docker container inspect distrobox &>/dev/null || { echo 'Container does not exist!' 1>&2 && return 1; }; }
fi

# __box_image_prune
if [[ -n "$__is_podman" ]]; then
  function __box_image_prune() { @host podman image prune --force &>/dev/null || true; }
else
  function __box_image_prune() { @host docker image prune --force &>/dev/null || true; }
fi

# __box_create
if [[ -n "$__is_host" ]]; then
  function __box_create() {
    __box_exists &>/dev/null && echo 'Container already exists!' 1>&2 && return 1
    @host distrobox-create --yes --no-entry --name distrobox \
      --pull --image quay.io/toolbx-images/archlinux-toolbox:latest \
      --additional-flags "--hostname '$(@host uname -n)'" \
      --additional-packages 'base-devel bat git less lesspipe neovim zsh' &&
      __box_image_prune &&
      __box_upgrade &&
      __box_enter
  }
else
  function __box_create() { echo "Command 'create' unavailable on distrobox container!" 1>&2 && return 1; }
fi

# __box_enter
if [[ -n "$__is_host" ]]; then
  function __box_enter() { __box_exists && @host distrobox-enter --name distrobox -- /usr/bin/zsh -l; }
else
  function __box_enter() { return 0; }
fi

# __box_run
if [[ -n "$__is_host" ]]; then
  function __box_run() { __box_exists && @host distrobox-enter --name distrobox -- "$@"; }
else
  function __box_run() { "$@"; }
fi

# __box_stats
if [[ -n "$__is_podman" ]]; then
  function __box_stats() { @host watch podman container stats --no-stream distrobox; }
else
  function __box_stats() { @host watch docker container stats --no-stream distrobox; }
fi

# __box_logs
if [[ -n "$__is_podman" ]]; then
  function __box_logs() { @host podman container logs --follow distrobox; }
else
  function __box_logs() { @host docker container logs --follow distrobox; }
fi

# __box_stop
if [[ -n "$__is_host" ]]; then
  function __box_stop() { @host distrobox-stop --yes --name distrobox; }
else
  function __box_stop() { echo "Command 'stop' unavailable on distrobox container!" 1>&2 && return 1; }
fi

# __box_rm
if [[ -n "$__is_host" ]]; then
  function __box_rm() {
    __box_stop &>/dev/null || true
    @host distrobox-rm --force `#--name` distrobox
  }
else
  function __box_rm() { echo "Command 'rm' unavailable on distrobox container!" 1>&2 && return 1; }
fi

# __box_upgrade
function __box_upgrade() {
  (
    set -eu -o pipefail

    # init  container
    __box_run echo

    echo '*** ZSH ***'
    __box_run sudo usermod --shell /usr/bin/zsh "$(id -nu)" >/dev/null
    echo '>>> OK <<<'
    echo

    echo '*** PACMAN ***'
    __box_run sudo sed -i '/^#Color$/c\Color' /etc/pacman.conf
    echo '>>> OK <<<'
    echo

    echo '*** YAY ***'
    local builddir
    builddir=~/.cache/yay
    __box_run mkdir -p "$builddir"
    if ! __box_run /usr/bin/zsh -c 'command -v yay' &>/dev/null; then
      __box_run rm -rf "$builddir/yay-bin"
      __box_run git clone https://aur.archlinux.org/yay-bin.git "$builddir/yay-bin"
      __box_run /usr/bin/zsh -c "cd '$builddir/yay-bin' && makepkg -si --noconfirm --needed --clean --cleanbuild"
    fi
    __box_run rm -f ~/.config/yay/config.json
    __box_run yay -Y --save --needed --devel --builddir "$builddir" --batchinstall --nocombinedupgrade --cleanafter --removemake \
      --nocleanmenu --answerclean A --nodiffmenu --answerdiff N --editmenu --answeredit A --editor /usr/bin/nvim \
      --mflags '--noconfirm --needed --clean --cleanbuild'
    echo '>>> OK <<<'
    echo

    echo '*** BASE PACKAGES ***'
    __box_run yay -Syu --noconfirm
    __box_run yay -S --noconfirm --needed --repo \
      bat bind btop cmatrix curl direnv exa ffmpeg fzf git git-lfs htop imagemagick inetutils inxi jq less lesspipe \
      mc ncdu neofetch neovim net-tools onefetch openssl p7zip shellcheck shfmt speedtest-cli tldr tmux traceroute \
      unarchiver unrar unzip xclip xsel wget whois wl-clipboard yq zip
    echo '>>> OK <<<'
    echo

    echo '*** REDIRECT HOST COMMANDS ***'
    __box_run /usr/bin/distrobox-host-exec --yes true # download host-spawn
    local host_cmd
    for host_cmd in xdg-open docker docker-compose podman podman-compose flatpak snap; do
      if @host zsh -c "command -v '$host_cmd'" &>/dev/null; then
        echo "command: $host_cmd"
        __box_run sudo ln -sfT /usr/bin/distrobox-host-exec "/usr/local/bin/$host_cmd"
      fi
    done
    echo 'command: sudo (wrapper)'
    __box_run /usr/bin/sudo tee /usr/local/bin/sudo >/dev/null <<EOF
#!/usr/bin/zsh
host_bin=\$(echo "\${1:-}" | sed 's|^/usr/local/bin/||')
if [[ -n "\$(find /usr/local/bin/ -mindepth 1 -maxdepth 1 -name "\$host_bin" -lname /usr/bin/distrobox-host-exec 2>/dev/null)" ]]; then
  shift && exec /usr/bin/distrobox-host-exec sudo -p "[sudo] password for \$(id -nu) (host): " "\$host_bin" "\$@" # host sudo
fi
exec /usr/bin/sudo "\$@" # container sudo
EOF
    __box_run sudo chmod +x /usr/local/bin/sudo
    echo '>>> OK <<<'
    echo

    if [[ -s ~/.box ]]; then
      echo '*** PROVISIONING SCRIPT ***'
      __box_run /usr/bin/zsh -euxf -o pipefail ~/.box
      echo '>>> OK <<<'
      echo
    fi

    echo '*** CLEANUP ***'
    __box_run /usr/bin/zsh -c 'yay -Qtdq | yay -Rns --noconfirm -' &>/dev/null || true
    __box_run yay -Sc --noconfirm >/dev/null
    echo '>>> OK <<<'
    echo
  )
}

# cleanup
unset __is_{host,podman}
