refresh_oscp_prompt() {
  local my_ip
  local default_if

  # 1. tun0 (HTB/TryHackMe などの VPN) を最優先
  my_ip=$(ip -br -4 a show tun0 2>/dev/null | awk '$2=="UP" {print $3}' | cut -d/ -f1)

  # 2. Docker関連 (br-* / docker0)
  if [[ -z "$my_ip" ]]; then
    my_ip=$(ip -br -4 a | awk '$1 ~ /^(docker0|br-)/ && $2=="UP" {print $3}' | head -n 1 | cut -d/ -f1)
  fi

  # 3. デフォルトルートのIFを使う
  if [[ -z "$my_ip" ]]; then
    default_if=$(ip route 2>/dev/null | awk '/^default via/ {print $5; exit}')
    [[ -n "$default_if" ]] && my_ip=$(ip -br -4 a show "$default_if" 2>/dev/null | awk '$2=="UP" {print $3}' | cut -d/ -f1)
  fi

  CURRENT_MY_IP="${my_ip:-N/A}"

  if [[ -n "$TARGET_IP" ]]; then
    TARGET_STATUS="%F{red}[T: ${TARGET_IP}${TARGET_NAME:+ ($TARGET_NAME)}]%f"
  else
    TARGET_STATUS=""
  fi
}

add-zsh-hook precmd refresh_oscp_prompt

setopt prompt_subst
PROMPT='%F{cyan}[L: ${CURRENT_MY_IP}]%f %F{blue}%~%f %# '
RPROMPT='${TARGET_STATUS}'
