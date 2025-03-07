[[ -n "${ZDOTDIR:-}" ]] || return 1

if whence -p rpm-ostree &>/dev/null; then
	@rpm-ostree() { if [[ $# -eq 0 ]]; then command rpm-ostree status --json 2>/dev/null | command jq -r '.deployments[0].packages[]' | command sort -u | command less; else command rpm-ostree search "$@" | command less; fi; }
fi

if whence -p dnf &>/dev/null; then
	@dnf() { if [[ $# -eq 0 ]]; then command dnf repoquery --userinstalled | command sort -u | command less; else command dnf search "$@" | command less; fi; }
fi

if whence -p yum &>/dev/null; then
	@yum() { if [[ $# -eq 0 ]]; then command yum repoquery --userinstalled | command sort -u | command less; else command yum search "$@" | command less; fi; }
fi

if whence -p rpm &>/dev/null; then
	@rpm() { command rpm -qa | command sort -u | command less; }
fi

if whence -p apt &>/dev/null; then
	@apt() { if [[ $# -eq 0 ]]; then command apt-mark showmanual | command sort -u | command less; else command apt search "$@" | command less; fi; }
fi

if whence -p pacman &>/dev/null; then
	function @pacman() {
		if [[ $# -eq 0 ]]; then
			command comm -23 <(command pacman -Qqett | command sort -u) <(command pacman -Qqg gnome | command sort -u) | command less
		else
			if whence -p yay &>/dev/null; then
				command yay -Ss "$@" | command less
			elif whence -p paru &>/dev/null; then
				command paru -Ss "$@" | command less
			else
				command pacman -Ss "$@" | command less
			fi
		fi
	}
	alias @yay='@pacman'
	alias @paru='@pacman'
fi

if whence -p flatpak &>/dev/null; then
	function @flatpak() {
		if [[ $# -eq 0 ]]; then
			{
				echo '*** system ***' && command flatpak list --app --columns=application | command sort -u
				echo
				echo '*** user ***' && command flatpak list --user --app --columns=application | command sort -u
			} | command less
		else
			command flatpak search --columns=application "$@" | command less
		fi
	}
fi

if whence -p brew &>/dev/null; then
	function @brew() { if [[ $# -eq 0 ]]; then command brew list --installed-on-request | command sort -u | command less; else command brew search "$@" | command less; fi; }
fi
