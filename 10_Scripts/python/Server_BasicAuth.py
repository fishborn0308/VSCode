from http.server import HTTPServer, SimpleHTTPRequestHandler
import base64

# 設定したいユーザー名とパスワード
USER = "admin"
PASS = "password123"
AUTH_STR = base64.b64encode(f"{USER}:{PASS}".encode()).decode()

class AuthHandler(SimpleHTTPRequestHandler):
    def do_HEAD(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

    def do_GET(self):
        # Authorizationヘッダーのチェック
        auth_header = self.headers.get('Authorization')
        if auth_header is None or auth_header != f"Basic {AUTH_STR}":
            self.send_response(401)
            self.send_header('WWW-Authenticate', 'Basic realm="Test"')
            self.end_headers()
            self.wfile.write(b"Auth failed")
        else:
            # 認証成功時は通常のファイル表示を行う
            super().do_GET()

if __name__ == '__main__':
    print("Serving on port 8000 with Basic Auth...")
    HTTPServer(('', 8000), AuthHandler).serve_forever()