if [[ -s "$HOME/.nvs/nvs.sh" ]]; then
  if ! command -v nvs &>/dev/null; then
    source "$HOME/.nvs/nvs.sh" &>/dev/null
  fi

  if nvs -v &>/dev/null; then
    function __nvs_use() {
      local version="${1:-lts}"
      if ! nvs use "$version" &>/dev/null; then
        nvs add "$version" && nvs use "$version"
      fi
    }

    __nvs_use
    nvs auto on &>/dev/null

    alias @node='__nvs_use'
    alias @nodeup='nvs upgrade'
    alias @noderm='nvs rm'
    alias @nodels='nvs ls'
  fi
fi
