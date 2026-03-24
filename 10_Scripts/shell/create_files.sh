#!/bin/bash
# ファイルリストから複数のファイルを一括で生成するスクリプト
# 引数が1つ指定されているか確認
if [ "$#" -ne 1 ]; then
  echo "Error: Missing argument."
  echo "Usage: $0 <file_list.txt>"
  exit 1
fi

# 1つ目の引数を変数に代入
FILE_LIST="$1"

# テキストファイルが存在するか確認
if [ ! -f "$FILE_LIST" ]; then
  echo "Error: File list '$FILE_LIST' not found."
  exit 1
fi

# 1行ずつ読み込んでファイルを生成
while IFS= read -r filename; do
  # 1行ずつ読み込んでファイルを生成
  if [ -n "$filename" ]; then
    # ファイルのパスからディレクトリ部分を取得
    dir=$(dirname "$filename")
    # ディレクトリが存在しない場合は作成 (-p オプションで深い階層も一度に作成)
    if [ ! -d "$dir" ]; then
      mkdir -p "$dir"
    fi

    # ファイルを作成
    touch "$filename"
    echo "Created: $filename"
  fi
done < "$FILE_LIST"

echo "All files have been created successfully."