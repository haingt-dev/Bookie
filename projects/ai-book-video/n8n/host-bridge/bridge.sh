#!/usr/bin/env bash
# =============================================================================
# Host Bridge — HTTP server for n8n → host command execution
#
# SECURITY: LOCAL DEVELOPMENT ONLY. No auth, no TLS.
# All script execution goes through this bridge since n8n runs in Docker
# and can't access host tools (python3, ffmpeg, GPU).
#
# Usage:
#   ./bridge.sh                         # port 3456, auto-detect project dir
#   ./bridge.sh --port 4000             # custom port
#   ./bridge.sh --project-dir /path     # custom project directory
# =============================================================================

set -euo pipefail

PORT=3456
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --port) PORT="$2"; shift 2 ;;
        --project-dir) PROJECT_DIR="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--port PORT] [--project-dir DIR]"
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

echo "[bridge] Port: $PORT | Project: $PROJECT_DIR | LOCAL DEV ONLY"

export BRIDGE_PORT="$PORT"
export BRIDGE_PROJECT_DIR="$PROJECT_DIR"

exec python3 -u << 'PYTHON_SERVER'
import http.server
import json
import subprocess
import sys
import os
from datetime import datetime
from pathlib import Path

PORT = int(os.environ.get("BRIDGE_PORT", "3456"))
PROJECT_DIR = os.environ.get("BRIDGE_PROJECT_DIR", os.getcwd())


class BridgeHandler(http.server.BaseHTTPRequestHandler):
    """
    Commands:
      - make targets: voice, render, images, subtitle, scenes, sync, validate, init, render-shorts, studio, status
      - file ops: read-file, write-file, scan-books
      - raw: run arbitrary shell command (for flexibility)
    """

    # Make targets that require BOOK=<slug>
    MAKE_BOOK_COMMANDS = {"voice", "render", "images", "subtitle", "scenes", "sync", "validate", "init", "render-shorts", "studio"}
    # Make targets that don't need BOOK
    MAKE_SIMPLE_COMMANDS = {"status"}
    # Special commands
    SPECIAL_COMMANDS = {"read-file", "write-file", "scan-books", "vixtts-health"}
    # Compound commands — whitelisted multi-step sequences (no shell=True)
    COMPOUND_COMMANDS = {
        "produce-visuals": ["images", "subtitle"],
        "produce-render": ["scenes", "sync", "validate", "render"],
        "produce-all": ["images", "subtitle", "scenes", "sync", "validate", "render"],
    }

    def log_message(self, format, *args):
        ts = datetime.now().strftime("%H:%M:%S")
        sys.stderr.write(f"[bridge {ts}] {format % args}\n")

    def _json(self, code, data):
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_OPTIONS(self):
        self.send_response(204)
        for h, v in [("Access-Control-Allow-Origin", "*"),
                      ("Access-Control-Allow-Methods", "GET, POST, OPTIONS"),
                      ("Access-Control-Allow-Headers", "Content-Type")]:
            self.send_header(h, v)
        self.end_headers()

    def do_GET(self):
        all_cmds = sorted(self.MAKE_BOOK_COMMANDS | self.MAKE_SIMPLE_COMMANDS | self.SPECIAL_COMMANDS)
        self._json(200, {"status": "ok", "service": "host-bridge", "project_dir": PROJECT_DIR, "commands": all_cmds})

    def do_POST(self):
        try:
            body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
            data = json.loads(body.decode()) if body else {}
        except Exception as e:
            return self._json(400, {"status": "error", "error": f"Bad request: {e}"})

        cmd = data.get("command", "")
        book = data.get("book", "")

        # Make targets with BOOK=
        if cmd in self.MAKE_BOOK_COMMANDS:
            if not book:
                return self._json(400, {"status": "error", "error": f"'{cmd}' requires 'book' field"})
            return self._exec(["make", cmd, f"BOOK={book}"] + data.get("args", []))

        # Make targets without BOOK
        if cmd in self.MAKE_SIMPLE_COMMANDS:
            return self._exec(["make", cmd] + data.get("args", []))

        # Read a file relative to project dir
        if cmd == "read-file":
            path = data.get("path", "")
            if not path:
                return self._json(400, {"status": "error", "error": "'path' required"})
            full = os.path.join(PROJECT_DIR, path)
            # Security: must be within project dir
            if not os.path.realpath(full).startswith(os.path.realpath(PROJECT_DIR)):
                return self._json(403, {"status": "error", "error": "Path outside project dir"})
            try:
                content = Path(full).read_text()
                return self._json(200, {"status": "ok", "content": content, "path": path})
            except FileNotFoundError:
                return self._json(404, {"status": "error", "error": f"File not found: {path}"})
            except Exception as e:
                return self._json(500, {"status": "error", "error": str(e)})

        # Write a file relative to project dir
        if cmd == "write-file":
            path = data.get("path", "")
            content = data.get("content", "")
            if not path:
                return self._json(400, {"status": "error", "error": "'path' required"})
            full = os.path.join(PROJECT_DIR, path)
            if not os.path.realpath(os.path.dirname(full)).startswith(os.path.realpath(PROJECT_DIR)):
                return self._json(403, {"status": "error", "error": "Path outside project dir"})
            try:
                os.makedirs(os.path.dirname(full), exist_ok=True)
                Path(full).write_text(content)
                return self._json(200, {"status": "ok", "path": path, "bytes": len(content)})
            except Exception as e:
                return self._json(500, {"status": "error", "error": str(e)})

        # Scan books directory for artifacts
        if cmd == "scan-books":
            books_dir = os.path.join(PROJECT_DIR, "books")
            artifacts = [
                "notes.md", "storyboard.md", "chunks.md", "chunks-display.md",
                "image-prompts.md", "metadata.md",
                "audio/voiceover.wav", "output/section-timing.json",
                "output/subtitles.srt", "output/video.mp4"
            ]
            result = {}
            try:
                for slug in sorted(os.listdir(books_dir)):
                    book_path = os.path.join(books_dir, slug)
                    if not os.path.isdir(book_path):
                        continue
                    result[slug] = {}
                    for art in artifacts:
                        result[slug][art] = os.path.isfile(os.path.join(book_path, art))
            except Exception as e:
                return self._json(500, {"status": "error", "error": str(e)})
            return self._json(200, {"status": "ok", "books": result})

        # Compound commands — run multiple make targets in sequence
        if cmd in self.COMPOUND_COMMANDS:
            if not book:
                return self._json(400, {"status": "error", "error": f"'{cmd}' requires 'book' field"})
            results = []
            for step in self.COMPOUND_COMMANDS[cmd]:
                self.log_message(f"compound step: make {step} BOOK={book}")
                try:
                    r = subprocess.run(["make", step, f"BOOK={book}"], cwd=PROJECT_DIR,
                                       capture_output=True, text=True, timeout=600)
                    results.append({"step": step, "returncode": r.returncode, "output": r.stdout[-500:], "error": r.stderr[-500:]})
                    if r.returncode != 0:
                        return self._json(500, {"status": "error", "failed_step": step, "results": results})
                except subprocess.TimeoutExpired:
                    return self._json(504, {"status": "error", "failed_step": step, "error": f"Timeout at step '{step}'"})
            return self._json(200, {"status": "ok", "results": results})

        # viXTTS health check
        if cmd == "vixtts-health":
            return self._exec(["curl", "-sf", "http://localhost:8020/speakers"], timeout=10)

        return self._json(400, {"status": "error", "error": f"Unknown command: {cmd}"})

    def _exec(self, cmd, shell=False, timeout=600):
        self.log_message(f"exec: {cmd if isinstance(cmd, str) else ' '.join(cmd)}")
        try:
            r = subprocess.run(cmd, cwd=PROJECT_DIR, capture_output=True, text=True, timeout=timeout, shell=shell)
            return self._json(200 if r.returncode == 0 else 500, {
                "status": "ok" if r.returncode == 0 else "error",
                "output": r.stdout, "error": r.stderr, "returncode": r.returncode
            })
        except subprocess.TimeoutExpired:
            return self._json(504, {"status": "error", "error": f"Timeout ({timeout}s)"})
        except Exception as e:
            return self._json(500, {"status": "error", "error": str(e)})


if __name__ == "__main__":
    server = http.server.HTTPServer(("127.0.0.1", PORT), BridgeHandler)
    print(f"[bridge] Listening on 127.0.0.1:{PORT} (localhost only)", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[bridge] Shutting down", file=sys.stderr)
        server.shutdown()
PYTHON_SERVER
