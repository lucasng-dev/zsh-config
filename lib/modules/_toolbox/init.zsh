# detect: host or container
if [[ -f /run/.containerenv ]] || [[ -f /.dockerenv ]]; then box_is_container=true; else box_is_container=''; fi

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
if [[ "$box_is_container" ]]; then
  function @host() { /usr/local/bin/host-spawn "$@"; }
else
  function @host() { "$@"; }
fi

# detect: container managers
if @host command -pv toolbox &>/dev/null; then host_uses_toolbox=true; else host_uses_toolbox=''; fi
if @host command -pv podman &>/dev/null; then host_uses_podman=true; else host_uses_podman=''; fi

# __box_help
function __box_help() {
  \cat <<EOF

Create a toolbox/distrobox container using a Fedora image with some opinionated defaults.

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
if [[ "$host_uses_podman" ]]; then
  function __box_exists() { @host podman container exists fedora-toolbox &>/dev/null || { echo 'Container does not exist!' 1>&2 && return 1; }; }
else
  function __box_exists() { @host docker container inspect fedora-toolbox &>/dev/null || { echo 'Container does not exist!' 1>&2 && return 1; }; }
fi

# __box_create
if [[ "$box_is_container" ]]; then
  function __box_create() { echo "Command 'create' unavailable on toolbox container!" 1>&2 && return 1; }
elif [[ "$host_uses_toolbox" ]]; then
  function __box_create() {
    __box_exists &>/dev/null && echo 'Container already exists!' 1>&2 && return 1
    @host toolbox -y create -i registry.fedoraproject.org/fedora-toolbox:38 fedora-toolbox && __box_upgrade && __box_enter
  }
else
  function __box_create() {
    __box_exists &>/dev/null && echo 'Container already exists!' 1>&2 && return 1
    @host distrobox create -Y --no-entry -i registry.fedoraproject.org/fedora-toolbox:38 -n fedora-toolbox \
      --additional-flags "--hostname '$(@host uname -n)'" && __box_upgrade && __box_enter
  }
fi

# __box_enter
if [[ "$box_is_container" ]]; then
  function __box_enter() { true; }
elif [[ "$host_uses_toolbox" ]]; then
  function __box_enter() { @host toolbox enter -c fedora-toolbox; }
else
  function __box_enter() { __box_exists && @host distrobox enter fedora-toolbox -- /usr/bin/zsh -l; }
fi

# __box_run
if [[ "$box_is_container" ]]; then
  function __box_run() { "$@"; }
elif [[ "$host_uses_toolbox" ]]; then
  function __box_run() { @host toolbox run -c fedora-toolbox "$@"; }
else
  function __box_run() { __box_exists && @host distrobox enter fedora-toolbox -- "$@"; }
fi

# __box_stats
if [[ "$host_uses_podman" ]]; then
  function __box_stats() { @host podman container stats fedora-toolbox; }
else
  function __box_stats() { @host docker container stats fedora-toolbox; }
fi

# __box_logs
if [[ "$host_uses_podman" ]]; then
  function __box_logs() { @host podman container logs fedora-toolbox; }
else
  function __box_logs() { @host docker container logs fedora-toolbox; }
fi

# __box_stop
if [[ "$box_is_container" ]]; then
  function __box_stop() { echo "Command 'stop' unavailable on toolbox container!" 1>&2 && return 1; }
elif [[ "$host_uses_toolbox" ]]; then
  if [[ "$host_uses_podman" ]]; then
    function __box_stop() { @host podman container stop fedora-toolbox; }
  else
    function __box_stop() { @host docker container stop fedora-toolbox; }
  fi
else
  function __box_stop() { @host distrobox stop -Y fedora-toolbox; }
fi

# __box_rm
if [[ "$box_is_container" ]]; then
  function __box_rm() { echo "Command 'rm' unavailable on toolbox container!" 1>&2 && return 1; }
elif [[ "$host_uses_toolbox" ]]; then
  function __box_rm() {
    __box_stop &>/dev/null || true
    @host toolbox rm -f fedora-toolbox
  }
else
  function __box_rm() {
    __box_stop &>/dev/null || true
    @host distrobox rm -f fedora-toolbox
  }
fi

# __box_upgrade
function __box_upgrade() {
  (
    set -eu -o pipefail

    echo
    echo '*** BASIC SETUP ***'
    __box_run sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    __box_run sudo dnf upgrade -y
    __box_run sudo dnf install -y \
      bat direnv exa git git-lfs htop jq neofetch net-tools \
      openssl p7zip p7zip-plugins tldr tmux traceroute unzip \
      vim xclip xsel wl-clipboard zip zsh
    __box_run sudo usermod --shell /usr/bin/zsh "$(id -nu)"
    echo '>>> OK <<<'
    echo

    if [[ -s ~/.box ]]; then
      echo '*** PROVISIONING SCRIPT ***'
      __box_run /usr/bin/zsh -euxf -o pipefail ~/.box
      echo '>>> OK <<<'
      echo
    fi

    echo '*** REDIRECT HOST COMMANDS ***'
    local bin_dir=/usr/local/bin
    local spawn_file
    spawn_file=host-spawn-$(uname -m)
    __box_run sudo wget --no-hsts --no-verbose --show-progress -N -P "$bin_dir" \
      "https://github.com/1player/host-spawn/releases/latest/download/$spawn_file"
    __box_run sudo chmod +x "$bin_dir/$spawn_file"
    __box_run sudo ln -srfT "$bin_dir/$spawn_file" "$bin_dir/host-spawn"
    local host_cmd
    for host_cmd in xdg-open docker docker-compose podman podman-compose flatpak; do
      if @host command -pv "$host_cmd" &>/dev/null; then
        echo "command: $host_cmd"
        __box_run sudo ln -srfT "$bin_dir/$spawn_file" "$bin_dir/$host_cmd"
      fi
    done
    echo '>>> OK <<<'
    echo
  )
}

# cleanup
unset box_is_container host_uses_{toolbox,podman}
