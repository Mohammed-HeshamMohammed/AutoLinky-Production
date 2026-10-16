"""Private extraction endpoint; each parse has a separate process and a hard deadline."""
import hmac
import json
import os
from pathlib import Path
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from threading import BoundedSemaphore

MAX_BYTES = 4 * 1024 * 1024
SLOTS = BoundedSemaphore(1)
KEY = os.environ.get('CV_EXTRACTOR_KEY', '')

class Handler(BaseHTTPRequestHandler):
    server_version = 'Extractor'
    sys_version = ''

    def log_message(self, *_args):
        pass

    def respond(self, code, body):
        encoded = json.dumps(body).encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(encoded)))
        self.send_header('Connection', 'close')
        self.end_headers()
        self.wfile.write(encoded)
        self.close_connection = True

    def do_GET(self):
        self.respond(200 if self.path == '/health' else 404, {'status': 'ok'} if self.path == '/health' else {'detail': 'Not found'})

    def do_POST(self):
        if self.path != '/extract':
            return self.respond(404, {'detail': 'Not found'})
        if len(KEY) < 32 or not hmac.compare_digest(self.headers.get('X-Extractor-Key', ''), KEY):
            return self.respond(401, {'detail': 'Unauthorized'})
        try:
            size = int(self.headers.get('Content-Length', '-1'))
        except ValueError:
            size = -1
        if size < 0:
            return self.respond(411, {'detail': 'Content length required'})
        if size > MAX_BYTES:
            return self.respond(413, {'detail': 'cv_too_large'})
        if not SLOTS.acquire(blocking=False):
            return self.respond(503, {'detail': 'extractor_busy'})
        try:
            self.connection.settimeout(10)
            data = self.rfile.read(size)
            if len(data) != size:
                return self.respond(400, {'detail': 'cv_empty'})
            child = subprocess.run([sys.executable, '-B', str(Path(__file__).with_name('worker.py'))], input=data,
                                   stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=10, check=True)
            result = json.loads(child.stdout)
            if 'error' in result:
                return self.respond(result['status'], {'detail': result['error']})
            self.respond(200, result['result'])
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError, TimeoutError, ValueError):
            self.respond(503, {'detail': 'extractor_unavailable'})
        finally:
            SLOTS.release()

if __name__ == '__main__':
    if len(KEY) < 32:
        raise SystemExit('CV_EXTRACTOR_KEY must contain at least 32 characters')
    ThreadingHTTPServer((os.environ.get('HOST', '127.0.0.1'), int(os.environ.get('PORT', '4001'))), Handler).serve_forever()
