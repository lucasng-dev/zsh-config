[[ -n "${ZDOTDIR:-}" ]] || return 1

if whence -p micro &>/dev/null; then
	function micro() {
		local src_dir="$ZDOTDIR/config/micro"
		local dst_dir="${XDG_CONFIG_HOME:-$HOME/.config}/micro"
		local config_file
		for config_file in {settings,bindings}.json; do
			if ! command cmp -s "$src_dir/$config_file" "$dst_dir/$config_file" &>/dev/null; then
				command mkdir -p "$dst_dir"
				command cp -f "$src_dir/$config_file" "$dst_dir/$config_file"
			fi
		done
		command micro "$@"
	}
fi
