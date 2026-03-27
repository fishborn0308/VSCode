#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Safe Shutdown
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖
# @raycast.packageName shutdown

# Documentation:
# @raycast.description all app quit before shutdown
# @raycast.author fishborn0308
# @raycast.authorURL https://raycast.com/fishborn0308

-- 1. 他のすべてのアプリケーションを終了させる
tell application "System Events"
    set visibleApps to name of every process whose visible is true and name is not "Finder"
end tell

repeat with appName in visibleApps
    tell application appName to quit
end repeat

-- 2. 少し待機（アプリの終了処理時間を確保）
delay 2

-- 3. シャットダウンを実行
tell application "System Events" to shut down

