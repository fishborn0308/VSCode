#!/bin/bash

# 保存先（Obsidianのノートパス）
OBSIDIAN_NOTE="$HOME/Vault/Target/$TARGET_IP/攻略メモ.md"

if [ -z "$TARGET_IP" ]; then
    echo "[-] TARGET_IP が設定されていません。target コマンドを実行してください。"
    exit 1
fi

LOG_DIR="$HOME/Vault/Target/$TARGET_IP/log"
LATEST_LOG=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -n 1)

if [ -z "$LATEST_LOG" ]; then
    echo "[-] ログファイルが見つかりません: $LOG_DIR"
    exit 1
fi

echo "[+] 処理中のログ: $(basename "$LATEST_LOG")"

# 1. 制御文字（色のコードなど）を除去
# 2. Markdownのコードブロックで囲む
# 3. Obsidianのノートの末尾に追記
{
    echo -e "\n## Terminal Log ($(date '+%Y-%m-%d %H:%M:%S'))"
    echo '```bash'
    # ansifilter があれば最適ですが、なければ sed で代用
    cat "$LATEST_LOG" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g" | col -b
    echo '```'
} >> "$OBSIDIAN_NOTE"

echo "[+] $OBSIDIAN_NOTE にログを追記しました。"