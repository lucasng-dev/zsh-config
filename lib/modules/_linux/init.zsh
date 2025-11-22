[[ -n "${ZDOTDIR:-}" ]] || return 1

### HOST FUNCTIONS ###

function @host() {
	(set -eu -o pipefail && __host_cmd "$@")
}

function __host_cmd() {
	case "${1:-}" in
	--logs) shift 1 && __host_logs ;;
	--up | --update | --upgrade) shift 1 && __host_upgrade ;;
	-*) echo "Unknown option: $1" 1>&2 && return 1 ;;
	*) if [[ $# -gt 0 ]]; then __host_exec "$@"; else __host_enter; fi ;;
	esac
}

function __host_exec() {
	if [[ -n "${CONTAINER_ID:-${container:-}}" ]]; then
		if [[ -n "${CONTAINER_ID:-}" ]] && [[ -x /usr/bin/distrobox-host-exec ]]; then
			/usr/bin/distrobox-host-exec "$@"
		elif whence -p host-spawn &>/dev/null; then
			command host-spawn "$@"
		else
			command flatpak-spawn --host --env='TERM=xterm-256color' "$@"
		fi
	else
		"$@"
	fi
}

function __host_enter() {
	if [[ -n "${CONTAINER_ID:-${container:-}}" ]]; then
		__host_exec zsh -l
	fi
}

function __host_logs() {
	__host_exec journalctl -xef
}

### DISTROBOX FUNCTIONS ###

DBX_CONTAINER_MANAGER='docker'
__host_exec zsh -c 'whence -p podman' &>/dev/null && DBX_CONTAINER_MANAGER='podman'
export DBX_CONTAINER_MANAGER

function @box() {
	(set -eu -o pipefail && __box_cmd "$@")
}

function __box_cmd() {
	case "${1:-}" in
	--exists) shift 1 && __box_exists ;;
	--create) shift 1 && __box_create "$@" ;;
	--stats) shift 1 && __box_stats ;;
	--logs) shift 1 && __box_logs ;;
	--stop) shift 1 && __box_stop ;;
	--rm | --delete) shift 1 && __box_rm ;;
	--up | --update | --upgrade) shift 1 && __box_upgrade ;;
	-*) echo "Unknown option: $1" 1>&2 && return 1 ;;
	*) if [[ $# -gt 0 ]]; then __box_exec "$@"; else __box_enter; fi ;;
	esac
}

function __box_exists() {
	__host_exec "$DBX_CONTAINER_MANAGER" container inspect distrobox &>/dev/null ||
		{ echo "Container 'distrobox' does not exist!" 1>&2 && return 1; }
	echo 'OK'
}

function __box_create() {
	echo && echo '### BOX CREATE ###' && echo
	__box_exists &>/dev/null && echo "Container 'distrobox' already exists!" 1>&2 && return 1
	echo '*** CONTAINER ***'
	# https://github.com/89luca89/distrobox/blob/main/docs/compatibility.md#containers-distros
	local image='quay.io/toolbx/arch-toolbox:latest'
	local pkgs=(zsh base-devel fontconfig git git-lfs bat eza micro starship)
	__host_exec distrobox-create --yes --no-entry \
		--name distrobox --hostname "$HOSTNAME" \
		--pull --image "$image" \
		--additional-packages "${pkgs[*]}" \
		--additional-flags "--env LANG='$LANG' --env SHELL='/usr/bin/zsh'" \
		"$@" &&
		__box_upgrade &&
		__box_enter
}

function __box_exec() {
	if [[ "${CONTAINER_ID:-}" != 'distrobox' ]]; then
		__box_exists >/dev/null && __host_exec distrobox-enter distrobox -- "$@"
	else
		"$@"
	fi
}

function __box_enter() {
	if [[ "${CONTAINER_ID:-}" != 'distrobox' ]]; then
		__box_exec zsh -l
	fi
}

function __box_stats() {
	__host_exec watch "$DBX_CONTAINER_MANAGER" container stats --no-stream distrobox
}

function __box_logs() {
	__host_exec "$DBX_CONTAINER_MANAGER" container logs --follow distrobox
}

function __box_stop() {
	echo && echo '### BOX STOP ###' && echo
	if [[ "${CONTAINER_ID:-}" != 'distrobox' ]]; then
		__host_exec distrobox-stop --yes distrobox
		__host_exec "$DBX_CONTAINER_MANAGER" container stop distrobox &>/dev/null || true
	else
		echo "Command 'stop' unavailable inside the distrobox container!" 1>&2 && return 126
	fi
}

function __box_rm() {
	echo && echo '### BOX REMOVE ###' && echo
	if [[ "${CONTAINER_ID:-}" != 'distrobox' ]]; then
		__box_stop &>/dev/null || true
		__host_exec distrobox-rm --yes --force distrobox
		__host_exec "$DBX_CONTAINER_MANAGER" container rm --force distrobox &>/dev/null || true
		__host_exec rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/distrobox"
	else
		echo "Command 'rm' unavailable inside the distrobox container!" 1>&2 && return 126
	fi
}

### UPGRADE FUNCTIONS ###

function __host_upgrade() {
	if [[ -n "${CONTAINER_ID:-}" ]]; then
		__host_exec zsh -i -c 'set -eu -o pipefail && __host_upgrade'
		return $?
	fi
	echo && echo '### HOST UPGRADE ###' && echo
	__linux_upgrade
	if [[ -s "$ZDOTDIR/../custom/.host" ]]; then
		echo '*** PROVISIONING SCRIPT ***'
		command zsh -eu -o pipefail "$ZDOTDIR/../custom/.host"
		echo '>>> OK <<<' && echo
	fi
	__linux_cleanup
}

function __box_upgrade() {
	if [[ "${CONTAINER_ID:-}" != 'distrobox' ]]; then
		__box_exec zsh -i -c 'set -eu -o pipefail && __box_upgrade'
		return $?
	fi
	echo && echo '### BOX UPGRADE ###' && echo
	__box_configure
	__linux_upgrade
	if [[ -s "$ZDOTDIR/../custom/.box" ]]; then
		echo '*** PROVISIONING SCRIPT ***'
		command zsh -eu -o pipefail "$ZDOTDIR/../custom/.box"
		echo '>>> OK <<<' && echo
	fi
	__linux_cleanup
}

function __linux_upgrade() {
	if [[ -z "${CONTAINER_ID:-${container:-}}" ]] && whence -p rpm-ostree &>/dev/null; then
		echo '*** UPGRADE: RPM-OSTREE ***' && sudo rpm-ostree upgrade && echo '>>> OK <<<' && echo
	elif whence -p dnf &>/dev/null; then
		echo '*** UPGRADE: DNF ***' && sudo dnf upgrade --refresh -y && echo '>>> OK <<<' && echo
	elif whence -p yum &>/dev/null; then
		echo '*** UPGRADE: YUM ***' && sudo yum upgrade --refresh -y && echo '>>> OK <<<' && echo
	elif whence -p zypper &>/dev/null; then
		echo '*** UPGRADE: ZYPPER ***' && sudo zypper refresh && sudo zypper update -y && echo '>>> OK <<<' && echo
	elif whence -p apt &>/dev/null; then
		echo '*** UPGRADE: APT ***' && sudo apt update && sudo apt upgrade -y && echo '>>> OK <<<' && echo
	elif whence -p yay &>/dev/null; then
		echo '*** UPGRADE: YAY ***' && command yay -Syu --noconfirm --combinedupgrade && echo '>>> OK <<<' && echo
	elif whence -p paru &>/dev/null; then
		echo '*** UPGRADE: PARU ***' && command paru -Syu --noconfirm --combinedupgrade && echo '>>> OK <<<' && echo
	elif whence -p pacman &>/dev/null; then
		echo '*** UPGRADE: PACMAN ***' && sudo pacman -Syu --noconfirm && echo '>>> OK <<<' && echo
	elif whence -p apk &>/dev/null; then
		echo '*** UPGRADE: APK ***' && sudo apk update && sudo apk upgrade && echo '>>> OK <<<' && echo
	fi
	if whence -p brew &>/dev/null; then
		echo '*** UPGRADE: HOMEBREW ***' && command brew update -q && command brew upgrade -q && echo '>>> OK <<<' && echo
	fi
	if [[ -z "${CONTAINER_ID:-${container:-}}" ]]; then
		if whence -p flatpak &>/dev/null; then
			echo '*** UPGRADE: FLATPAK ***' && sudo flatpak update -y && command flatpak --user update -y && echo '>>> OK <<<' && echo
		fi
		if whence -p snap &>/dev/null; then
			echo '*** UPGRADE: SNAP ***' && sudo snap refresh && echo '>>> OK <<<' && echo
		fi
	fi
}

function __linux_cleanup() {
	if [[ -z "${CONTAINER_ID:-${container:-}}" ]] && whence -p rpm-ostree &>/dev/null; then
		echo '*** CLEANUP: RPM-OSTREE ***' && sudo rpm-ostree cleanup --base && echo '>>> OK <<<' && echo
	elif whence -p dnf &>/dev/null; then
		echo '*** CLEANUP: DNF ***' && sudo dnf autoremove -y && echo '>>> OK <<<' && echo
	elif whence -p yum &>/dev/null; then
		echo '*** CLEANUP: YUM ***' && sudo yum autoremove -y && echo '>>> OK <<<' && echo
	elif whence -p zypper &>/dev/null; then
		echo '*** CLEANUP: ZYPPER ***' && sudo zypper clean && echo '>>> OK <<<' && echo
	elif whence -p apt &>/dev/null; then
		echo '*** CLEANUP: APT ***' && sudo apt autoremove -y && echo '>>> OK <<<' && echo
	elif whence -p yay &>/dev/null; then
		echo '*** CLEANUP: YAY ***' && { command yay -Qtdq | command yay -Rns --noconfirm - 2>/dev/null || true; } && command yay -Sc --noconfirm >/dev/null && echo '>>> OK <<<' && echo
	elif whence -p paru &>/dev/null; then
		echo '*** CLEANUP: PARU ***' && { command paru -Qtdq | command paru -Rns --noconfirm - 2>/dev/null || true; } && command paru -Sc --noconfirm >/dev/null && echo '>>> OK <<<' && echo
	elif whence -p pacman &>/dev/null; then
		echo '*** CLEANUP: PACMAN ***' && { sudo pacman -Qtdq | sudo pacman -Rns --noconfirm - 2>/dev/null || true; } && sudo pacman -Sc --noconfirm >/dev/null && echo '>>> OK <<<' && echo
	elif whence -p apk &>/dev/null; then
		echo '*** CLEANUP: APK ***' && sudo apk cache clean && echo '>>> OK <<<' && echo
	fi
	if whence -p brew &>/dev/null; then
		echo '*** CLEANUP: HOMEBREW ***' && command brew autoremove -q && echo '>>> OK <<<' && echo
	fi
	if [[ -z "${CONTAINER_ID:-${container:-}}" ]]; then
		if whence -p flatpak &>/dev/null; then
			echo '*** CLEANUP: FLATPAK ***' && sudo flatpak uninstall --unused -y && command flatpak --user uninstall --unused -y && echo '>>> OK <<<' && echo
		fi
		if whence -p snap &>/dev/null; then
			echo '*** CLEANUP: SNAP ***' && (
				local name _version rev _tracking _publisher notes
				while read -r name _version rev _tracking _publisher notes; do
					if [[ "$notes" == *disabled* ]]; then
						sudo snap remove "$name" --revision="$rev"
					fi
				done < <(sudo env LANG=C snap list --all)
			) && echo '>>> OK <<<' && echo
		fi
	fi
}

function __box_configure() {
	echo '*** USER ***'
	sudo usermod --shell "$(whence -p zsh)" "$(id -nu)" >/dev/null
	sudo mkdir -p /var/lib/systemd/linger
	sudo touch "/var/lib/systemd/linger/$USER"
	echo '>>> OK <<<' && echo

	echo '*** PACMAN ***'
	if [[ -f /var/lib/pacman/db.lck ]] && ! command pgrep pacman &>/dev/null; then
		sudo rm -f /var/lib/pacman/db.lck
	fi
	sudo sed -Ei \
		-e '\/^(Color|ILoveCandy|NoExtract|NoProgressBar)\b/d' \
		-e '0,/^(\[options\])/s//\1\nColor\nILoveCandy/' \
		/etc/pacman.conf
	sudo sed -Ei \
		-e 's/^(OPTIONS=.*\s)(debug)(\b.*)$/\1!\2\3/g' \
		/etc/makepkg.conf
	if [[ ! -d /etc/pacman.d/gnupg/ ]]; then
		# https://gitlab.archlinux.org/archlinux/archlinux-docker
		sudo pacman-key --init
		sudo pacman-key --populate
	fi
	echo '>>> OK <<<' && echo

	if [[ -s /etc/locale.gen ]]; then
		local locales=($(LC_ALL='' command locale 2>/dev/null | command grep -Eo '\b\w+\.UTF-8\b' | command sort -u))
		local locales_hash && locales_hash=$(command sha512sum /etc/locale.gen)
		local locale
		for locale in "${locales[@]}"; do
			sudo sed -Ei "s|^#\s*(${locale/./\\.})|\1|g" /etc/locale.gen
		done
		if [[ "$locales_hash" != "$(command sha512sum /etc/locale.gen)" ]]; then
			echo '*** LOCALES ***'
			if whence -p pacman &>/dev/null; then
				# https://gitlab.archlinux.org/archlinux/archlinux-docker/-/issues/72
				sudo pacman -S --noconfirm glibc >/dev/null
			fi
			sudo locale-gen
			echo '>>> OK <<<' && echo
		fi
	fi

	# https://github.com/89luca89/distrobox/issues/358
	echo '*** FONT CACHE ***'
	sudo sed -Ei 's|(<cachedir\s[^>]*prefix="xdg"[^>]*>)[^<]*(</cachedir>)|\1distrobox/fontconfig\2|g' /etc/fonts/fonts.conf
	fc-cache -f
	echo '>>> OK <<<' && echo

	echo '*** REDIRECT HOST COMMANDS ***'
	/usr/bin/distrobox-host-exec --yes true # download host-spawn
	local host_cmd
	for host_cmd in virsh docker{,-compose} podman{,-compose} minikube flatpak snap xdg-open gtk-launch gnome-terminal kgx ptyxis tilix konsole; do
		if __host_exec zsh -c "whence -p '$host_cmd'" &>/dev/null; then
			echo "command: $host_cmd"
			sudo ln -sfT /usr/bin/distrobox-host-exec "/usr/local/bin/$host_cmd"
		fi
	done
	echo '>>> OK <<<' && echo

	echo '*** YAY ***'
	local builddir="${XDG_CACHE_HOME:-$HOME/.cache}/yay" && command mkdir -p "$builddir"
	if ! whence -p yay &>/dev/null; then
		command rm -rf "$builddir/yay-bin"
		command git clone https://aur.archlinux.org/yay-bin.git "$builddir/yay-bin"
		local mflags=(--noconfirm --needed --clean --cleanbuild)
		(cd "$builddir/yay-bin" && PATH='/usr/bin:/usr/sbin:/bin:/sbin' command makepkg -si "${mflags[@]}")
		command rm -f "${XDG_CONFIG_HOME:-$HOME/.config}/yay/config.json"
		command yay -Y --save --mflags "${mflags[*]}"
	fi
	command yay -Y --save --needed --devel --builddir "$builddir" --batchinstall --combinedupgrade --cleanafter --removemake \
		--answerclean A --diffmenu --answerdiff A --editmenu --answeredit N
	echo '>>> OK <<<' && echo
}
