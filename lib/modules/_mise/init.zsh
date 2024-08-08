if whence -p mise &>/dev/null; then
	eval "$(command mise activate zsh)"
	alias rtx='mise'
	alias asdf='mise'
fi
