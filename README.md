# Zsh config

Basic [Zsh](https://www.zsh.org/) config, using [Prezto](https://github.com/sorin-ionescu/prezto) framework, [Starship](https://starship.rs/) prompt and some extra [modules](lib/modules).

The prompt theme is based on [Nerd Font Symbols Preset](https://starship.rs/presets/nerd-font.html). The following patched [Nerd Fonts](https://www.nerdfonts.com/) are included:

- [FiraCode Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FiraCode) _(recommended)_
- [DroidSansMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/DroidSansMono)

It is necessary to change the terminal app preferences to use a patched font, otherwise the special icons/glyphs won't be displayed.

## Installation

Choose a folder _(e.g.: `~/.zsh`)_ and clone the repository:

```shell
git clone https://github.com/lucasng-dev/zsh-config.git ~/.zsh
```

Run the installer:

```shell
zsh ~/.zsh/install.zsh
```

The install process will update the `~/.zshenv` file, pointing to this project. Reopen the terminal and adjust the font preferences.

## Update

Run again the installer, or use the following command/alias:

```shell
@zshup
```

## Uninstall

Update the `~/.zshenv` file to remove the line that points to this project.

Update the terminal app preferences to use a normal font.

Delete the following folders:

- `~/.zsh` _(folder where the project was cloned)_
- `~/.local/share/fonts/zsh-config` _(patched fonts on Linux)_
- `~/Library/Fonts/zsh-config` _(patched fonts on macOS)_
