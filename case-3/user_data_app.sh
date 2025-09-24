#!/bin/bash
set -euxo pipefail
exec > /var/log/bootstrap-app.log 2>&1

dnf -y install python3
cat >/opt/app.py <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import socket

class H(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith("/hello"):
            msg = f"Hello from private app on {socket.gethostname()}!"
            self.send_response(200); self.end_headers(); self.wfile.write(msg.encode()); return
        self.send_response(200); self.end_headers(); self.wfile.write(b"OK")
if __name__ == "__main__":
    HTTPServer(("", 8080), H).serve_forever()
PY

nohup python3 /opt/app.py >/var/log/app.log 2>&1 &
echo "App started on :8080"