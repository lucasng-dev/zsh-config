[[ -n "${ZDOTDIR:-}" ]] || return 1

# upgrade zsh-config
function @zshup() {
	git -C "$ZDOTDIR/.." pull >/dev/null && zsh "$ZDOTDIR/../install.sh"
}

# upgrade system
function @upgrade() {
	(
		set -eu -o pipefail
		@zshup
		@host --upgrade
		if @box --exists &>/dev/null; then
			@box --upgrade
		fi
	)
}
