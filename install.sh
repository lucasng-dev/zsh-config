#!/usr/bin/env zsh
set -eu -o pipefail

echo && echo '### ZSH CONFIG ###' && echo

script_dir="${0:A:h}" && cd "$script_dir"
if [[ -z "$script_dir" ]] || [[ "$script_dir" == '/' ]] || [[ "$script_dir" == "$HOME" ]]; then
	echo "Invalid workdir '$script_dir'!" 1>&2 && return 1
fi
ZDOTDIR="$script_dir/lib"

echo '*** GIT INFO ***'
echo "Commit: $(git -C "$script_dir" rev-parse --short HEAD)"
echo "Date: $(git -C "$script_dir" --no-pager log -1 --format='%cd')"
echo '>>> OK <<<' && echo

echo '*** PREZTO INSTALL ***'
prezto_dir="$ZDOTDIR/.zprezto"
if [[ ! -d "$prezto_dir/.git" ]]; then
	git clone --recursive https://github.com/sorin-ionescu/prezto.git "$prezto_dir"
else
	git -C "$prezto_dir" pull
	git -C "$prezto_dir" submodule sync --recursive
	git -C "$prezto_dir" submodule update --init --recursive
fi
echo "Commit: $(git -C "$prezto_dir" rev-parse --short HEAD)"
echo "Date: $(git -C "$prezto_dir" --no-pager log -1 --format='%cd')"
echo '>>> OK <<<' && echo

if ! whence -p starship &>/dev/null; then
	echo '*** STARSHIP INSTALL ***'
	starship_dir="$ZDOTDIR/.starship"
	mkdir -p "$starship_dir"
	curl -fsSL https://raw.githubusercontent.com/starship/starship/HEAD/install/install.sh | sh -s -- --bin-dir "$starship_dir" -y >/dev/null
	"$starship_dir/starship" --version
	echo '>>> OK <<<' && echo
fi

if ! fc-list 2>/dev/null | grep -v "$HOME" | grep -i 'fira.*code.*nerd' &>/dev/null; then
	echo '*** FONT INSTALL ***'
	font_download_dir="$(mktemp -d)"
	font_zip_file="$font_download_dir/fira-code.zip"
	curl -fsSL -o "$font_zip_file" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
	if [[ "${OSTYPE:-}" == darwin* ]]; then
		font_install_dir="$HOME/Library/Fonts/nerd-fonts/fira-code" # macOS
	else
		font_install_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/nerd-fonts/fira-code" # Linux
	fi
	rm -rf "$font_install_dir" && mkdir -p "$font_install_dir"
	unzip -q -o -d "$font_install_dir" "$font_zip_file"
	rm -rf "$font_download_dir"
	echo "$font_install_dir"
	echo '>>> OK <<<' && echo
fi

echo '*** ZSH CONFIG ENABLE ***'
zshenv_src="$(sed -E '/ZDOTDIR=/d' ~/.zshenv 2>/dev/null || true)"
cat >~/.zshenv <<-EOF
	export ZDOTDIR="${ZDOTDIR/$HOME/\$HOME}" && source "\$ZDOTDIR/.zshenv"
	$zshenv_src
EOF
echo '>>> OK <<<' && echo

if [[ "$SHELL" != 'zsh' ]] && [[ "$SHELL" != *'/zsh' ]] &&
	whence -p sudo &>/dev/null && { whence -p usermod &>/dev/null || whence -p chsh &>/dev/null; }; then
	echo '*** DEFAULT SHELL ***'
	zsh_ok='false'
	for zsh_bin in /usr/bin/zsh /bin/zsh; do
		if [[ -x "$zsh_bin" ]] && grep "^$zsh_bin$" /etc/shells &>/dev/null; then
			if whence -p usermod &>/dev/null; then
				sudo usermod --shell "$zsh_bin" "$USER"
			else
				sudo chsh --shell "$zsh_bin" "$USER"
			fi
			zsh_ok='true'
			break
		fi
	done
	if [[ "$zsh_ok" == 'false' ]]; then
		echo "unable to set zsh as the default shell!" 1>&2 && return 1
	fi
	echo '>>> OK <<<' && echo
fi
