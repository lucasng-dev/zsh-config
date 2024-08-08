# Zsh config

Basic [Zsh](https://www.zsh.org/) config, using [Prezto](https://github.com/sorin-ionescu/prezto) framework, [Starship](https://starship.rs/) prompt and some extra [modules](lib/modules).

The prompt theme is based on [Nerd Font Symbols Preset](https://starship.rs/presets/nerd-font.html). The [FiraCode Nerd Font](https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/FiraCode) is included, update the terminal app preferences to use it, otherwise the special icons/glyphs won't be displayed.

## Installation

Choose a folder _(e.g.: `~/.zsh`)_ and clone the repository:

```shell
git clone https://github.com/lucasng-dev/zsh-config.git ~/.zsh
```

Run the installer:

```shell
zsh ~/.zsh/install.sh
```

The installation process will update the `~/.zshenv` file, pointing to this project. Reopen the terminal and adjust the font preferences.

## Update

Use the following command/alias:

```shell
@zshup
```

An alternative is to run manually a `git pull` on this project folder and re-run the `install.sh` script.

## Uninstall

Update the `~/.zshenv` file to remove the line that points to this project.

Update the terminal app preferences to use a normal font.

Delete the following folders:

- `~/.zsh` _(folder where the project was cloned)_
- `~/.local/share/fonts/NerdFonts/FiraCode` _(patched font on Linux)_
- `~/Library/Fonts/NerdFonts/FiraCode` _(patched font on macOS)_

## Custom shell scripts

These local user home files, if existent, will be loaded in the following order:

| User script file     | Usage                                                   | Loaded on              |
| -------------------- | ------------------------------------------------------- | ---------------------- |
| `~/.zshenv`          | Setup only, points to this project, keep it as is       | All executions         |
| `~/.profile`         | Use **`~/.zprofile`** instead                           | All executions         |
| **`~/.zprofile`** ✅ | **Recommended**, e.g: environment variables and options | All executions         |
| **`~/.zshrc`** ✅    | **Recommended**, e.g: aliases, functions                | Interactive shell only |
| `~/.zprestorc`       | If necessary, allows changes on Prezto config           | Interactive shell only |
| `~/.zlogin`          | Unusual, interactive shell, after open                  | Interactive shell only |
| `~/.zlogout`         | Unusual, interactive shell, before exit                 | Interactive shell only |

## Extra shell scripts used by modules

| User script file | Usage                                               | Loaded on       |
| ---------------- | --------------------------------------------------- | --------------- |
| `~/.host`        | Script to provision host                            | `@host upgrade` |
| `~/.box`         | Script to provision distrobox                       | `@box upgrade`  |
| `~/.box-DISTRO`  | Script to provision distrobox for a specific distro | `@box upgrade`  |
