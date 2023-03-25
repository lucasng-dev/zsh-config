alias @zshup='zsh "$ZDOTDIR/../install.zsh"'

__upgrade_cmds+=()
if command -v dnf &>/dev/null; then
  __upgrade_cmds+=('echo && echo "### DNF ###" && sudo dnf upgrade && sudo dnf autoremove -y;')
elif command -v apt-get &>/dev/null; then
  __upgrade_cmds+=('echo && echo "### APT ###" && sudo apt-get update && sudo apt-get upgrade && sudo apt-get autoremove -y;')
fi
if command -v flatpak &>/dev/null; then
  __upgrade_cmds+=('echo && echo "### FLATPAK ###" && sudo flatpak update && sudo flatpak uninstall --unused -y;')
fi
__upgrade_cmds="${__upgrade_cmds[@]}"
alias @upgrade="$__upgrade_cmds"
unset __upgrade_cmds
