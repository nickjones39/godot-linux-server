#!/usr/bin/env bash
set -e

# 1) where your Godot binary lives
ASSET_URL="https://github.com/nickjones39/godot-linux-server/releases/download/binary/Godot_v4.5.1-stable_linux.x86_64.zip"
GODOT_BIN="Godot_v4.5.1-stable_linux.x86_64"

echo "[server.sh] starting…"

# 2) download only if we don't already have it
if [ ! -f "$GODOT_BIN" ]; then
  echo "[server.sh] downloading Godot..."
  curl -L -o godot.zip "$ASSET_URL"

  echo "[server.sh] unzipping..."
  unzip -o godot.zip
  chmod +x "$GODOT_BIN"
else
  echo "[server.sh] Godot already present, skipping download."
fi

# 3) Render gives us a port — your Godot WS server listens there
PORT_ENV=${PORT:-10000}
echo "[server.sh] starting Godot on port $PORT_ENV..."

# 4) run godot headless with your pack
./"$GODOT_BIN" --headless --main-pack server.pck -- --port="$PORT_ENV"

# 5) if Godot ever returns, sleep so Render doesn’t hammer-restart
echo "[server.sh] Godot exited, sleeping..."
sleep 3600