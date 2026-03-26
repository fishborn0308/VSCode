from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn
import base64
import time
import threading

# --- 設定 ---
USER = "admin"
PASS = "password123"
AUTH_STR = f"Basic {base64.b64encode(f'{USER}:{PASS}'.encode()).decode()}"

# 統計用グローバル変数
request_count = 0
last_check_time = time.time()
current_rps = 0
lock = threading.Lock()

class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    """リクエストごとにスレッドを生成し、並列処理を可能にする"""
    daemon_threads = True

class HighSpeedAuthHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args): return # 標準ログを無効化して速度優先

    def do_GET(self):
        global request_count, current_rps, last_check_time

        # 1. 統計計算（スレッドセーフ）
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
        auth_header = self.headers.get('Authorization', 'None')
        ua = self.headers.get('User-Agent', 'Unknown')

        # 3. 認証ロジック
        if auth_header == AUTH_STR:
            # 成功時のみ詳細を表示（攻撃中は画面が流れるのを防ぐため）
            print(f"\n[!!!] SUCCESS! | UA: {ua} | RAW: {auth_header}\n")
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Authenticated")
        else:
            # 失敗時は401を返してツールに継続させる
            self.send_response(401)
            self.send_header('WWW-Authenticate', 'Basic realm="Lab"')
            self.end_headers()
            self.wfile.write(b"Unauthorized")

if __name__ == '__main__':
    print("High-Speed Basic Auth Server (Parallel) started on port 8000")
    print("Ready for high-concurrency testing with Legba / Hydra.")
    server = ThreadingHTTPServer(('', 8000), HighSpeedAuthHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        server.shutdown()