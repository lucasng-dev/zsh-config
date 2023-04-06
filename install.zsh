#!/usr/bin/env zsh
set -eu -o pipefail

### cwd ###
script_dir="${0:a:h}"
if [[ -z "$script_dir" || "$script_dir" == "/" || "$script_dir" == "$HOME" ]]; then
  echo "Invalid workdir '$script_dir'!" 1>&2
  return 1
fi
cd "$script_dir"

### environment ###
ZDOTDIR="$script_dir/lib"

### zsh-config ###
echo
echo "### ZSH-CONFIG ###"
echo "Commit: $(git -C "$script_dir" rev-parse --short HEAD)"
echo "Date: $(git -C "$script_dir" --no-pager log -1 --format="%cd")"
echo "OK"
echo

### prezto ###
echo "### PREZTO INSTALL ###"
ZPREZTODIR="$ZDOTDIR/.zprezto"
if [[ ! -d "$ZPREZTODIR/.git" ]]; then
  git clone --recursive https://github.com/sorin-ionescu/prezto.git "$ZPREZTODIR"
else
  git -C "$ZPREZTODIR" pull
  git -C "$ZPREZTODIR" submodule sync --recursive
  git -C "$ZPREZTODIR" submodule update --init --recursive
fi
echo "Commit: $(git -C "$ZPREZTODIR" rev-parse --short HEAD)"
echo "Date: $(git -C "$ZPREZTODIR" --no-pager log -1 --format="%cd")"
echo "OK"
echo

### starship ###
echo "### STARSHIP INSTALL ###"
STARSHIPDIR="$ZDOTDIR/.starship"
mkdir -p "$STARSHIPDIR"
wget --no-hsts -q -O - https://starship.rs/install.sh | sh -s -- --bin-dir "$STARSHIPDIR" -y >/dev/null
"$STARSHIPDIR/starship" --version
echo "OK"
echo

### fonts ###
echo "### FONTS INSTALL ###"
font_files=("FiraCode.zip" "DroidSansMono.zip")
font_download_dir="$ZDOTDIR/.cache/fonts-download"
mkdir -p "$font_download_dir"
for font_file in "${font_files[@]}"; do
  wget --no-hsts -q --show-progress -N -P "$font_download_dir" \
    "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$font_file"
done
if [[ "$(uname)" == 'Darwin' ]]; then
  font_user_dir="$HOME/Library/Fonts/zsh-config" # macOS
else
  font_user_dir="$HOME/.local/share/fonts/zsh-config" # Linux
fi
rm -rf "$font_user_dir"
mkdir -p "$font_user_dir"
for font_file in "${font_files[@]}"; do
  font_subdir_name="$(basename "$font_file" ".zip")"
  unzip -q -o -d "$font_user_dir/$font_subdir_name" "$font_download_dir/$font_file"
done
echo "OK"
echo

### file '~/.zshenv' ###
echo "### ZSH CONFIG ENABLE ###"
touch ~/.zshenv
sed -i '/ZDOTDIR=/d' ~/.zshenv || true
zshenv_previous="$(cat ~/.zshenv)"
cat <<EOT >~/.zshenv
export ZDOTDIR='$ZDOTDIR'; if [[ -s "\$ZDOTDIR/.zshenv" ]]; then source "\$ZDOTDIR/.zshenv"; fi # points to 'zsh-config' project
$zshenv_previous
EOT
echo "OK"
