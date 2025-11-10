#!/usr/bin/env bash
set -e

ASSET_URL="https://github.com/nickjones39/godot-linux-server/releases/download/binary/Godot_v4.5.1-stable_linux.x86_64.zip"
GODOT_BIN="Godot_v4.5.1-stable_linux.x86_64"

echo "[server.sh] starting…"

# 1) download Godot once
if [ ! -f "$GODOT_BIN" ]; then
  echo "[server.sh] downloading Godot..."
  curl -L -o godot.zip "$ASSET_URL"
  echo "[server.sh] unzipping..."
  unzip -o godot.zip
  chmod +x "$GODOT_BIN"
else
  echo "[server.sh] Godot already present, skipping download."
fi

PORT_ENV=${PORT:-10000}
INTERNAL_GODOT_PORT=10001

echo "[server.sh] starting Godot on internal port $INTERNAL_GODOT_PORT..."
./"$GODOT_BIN" --headless --main-pack server.pck -- --port=$INTERNAL_GODOT_PORT &
GODOT_PID=$!

sleep 1

echo "[server.sh] starting node proxy on port $PORT_ENV -> $INTERNAL_GODOT_PORT..."
PORT="$PORT_ENV" TARGET_PORT="$INTERNAL_GODOT_PORT" node /app/proxy.js &
PROXY_PID=$!

wait -n "$GODOT_PID" "$PROXY_PID"

echo "[server.sh] one of the processes exited, shutting down."
exit 1