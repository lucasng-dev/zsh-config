[[ -n "${ZDOTDIR:-}" ]] || return 1

if whence -p fd &>/dev/null; then
	function fdname() {
		command fd --color always --follow --hidden --exclude .git "$@" | command less
	}
fi

if whence -p rg &>/dev/null; then
	function fdcontent() {
		command rg --smart-case --pretty --follow --hidden --glob '!.git' "$@" | command less
	}
fi

if whence -p fzf &>/dev/null; then
	function fdselect() {
		local cmd=(fzf --multi --layout=reverse --ansi)
		if whence -p bat &>/dev/null; then
			cmd+=('--preview=bat --color=always -p {}')
		else
			cmd+=('--preview=cat {}')
		fi
		while [[ $# -gt 0 ]]; do
			case "$1" in
			-*) cmd+=("$1") ;;
			*) cmd+=('--bind' "enter:become($1 {+})") ;;
			esac
			shift 1
		done
		if whence -p fd &>/dev/null; then
			FZF_DEFAULT_COMMAND='fd --follow --hidden --exclude .git' command "${cmd[@]}"
		else
			command "${cmd[@]}"
		fi
	}
fi
