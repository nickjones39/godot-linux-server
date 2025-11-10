#!/usr/bin/env bash
set -e

ASSET_URL="https://github.com/nickjones39/godot-linux-server/releases/download/binary/Godot_v4.5.1-stable_linux.x86_64.zip"
GODOT_BIN="Godot_v4.5.1-stable_linux.x86_64"

echo "[server.sh] starting…"

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
echo "[server.sh] starting Godot on port $PORT_ENV..."
./"$GODOT_BIN" --headless --main-pack server.pck -- --port="$PORT_ENV"