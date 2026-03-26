from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
import urllib.parse
import time
import threading

# --- 設定 ---
USER = "admin"
PASS = "password123"

# 統計用グローバル変数
request_count = 0
last_check_time = time.time()
current_rps = 0
lock = threading.Lock()

class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True

class HighPerformanceFormHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args): return # ログ抑制

    # 【復活】ブラウザでアクセスした時にフォームを表示する
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()
        html = """
        <html>
            <body style="font-family: sans-serif;">
                <h2>Login Test Page (High-Speed Mode)</h2>
                <form method="POST">
                    User: <input type="text" name="username"><br><br>
                    Pass: <input type="password" name="password"><br><br>
                    <input type="submit" value="Login">
                </form>
                <p style="color: gray;">Monitoring RPS in terminal...</p>
            </body>
        </html>
        """
        self.wfile.write(html.encode())

    # 爆速POST処理（Legba/Hydra用）
    def do_POST(self):
        global request_count, current_rps, last_check_time

        # 1. 統計計算
        with lock:
            request_count += 1
            now = time.time()
            elapsed = now - last_check_time
            if elapsed >= 1.0:
                current_rps = request_count / elapsed
                request_count = 0
                last_check_time = now
                print(f"[*] [LIVE STATS] RPS: {current_rps:.2f}")

        # 2. データの取得
        content_length = int(self.headers.get('Content-Length', 0))
        raw_post_data = self.rfile.read(content_length).decode('utf-8', errors='ignore')
        ua = self.headers.get('User-Agent', 'Unknown')

        # 3. 認証ロジック
        params = urllib.parse.parse_qs(raw_post_data)
        username = params.get('username', [''])[0]
        password = params.get('password', [''])[0]

        if username == USER and password == PASS:
            print(f"\n[!!!] SUCCESS: {username}:{password} | UA: {ua}\n")
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Success")
        else:
            self.send_response(401)
            self.end_headers()
            self.wfile.write(b"Fail")

if __name__ == '__main__':
    print("Multithreaded Login Form Server started on http://localhost:8000")
    print("Now you can open this in your browser AND attack with Legba.")
    server = ThreadingHTTPServer(('', 8000), HighPerformanceFormHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()