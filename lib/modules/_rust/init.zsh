if [[ -s ~/.cargo/env ]]; then
  if ! command -v rustup &>/dev/null; then
    source ~/.cargo/env
  fi

  alias @rustup='rustup update'
fi
