from http.server import BaseHTTPRequestHandler, HTTPServer
import sqlite3
import json
import signal
import sys
import logging

# 로깅 설정 (systemd journal에서 식별하기 위함)
logging.basicConfig(level=logging.INFO, format='[HSS-CORE] %(message)s')

class HSSHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/api/v1/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "OK", "service": "HSS Core Active (Systemd Daemon)"}).encode())
            logging.info("Status check received.")
        else:
            self.send_response(404)
            self.end_headers()

def run(server_class=HTTPServer, handler_class=HSSHandler, port=8443):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    
    # Graceful Shutdown 핸들러 정의
    def handle_exit(signum, frame):
        logging.info(f"Received signal {signum}. Shutting down gracefully...")
        # DB 커넥션 등 자원 정리 필요 시 여기서 수행
        httpd.server_close()
        logging.info("HSS Core server stopped.")
        sys.exit(0)

    # OS 시그널 등록 (Systemd stop 시 SIGTERM을 보냄)
    signal.signal(signal.SIGINT, handle_exit)
    signal.signal(signal.SIGTERM, handle_exit)

    logging.info(f"HSS Core Service starting on port {port}...")
    try:
        httpd.serve_forever()
    except Exception as e:
        logging.error(f"Server error: {e}")

if __name__ == '__main__':
    run()
