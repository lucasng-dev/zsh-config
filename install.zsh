#!/usr/bin/env zsh
# shellcheck shell=bash
set -eu -o pipefail

echo
echo '### ZSH-CONFIG ###'
echo

script_dir=${0:A:h}
if [[ -z "$script_dir" ]] || [[ "$script_dir" == '/' ]] || [[ "$script_dir" == ~ ]]; then
  echo "Invalid workdir '$script_dir'!" 1>&2
  return 1
fi
cd "$script_dir"

ZDOTDIR=$script_dir/lib

echo '*** GIT INFO ***'
echo "Commit: $(git -C "$script_dir" rev-parse --short HEAD)"
echo "Date: $(git -C "$script_dir" --no-pager log -1 --format='%cd')"
echo '>>> OK <<<'
echo

echo '*** PREZTO INSTALL ***'
ZPREZTODIR=$ZDOTDIR/.zprezto
if [[ ! -d "$ZPREZTODIR/.git" ]]; then
  git clone --recursive https://github.com/sorin-ionescu/prezto.git "$ZPREZTODIR"
else
  git -C "$ZPREZTODIR" pull
  git -C "$ZPREZTODIR" submodule sync --recursive
  git -C "$ZPREZTODIR" submodule update --init --recursive
fi
echo "Commit: $(git -C "$ZPREZTODIR" rev-parse --short HEAD)"
echo "Date: $(git -C "$ZPREZTODIR" --no-pager log -1 --format='%cd')"
echo '>>> OK <<<'
echo

echo '*** STARSHIP INSTALL ***'
STARSHIPDIR=$ZDOTDIR/.starship
mkdir -p "$STARSHIPDIR"
wget --no-hsts --no-verbose -O - https://starship.rs/install.sh | sh -s -- --bin-dir "$STARSHIPDIR" -y >/dev/null
"$STARSHIPDIR/starship" --version
echo '>>> OK <<<'
echo

echo '*** FONT INSTALL ***'
font_file=FiraCode.zip
font_download_dir=$ZDOTDIR/.cache/fonts-download
mkdir -p "$font_download_dir"
wget --no-hsts --no-verbose --show-progress -N -P "$font_download_dir" \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_file"
if [[ "$(uname)" == 'Darwin' ]]; then
  font_user_dir=~/Library/Fonts/NerdFonts # macOS
else
  font_user_dir=~/.local/share/fonts/NerdFonts # Linux
fi
mkdir -p "$font_user_dir"
font_subdir=$font_user_dir/$(basename "$font_file" '.zip')
rm -rf "$font_subdir"
unzip -q -o -d "$font_subdir" "$font_download_dir/$font_file"
echo "$font_subdir"
echo '>>> OK <<<'
echo

echo '*** ZSH CONFIG ENABLE ***'
touch ~/.zshenv
sed -i '/ZDOTDIR=/d' ~/.zshenv || true
zshenv_previous=$(cat ~/.zshenv)
cat <<EOT >~/.zshenv
export ZDOTDIR='$ZDOTDIR' && if [[ -s "\$ZDOTDIR/.zshenv" ]]; then source "\$ZDOTDIR/.zshenv"; fi # points to 'zsh-config' project
$zshenv_previous
EOT
echo '>>> OK <<<'
echo
