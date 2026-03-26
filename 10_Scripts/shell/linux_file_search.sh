#!/bin/bash

# ==========================================
# 1. 権限判定と初期設定 (Linpeas Core)
# ==========================================

if ([ -f /usr/bin/id ] && [ "$(/usr/bin/id -u)" -eq "0" ]) || [ "`whoami 2>/dev/null`" = "root" ]; then
  IAMROOT="1"
  MAXPATH_FIND_W="3"
else
  IAMROOT=""
  MAXPATH_FIND_W="7"
fi

TARGET="${1:-/}"
LOG_FILE="/tmp/pe_discovery_$(date +%Y%m%d).log"
GTFO_LIST="cp|find|vim|nano|python|perl|ruby|bash|sh|awk|sed|tar|zip|nmap|strace|gdb|git|socat|php|lua"

# カラー定義
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# ==========================================
# 2. クイック解析モジュール
# ==========================================

# A. 重要ファイルの権限 & NFSチェック
check_critical_config() {
  echo -e "${YELLOW}=== [!] Critical Configuration Scan ===${NC}"
  # 書き込み可能な重要ファイル
  local CRIT_FILES=("/etc/passwd" "/etc/shadow" "/etc/sudoers" "/etc/exports")
  for f in "${CRIT_FILES[@]}"; do
    [ -w "$f" ] && echo -e "${RED}[!!!] WRITABLE: $f${NC}"
  done

  # NFS no_root_squash
  if [ -f /etc/exports ]; then
    grep -q "no_root_squash" /etc/exports && echo -e "${RED}[!!!] NFS no_root_squash detected in /etc/exports${NC}"
  fi
}

# B. PATHハイジャック解析
check_path_vulnerability() {
  echo -e "\n${YELLOW}=== [!] PATH Hijacking Analysis ===${NC}"
  # システムの $PATH を分解
  echo "$PATH" | tr ':' '\n' | while read d; do
    if [ -w "$d" ]; then
      echo -e "${RED}[!!!] Writable directory in PATH: $d${NC} (Owner: $(ls -ld "$d" | awk '{print $3}'))"
    fi
  done
}

# C. Cron & 定期実行ファイルのパス解析
check_cron_path() {
  echo -e "\n${YELLOW}=== [!] Cron & Timer Path Analysis ===${NC}"
  # Crontab内のPATH設定
  grep "^PATH=" /etc/crontab 2>/dev/null | cut -d= -f2 | tr ':' '\n' | while read d; do
    [ -w "$d" ] && echo -e "${RED}[!!!] Writable PATH in /etc/crontab: $d${NC}"
  done

  # 実行されているスクリプト自体の書き込み権限
  grep -rE "/[a-zA-Z0-9./_-]+" /etc/cron* /var/spool/cron/crontabs/* 2>/dev/null | awk -F: '{print $2}' | grep "/" | while read -r cmd; do
    local exec_file=$(echo "$cmd" | awk '{print $1}')
    if [ -f "$exec_file" ] && [ -w "$exec_file" ]; then
      echo -e "${RED}[!!!] Writable Executable in Cron: $exec_file${NC}"
    fi
  done | sort -u
}

# D. SUID & Capabilities & GTFOBins
check_suids_caps() {
  echo -e "\n${YELLOW}=== [+] SUID & Capabilities & GTFOBins ===${NC}"
  # SUID探索
  find "$TARGET" -perm -4000 -type f 2>/dev/null | while read s; do
    local bname=$(basename "$s")
    local res="[SUID] $s"

    # GTFOBins照合
    if echo "$bname" | grep -iqE "($GTFO_LIST)"; then
      res="${res} ${YELLOW}<-- GTFO: https://gtfobins.github.io/gtfobins/$bname/#suid${NC}"
    fi

    # 書き込み権限
    if [ -w "$s" ]; then
      echo -e "${RED}[!!!] $res (WRITABLE!)${NC}"
    else
      echo -e "${GREEN}$res${NC}"
    fi
  done | head -n 20

  # Capabilities
  if command -v getcap >/dev/null; then
    getcap -r / 2>/dev/null | grep -v "cap_net_bind_service" | sed 's/^/ [CAP] /'
  fi
}

# ==========================================
# 3. 統合一括探索 (バックグラウンド)
# ==========================================
unified_deep_search() {
  echo -e "\n${YELLOW}=== [+] Starting Deep File Search (Background Logging) ===${NC}"
  echo "Scanning $TARGET with depth $MAXPATH_FIND_W..."

  local EXT_RE=".*\.\(sh\|py\|pl\|php\|cgi\|key\|pem\|bak\|sql\|config\)$"
  local KEY_RE=".*\(id_rsa\|shadow\|passwd\|secret\|creds\|backup\).*"

  # findの結果を1つのログにまとめる
  find "$TARGET" -maxdepth "$MAXPATH_FIND_W" \
    \( -path "/proc" -o -path "/sys" -o -path "/dev" -o -path "/var/lib" \) -prune -o \
    \( \
      \( -writable -type f -printf "[WRITE] %p\n" \) -o \
      \( -regex "$EXT_RE" -printf "[EXT] %p\n" \) -o \
      \( -regex "$KEY_RE" -printf "[KEY] %p\n" \) \
    \) 2>/dev/null > "$LOG_FILE"

  echo -e "${GREEN}[✔] Deep Search Complete. Full log: $LOG_FILE${NC}"
  echo -e "Summary: Writable($(grep -c "\[WRITE\]" "$LOG_FILE")), Ext($(grep -c "\[EXT\]" "$LOG_FILE")), Key($(grep -c "\[KEY\]" "$LOG_FILE"))"
}

# ==========================================
# 4. 実行
# ==========================================
clear
echo "=================================================="
echo -e " ${GREEN}PE COLLAB SHIFTER - Final Prototype${NC}"
echo " Privilege: $([ "$IAMROOT" ] && echo -e "${RED}ROOT${NC}" || echo -e "${YELLOW}USER${NC}")"
echo " Scan Depth: $MAXPATH_FIND_W | Target: $TARGET"
echo "=================================================="

check_critical_config
check_path_vulnerability
check_cron_path
check_suids_caps
unified_deep_search

echo -e "\n${YELLOW}Next Step:${NC} Review $LOG_FILE or check 'sudo -l'"