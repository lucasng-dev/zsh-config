if [[ -s "$HOME/.cargo/env" ]]; then
  if ! command -v rustup &>/dev/null; then
    source "$HOME/.cargo/env"
  fi

  alias @rustup='rustup update'
fi
