if [[ -s ~/.nvs/nvs.sh ]]; then
  if ! command -v nvs &>/dev/null; then
    source ~/.nvs/nvs.sh &>/dev/null
  fi

  if nvs -v &>/dev/null; then
    function @node() {
      local version=${1:-lts}
      if ! nvs use "$version" &>/dev/null; then
        nvs add "$version" && nvs use "$version"
      fi
    }
    alias @nodeup='nvs upgrade'
    alias @noderm='nvs rm'
    alias @nodels='nvs ls'

    @node
    nvs auto on &>/dev/null
  fi
fi
