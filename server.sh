#!/usr/bin/env bash
set -e

GODOT_BIN="/app/Godot_v4.5.1-stable_linux.x86_64"
PACK_FILE="/app/server.pck"

# Render gives us this
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

# tiny pause so Godot binds before proxy dials it
sleep 1

# 3) start Node proxy on the public port → forward to internal
echo "[server.sh] starting node proxy on port $PORT_ENV -> $INTERNAL_GODOT_PORT..."
PORT="$PORT_ENV" TARGET_PORT="$INTERNAL_GODOT_PORT" node /app/proxy.js &
PROXY_PID=$!

# 4) if either dies, we die → Render restarts us
wait -n "$GODOT_PID" "$PROXY_PID"

echo "[server.sh] one of the processes exited, shutting down."
exit 1