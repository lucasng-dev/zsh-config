### HOST FUNCTIONS ###

function @host() {
	(set -eu -o pipefail && __host_cmd "$@")
}

function __host_cmd() {
	local __command
	if [[ $# -ge 1 ]]; then __command="$1" && shift 1; fi
	case "$__command" in
	exec | run) __host_exec "$@" ;;
	enter | shell) __host_enter ;;
	logs) __host_logs ;;
	upgrade | update) __host_upgrade ;;
	*) if [[ $# -gt 0 ]]; then __host_exec "$@"; else __host_enter; fi ;;
	esac
}

function __host_exec() {
	[[ $# -eq 0 ]] && echo 'Command is not specified!' 1>&2 && return 1
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
	if [[ -n "${CONTAINER_ID:-${container:-}}" ]]; then __host_exec zsh -l; fi
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
	local __command distro_name
	if [[ $# -ge 1 ]]; then __command="$1" && shift 1; fi
	if [[ $# -ge 1 ]]; then distro_name="$1" && shift 1; fi
	if [[ "$__command" == 'list' ]]; then
		__box_list
	elif [[ "$distro_name" == '--all' ]]; then
		if [[ "$__command" =~ ^(stop|rm|delete|upgrade|update)$ ]]; then
			for distro_name in $(__box_list); do (__box_cmd "$__command" "$distro_name" "$@"); done
		else
			echo "Command '$__command' unavailable when '--all' option is specified!" 1>&2 && return 126
		fi
	else
		if [[ -z "$distro_name" ]]; then
			if [[ -n "${CONTAINER_ID:-}" ]]; then
				distro_name="$(echo -n "$CONTAINER_ID" | command sed 's/^distrobox-//g')" # current container
			else
				# shellcheck disable=SC2207
				local __box_list=($(__box_list))
				if [[ "${#__box_list[@]}" -eq 1 ]]; then
					distro_name="${__box_list[1]}" # single container
				else
					echo 'Linux distro name is not specified!' 1>&2 && return 1
				fi
			fi
		fi
		case "$__command" in
		exists) __box_exists ;;
		create) __box_create ;;
		exec | run) __box_exec "$@" ;;
		enter | shell) __box_enter ;;
		stats) __box_stats ;;
		logs) __box_logs ;;
		stop) __box_stop ;;
		rm | delete) __box_rm ;;
		upgrade | update) __box_upgrade ;;
		*) if [[ $# -gt 0 ]]; then __box_exec "$@"; else __box_enter; fi ;;
		esac
	fi
}

function __box_list() {
	{ __host_exec "$DBX_CONTAINER_MANAGER" container ls --all --format '{{.Names}}' | command grep '^distrobox-' | command sed 's/^distrobox-//g' | command sort -u; } || true
}

function __box_exists() {
	__host_exec "$DBX_CONTAINER_MANAGER" container inspect "distrobox-${distro_name}" &>/dev/null ||
		{ echo "Container 'distrobox-${distro_name}' does not exist!" 1>&2 && return 1; }
	echo 'OK'
}

function __box_create() {
	echo && echo "### BOX CREATE: ${distro_name:u} ###" && echo
	__box_exists &>/dev/null && echo "Container 'distrobox-${distro_name}' already exists!" 1>&2 && return 1
	echo '*** CONTAINER ***'
	local image='' pkgs=(zsh fontconfig git git-lfs)
	# https://github.com/89luca89/distrobox/blob/main/docs/compatibility.md#containers-distros
	case "$distro_name" in
	alma) image='quay.io/toolbx-images/almalinux-toolbox:latest' && pkgs+=(bat eza) ;;
	alpine) image='quay.io/toolbx-images/alpine-toolbox:latest' && pkgs+=(bat eza micro starship gcompat) ;;
	amazon) image='quay.io/toolbx-images/amazonlinux-toolbox:latest' && pkgs+=() ;;
	arch) image='quay.io/toolbx/arch-toolbox:latest' && pkgs+=(bat eza micro starship base-devel) ;;
	centos) image='quay.io/toolbx-images/centos-toolbox:latest' && pkgs+=(bat eza) ;;
	debian) image='quay.io/toolbx-images/debian-toolbox:testing' && pkgs+=(bat eza micro) ;;
	fedora) image='registry.fedoraproject.org/fedora-toolbox:latest' && pkgs+=(bat eza micro) ;;
	opensuse) image='registry.opensuse.org/opensuse/distrobox:latest' && pkgs+=(bat eza micro-editor starship) ;;
	rhel) image='quay.io/toolbx-images/rhel-toolbox:latest' && pkgs+=(bat eza) ;;
	rocky) image='quay.io/toolbx-images/rockylinux-toolbox:latest' && pkgs+=(bat eza) ;;
	ubuntu) image='quay.io/toolbx/ubuntu-toolbox:latest' && pkgs+=(bat eza micro) ;;
	*) echo "Unsupported distro '$distro_name'" 1>&2 && return 1 ;;
	esac
	__host_exec distrobox-create --yes --no-entry \
		--name "distrobox-${distro_name}" --hostname "$HOSTNAME" \
		--pull --image "$image" \
		--additional-packages "${pkgs[*]}" &&
		{ __host_exec "$DBX_CONTAINER_MANAGER" image prune --force &>/dev/null || true; } &&
		__box_upgrade &&
		__box_enter
}

function __box_exec() {
	[[ $# -eq 0 ]] && echo 'Command is not specified!' 1>&2 && return 1
	if [[ "${CONTAINER_ID:-}" != "distrobox-${distro_name}" ]]; then
		__box_exists >/dev/null && __host_exec distrobox-enter "distrobox-${distro_name}" -- "$@"
	else
		"$@"
	fi
}

function __box_enter() {
	if [[ "${CONTAINER_ID:-}" != "distrobox-${distro_name}" ]]; then __box_exec zsh -l; fi
}

function __box_stats() {
	__host_exec watch "$DBX_CONTAINER_MANAGER" container stats --no-stream "distrobox-${distro_name}"
}

function __box_logs() {
	__host_exec "$DBX_CONTAINER_MANAGER" container logs --follow "distrobox-${distro_name}"
}

function __box_stop() {
	echo && echo "### BOX STOP: ${distro_name:u} ###" && echo
	if [[ "${CONTAINER_ID:-}" != "distrobox-${distro_name}" ]]; then
		__host_exec distrobox-stop --yes "distrobox-${distro_name}"
		__host_exec "$DBX_CONTAINER_MANAGER" container stop "distrobox-${distro_name}" &>/dev/null || true
	else
		echo "Command 'stop' unavailable inside the distrobox container!" 1>&2 && return 126
	fi
}

function __box_rm() {
	echo && echo "### BOX REMOVE: ${distro_name:u} ###" && echo
	if [[ "${CONTAINER_ID:-}" != "distrobox-${distro_name}" ]]; then
		__box_stop &>/dev/null || true
		__host_exec distrobox-rm --yes --force "distrobox-${distro_name}"
		__host_exec "$DBX_CONTAINER_MANAGER" container rm --force "distrobox-${distro_name}" &>/dev/null || true
		__host_exec rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/distrobox/distrobox-${distro_name}"
	else
		echo "Command 'rm' unavailable inside the distrobox container!" 1>&2 && return 126
	fi
}

### UPGRADE FUNCTIONS ###

function __host_upgrade() {
	if [[ -n "${CONTAINER_ID:-}" ]]; then
		__host_exec zsh -i -c __host_upgrade
		return $?
	fi
	echo && echo '### HOST UPGRADE ###' && echo
	__linux_upgrade
	# shellcheck disable=SC2154
	if [[ -s "$ZDOTDIR/../custom/.host" ]]; then
		echo '*** PROVISIONING SCRIPT ***'
		command zsh -eu -o pipefail "$ZDOTDIR/../custom/.host"
		echo '>>> OK <<<' && echo
	fi
	__linux_cleanup
}

function __box_upgrade() {
	if [[ "${CONTAINER_ID:-}" != "distrobox-${distro_name}" ]]; then
		__box_exec env distro_name="${distro_name}" zsh -i -c __box_upgrade
		return $?
	fi
	echo && echo "### BOX UPGRADE: ${distro_name:u} ###" && echo
	__box_configure
	__linux_upgrade
	# shellcheck disable=SC2154
	if [[ -s "$ZDOTDIR/../custom/.box" ]]; then
		echo '*** PROVISIONING SCRIPT ***'
		command zsh -eu -o pipefail "$ZDOTDIR/../custom/.box" # all distros
		echo '>>> OK <<<' && echo
	fi
	if [[ -s "$ZDOTDIR/../custom/.box-${distro_name}" ]]; then
		echo "*** PROVISIONING SCRIPT: ${distro_name:u} ***"
		command zsh -eu -o pipefail "$ZDOTDIR/../custom/.box-${distro_name}" # distro specific
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
				local name version rev tracking publisher notes
				# shellcheck disable=SC2034
				while read -r name version rev tracking publisher notes; do
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

	if whence -p pacman &>/dev/null; then
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
	fi

	if whence -p locale-gen &>/dev/null && [[ -s /etc/locale.gen ]]; then
		# shellcheck disable=SC2207
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
	sudo sed -Ei "s|(<cachedir\s[^>]*prefix=\"xdg\"[^>]*>)[^<]*(</cachedir>)|\1distrobox/distrobox-${distro_name}/fontconfig\2|g" /etc/fonts/fonts.conf
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

	if whence -p pacman &>/dev/null; then
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
			--answerclean A --diffmenu --answerdiff I --editmenu --answeredit A
		echo '>>> OK <<<' && echo
	fi
}
