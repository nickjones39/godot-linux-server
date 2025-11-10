#!/usr/bin/env bash
set -e

ASSET_URL="https://github.com/nickjones39/godot-linux-server/releases/download/binary/Godot_v4.5.1-stable_linux.x86_64.zip"
GODOT_BIN="Godot_v4.5.1-stable_linux.x86_64"

echo "[server.sh] starting…"

# download Godot if we don't have it yet
if [ ! -f "$GODOT_BIN" ]; then
  echo "[server.sh] downloading Godot..."
  curl -L -o godot.zip "$ASSET_URL"
  echo "[server.sh] unzipping..."
  unzip -o godot.zip
  chmod +x "$GODOT_BIN"
fi

# 1) start Godot headless on the same port the container will proxy to
PORT_ENV=${PORT:-10000}
echo "[server.sh] starting Godot on port $PORT_ENV..."
./"$GODOT_BIN" --headless --main-pack server.pck -- --port="$PORT_ENV" &
GODOT_PID=$!

# 2) start the HTTP+WS proxy on $PORT (same value) so Render sees an HTTP server
echo "[server.sh] starting node proxy on port $PORT_ENV..."
node /app/proxy.js &

# 3) wait for godot so container stays alive
wait $GODOT_PID