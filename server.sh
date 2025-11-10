#!/usr/bin/env bash
set -e

ASSET_URL="https://github.com/nickjones39/godot-linux-server/releases/download/binary/Godot_v4.5.1-stable_linux.x86_64.zip"
GODOT_BIN="Godot_v4.5.1-stable_linux.x86_64"

echo "[server.sh] starting…"

# ─────────────────────────────────────────
# 1) download Godot once
# ─────────────────────────────────────────
if [ ! -f "$GODOT_BIN" ]; then
  echo "[server.sh] downloading Godot..."
  curl -L -o godot.zip "$ASSET_URL"
  echo "[server.sh] unzipping..."
  unzip -o godot.zip
  chmod +x "$GODOT_BIN"
else
  echo "[server.sh] Godot already present, skipping download."
fi

# Render gives us the public port
PORT_ENV=${PORT:-10000}

# ─────────────────────────────────────────
# 2) start Godot headless on the *internal* WS port 10000
#    (this is the port your Godot project reads via --port=10000)
# ─────────────────────────────────────────
echo "[server.sh] starting Godot on port 10000..."
./"$GODOT_BIN" --headless --main-pack server.pck -- --port=10000 &
GODOT_PID=$!

# give Godot a moment to bind 10000 so the proxy doesn’t race it
sleep 1

# ─────────────────────────────────────────
# 3) start Node proxy on the Render port → forward to 10000
# ─────────────────────────────────────────
echo "[server.sh] starting node proxy on port $PORT_ENV..."
PORT=$PORT_ENV TARGET_PORT=10000 node /app/proxy.js &
PROXY_PID=$!

# ─────────────────────────────────────────
# 4) wait on both — if either dies, we die, so Render restarts us
# ─────────────────────────────────────────
wait $GODOT_PID
wait $PROXY_PID