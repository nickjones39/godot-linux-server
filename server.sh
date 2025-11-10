#!/usr/bin/env bash
set -euo pipefail

GODOT_BIN="/app/Godot_v4.5.1-stable_linux.x86_64"
PACK_FILE="/app/server.pck"

# Fly will map 80/443 → your process, but your container listens on this:
PORT_ENV=${PORT:-10000}
INTERNAL_GODOT_PORT=10001

echo "[server.sh] starting…"

# 1) sanity check
if [ ! -x "$GODOT_BIN" ]; then
  echo "[server.sh] FATAL: Godot binary not found at $GODOT_BIN"
  exit 1
fi

if [ ! -f "$PACK_FILE" ]; then
  echo "[server.sh] FATAL: pack not found at $PACK_FILE"
  exit 1
fi

# 2) start Godot headless on the internal port
echo "[server.sh] starting Godot on internal port $INTERNAL_GODOT_PORT..."
"$GODOT_BIN" --headless --main-pack "$PACK_FILE" -- --port="$INTERNAL_GODOT_PORT" &
GODOT_PID=$!

# 3) start Node proxy on the public port → forward to internal
echo "[server.sh] starting node proxy on port $PORT_ENV -> $INTERNAL_GODOT_PORT..."
PORT="$PORT_ENV" TARGET_PORT="$INTERNAL_GODOT_PORT" node /app/proxy.js &
PROXY_PID=$!

# 4) wait for proxy to be ready so Fly’s health check stops complaining
echo "[server.sh] waiting for proxy on 0.0.0.0:${PORT_ENV} ..."
for i in {1..20}; do
  if nc -z 0.0.0.0 "$PORT_ENV" 2>/dev/null; then
    echo "[server.sh] proxy is up."
    break
  fi
  sleep 0.5
done

# 5) if either dies, we die → Fly restarts us (or keeps since you set schedule=always)
wait -n "$GODOT_PID" "$PROXY_PID"

echo "[server.sh] one of the processes exited, shutting down."
exit 1