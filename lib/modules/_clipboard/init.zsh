[[ -n "${ZDOTDIR:-}" ]] || return 1

# https://github.com/zyedidia/clipboard
if [[ -n "${WAYLAND_DISPLAY:-}" ]] && whence -p wl-copy &>/dev/null && whence -p wl-paste &>/dev/null; then
	alias @copy='wl-copy &>/dev/null'
	alias @paste='wl-paste --no-newline'
elif [[ -n "${DISPLAY:-}" ]] && whence -p xclip &>/dev/null; then
	alias @copy='xclip -in -selection clipboard &>/dev/null'
	alias @paste='xclip -out -selection clipboard'
elif [[ -n "${DISPLAY:-}" ]] && whence -p xsel &>/dev/null; then
	alias @copy='xsel --input --clipboard'
	alias @paste='xsel --output --clipboard'
elif [[ "${OSTYPE:-}" == darwin* ]] && whence -p pbcopy &>/dev/null && whence -p pbpaste &>/dev/null; then
	alias @copy='pbcopy'
	alias @paste='pbpaste'
fi
