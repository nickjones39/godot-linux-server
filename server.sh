#!/usr/bin/env bash
set -e

ASSET_URL="https://github.com/nickjones39/godot-linux-server/releases/download/binary/Godot_v4.5.1-stable_linux.x86_64.zip"
GODOT_BIN="Godot_v4.5.1-stable_linux.x86_64"

echo "[server.sh] starting…"

# 1) download Godot once (kept – your image is small)
if [ ! -f "$GODOT_BIN" ]; then
  echo "[server.sh] downloading Godot..."
  curl -L -o godot.zip "$ASSET_URL"
  echo "[server.sh] unzipping..."
  unzip -o godot.zip
  chmod +x "$GODOT_BIN"
else
  echo "[server.sh] Godot already present, skipping download."
fi

# Render tells us which port to listen on publicly
PORT_ENV=${PORT:-10000}

# 2) start Godot on a fixed *internal* port (10000)
#    your Godot project already does `create_server(port)` from GDScript
echo "[server.sh] starting Godot on internal port 10000..."
./"$GODOT_BIN" --headless --main-pack server.pck -- --port=10000 &
GODOT_PID=$!

# give Godot a moment to bind 10000 so proxy won’t race it
sleep 1

# 3) start Node proxy on the Render port → forward to internal 10000
#    (proxy.js reads PORT and TARGET_PORT)
echo "[server.sh] starting node proxy on port $PORT_ENV..."
PORT="$PORT_ENV" TARGET_PORT=10000 node /app/proxy.js &
PROXY_PID=$!

# 4) if either dies, exit so Render restarts the container
wait -n "$GODOT_PID" "$PROXY_PID"

echo "[server.sh] one of the processes exited, shutting down."
exit 1