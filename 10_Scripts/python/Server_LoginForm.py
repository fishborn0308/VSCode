from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.parse

# テスト用の正解データ
USER = "admin"
PASS = "password123"

class FormAuthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # ログインフォームのHTMLを表示
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.end_headers()
        html = """
        <html>
            <body>
                <h2>Login Test Page</h2>
                <form method="POST">
                    User: <input type="text" name="username"><br>
                    Pass: <input type="password" name="password"><br>
                    <input type="submit" value="Login">
                </form>
            </body>
        </html>
        """
        self.wfile.write(html.encode())

    def do_POST(self):
        # 送信されたデータの長さを取得
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length).decode('utf-8')

        # パラメータをパース
        params = urllib.parse.parse_qs(post_data)
        username = params.get('username', [''])[0]
        password = params.get('password', [''])[0]

        # 解析用にコンソールに出力
        print(f"[Captured] User: {username}, Pass: {password}")

        if username == USER and password == PASS:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"Login Success!")
        else:
            self.send_response(401)
            self.end_headers()
            self.wfile.write(b"Login Failed")

if __name__ == '__main__':
    print("Serving Login Form on port 8000...")
    HTTPServer(('', 8000), FormAuthHandler).serve_forever()