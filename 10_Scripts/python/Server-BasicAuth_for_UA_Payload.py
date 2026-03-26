from http.server import HTTPServer, SimpleHTTPRequestHandler
import base64
import time
from collections import deque

# --- 設定 ---
USER = "admin"
PASS = "password123"
AUTH_STR = base64.b64encode(f"{USER}:{PASS}".encode()).decode()

# 統計用データ
request_times = deque(maxlen=100) # 直近100件のタイムスタンプ

class VerboseAuthHandler(SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        # 標準のログ出力を抑制して、カスタム表示を見やすくする
        return

    def do_GET(self):
        # 1. 統計計算 (秒間リクエスト数)
        current_time = time.time()
        request_times.append(current_time)

        # 直近1秒間のリクエスト数を計算
        rps = len([t for t in request_times if current_time - t < 1.0])

        # 2. データの抽出
        ua = self.headers.get('User-Agent', 'Unknown')
        auth_header = self.headers.get('Authorization', 'None')

        # ペイロード（Basic認証の場合はBase64デコード）
        payload = "None"
        if auth_header.startswith("Basic "):
            try:
                encoded = auth_header.split(" ")[1]
                payload = base64.b64decode(encoded).decode()
            except:
                payload = f"Malformed: {auth_header}"

        # 3. ターミナルへの詳細表示
        print(f"\n" + "="*50)
        print(f"[*] [STATS] Requests Per Second: {rps}")
        print(f"[*] [UA   ] {ua}")
        print(f"[*] [DATA ] {payload}")
        print(f"[*] [RAW  ] {auth_header}")
        print("="*50)

        # 4. 認証ロジック
        if auth_header != f"Basic {AUTH_STR}":
            self.send_response(401)
            self.send_header('WWW-Authenticate', 'Basic realm="Test"')
            self.end_headers()
            self.wfile.write(b"Unauthorized")
        else:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Success!")

if __name__ == '__main__':
    print("Security Lab Server started on http://localhost:8000")
    print("Ready for Brute Force Analysis...")
    HTTPServer(('', 8000), VerboseAuthHandler).serve_forever()