#!/usr/bin/env python3

import re

def extract_file_paths(text: str) -> list[str]:
    """
    テキストの中からファイルパスと思われる文字列を抽出します。

    Windows, Linux, 相対パスなど、一般的な形式に対応しています。
    - Windows絶対パス (例: C:\\Users\\Default\\ntuser.dat)
    - UNCパス (例: \\\\server\\share\\file.zip)
    - Linux/macOS絶対パス (例: /var/log/syslog)
    - ホームディレクトリパス (例: ~/documents/report.docx)
    - 相対パス (例: ./data/sales.csv, ../images/icon.png)

    Args:
        text: 検索対象の文字列。

    Returns:
        抽出されたファイルパスのリスト。
    """
    # ファイルパスを検出するための正規表現パターン
    # 解説は後述します
    path_pattern = re.compile(r"""
        (?:
            # Windows系パス (C:\... or \\server\...)
            (?:[a-zA-Z]:|\\)\\(?:[\w\s.-]+\\)*[\w\s.-]+
            |
            # Unix/Linux系パス (/home/... or ~/... or ./... or ../...)
            (?:~|\.\.?|/[\w\s.-]+)/(?:[\w\s.-]+/)*[\w\s.-]+
            |
            # シンプルな相対パス (folder/file.ext)
            [\w\s.-]+/(?:[\w\s.-]+/)*[\w\s.-]+
        )
    """, re.VERBOSE)

    found_paths = re.findall(path_pattern, text)

    # クリーンアップ：パスの末尾に含まれる可能性のある句読点などを取り除く
    cleaned_paths = [path.strip('.,;)"\'') for path in found_paths]

    return cleaned_paths

# --- ここから実行部分 ---
if __name__ == "__main__":
    # このサンプルテキストの中からファイルパスを抜き出します
    sample_text = """
    設定ファイルは C:\\Users\\Default\\ntuser.dat にあります。
    ログは /var/log/syslog を確認してください。
    提出するレポートは ~/documents/report.docx です。
    必要なデータは ./data/sales.csv を参照。エラーの詳細はログファイルを確認。
    画像は ../images/icon.png を使ってください。
    ネットワーク上のファイルは \\\\server\\share\\file.zip にバックアップしました。
    プロジェクトのメインスクリプトは project/main.py です。
    これはファイルパスではありません: abc/def ghi:123
    ドキュメントはこちらです: "C:\\Program Files\\MyApp\\docs\\readme.txt", 確認してください。
    """

    print("---  ---")
    print(sample_text)

    # 関数を呼び出してファイルパスを抽出
    extracted_paths = extract_file_paths(sample_text)

    print("\n--- Extracted file path ---")
    if extracted_paths:
        for path in extracted_paths:
            print(path)
    else:
        print("The file path was not found.")
