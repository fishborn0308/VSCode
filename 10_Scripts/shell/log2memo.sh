#!/usr/bin/env bash
set -euo pipefail

if [ -z "${TARGET_IP:-}" ]; then
    echo "[-] TARGET_IP が設定されていません。target コマンドを実行してください。"
    exit 1
fi

TARGET_BASE="$HOME/Vault/Target/$TARGET_IP"
LOG_DIR="$TARGET_BASE/log"
OBSIDIAN_NOTE="$TARGET_BASE/攻略メモ.md"

if [ ! -d "$LOG_DIR" ]; then
    echo "[-] ログディレクトリが見つかりません: $LOG_DIR"
    exit 1
fi

LATEST_LOG="$(
    find "$LOG_DIR" -maxdepth 1 -type f -name '*.log' -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr \
    | head -n 1 \
    | cut -d' ' -f2-
)"

if [ -z "$LATEST_LOG" ]; then
    echo "[-] ログファイルが見つかりません: $LOG_DIR"
    exit 1
fi

mkdir -p "$(dirname "$OBSIDIAN_NOTE")"
touch "$OBSIDIAN_NOTE"

echo "[+] 処理中のログ: $(basename "$LATEST_LOG")"

strip_ansi() {
    sed -r 's/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGKHFJ]//g'
}

{
    echo
    echo "## Terminal Log ($(date '+%Y-%m-%d %H:%M:%S'))"
    echo
    echo "**Source:** \`$(basename "$LATEST_LOG")\`"
    echo
    echo '```bash'
    if command -v col >/dev/null 2>&1; then
        cat "$LATEST_LOG" | strip_ansi | col -b
    else
        cat "$LATEST_LOG" | strip_ansi
    fi
    echo '```'
} >> "$OBSIDIAN_NOTE"

echo "[+] $OBSIDIAN_NOTE にログを追記しました。"
