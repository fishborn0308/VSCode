from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.parse
import time
from collections import deque

# --- 設定 ---
USER = "admin"
PASS = "password123"

# 統計用データ
request_times = deque(maxlen=100)

class VerboseFormHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # 標準ログを抑制
        return

    def do_GET(self):
        # フォームの表示
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()
        html = """
        <html><body><h2>Login Test Page</h2>
        <form method="POST">
            User: <input type="text" name="username"><br>
            Pass: <input type="password" name="password"><br>
            <input type="submit" value="Login">
        </form></body></html>
        """
        self.wfile.write(html.encode())

    def do_POST(self):
        # 1. 統計計算 (秒間リクエスト数)
        current_time = time.time()
        request_times.append(current_time)
        rps = len([t for t in request_times if current_time - t < 1.0])

        # 2. データの抽出
        content_length = int(self.headers.get('Content-Length', 0))
        raw_post_data = self.rfile.read(content_length).decode('utf-8')
        ua = self.headers.get('User-Agent', 'Unknown')

        # パラメータをパース
        params = urllib.parse.parse_qs(raw_post_data)
        username = params.get('username', [''])[0]
        password = params.get('password', [''])[0]

        # 3. ターミナルへの詳細表示
        print(f"\n" + "="*60)
        print(f"[*] [STATS] Requests Per Second: {rps}")
        print(f"[*] [UA   ] {ua}")
        print(f"[*] [RAW  ] {raw_post_data}") # 生の送信データを確認
        print(f"[*] [PARSED] User: {username} / Pass: {password}")
        print("="*60)

        # 4. 認証ロジックとレスポンス
        if username == USER and password == PASS:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Login Success!")
        else:
            # 多くのツールはレスポンスコードや文字列で成功・失敗を判定します
            self.send_response(401)
            self.end_headers()
            self.wfile.write(b"Login Failed")

if __name__ == '__main__':
    print("Form Auth Lab Server started on http://localhost:8000")
    print("Monitoring UA, Raw Payload, and RPS...")
    HTTPServer(('', 8000), VerboseFormHandler).serve_forever()
