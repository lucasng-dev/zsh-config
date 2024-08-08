# upgrade zsh-config
function @zshup() {
	# shellcheck disable=SC2154
	git -C "$ZDOTDIR/.." pull >/dev/null && zsh "$ZDOTDIR/../install.sh"
}

# upgrade system
function @upgrade() {
	(
		set -eu -o pipefail
		@zshup
		@host upgrade
		@box upgrade --all
	)
}
