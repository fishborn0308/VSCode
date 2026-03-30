tmuxsync() {
  [[ -z "$TMUX" ]] && return 0

  local session v raw val
  session=$(tmux display-message -p '#S' 2>/dev/null) || return 0

  local vars=(
    TARGET_IP
    TARGET_NAME
    TARGET_DIR
    OUT
    LOG
    ASSETS
    workdir
    INIT_SCAN_SOURCE
    INIT_PORTS
  )

  for v in "${vars[@]}"; do
    raw=$(tmux show-environment -t "$session" "$v" 2>/dev/null)

    if [[ "$raw" == "$v="* ]]; then
      val="${raw#${v}=}"
      export "$v=$val"
    else
      unset "$v"
    fi
  done
}

add-zsh-hook precmd tmuxsync
