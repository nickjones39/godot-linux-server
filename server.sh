#!/usr/bin/env bash
set -e

# change to your real tag and filename
ASSET_URL="https://github.com/nickjones39/godot-linux-server/releases/download/binary/Godot_v4.5.1-stable_linux.x86_64.zip"

echo "[server.sh] downloading Godot..."
curl -L -o godot.zip "$ASSET_URL"

echo "[server.sh] unzipping..."
unzip -o godot.zip

# this is the name inside the zip
chmod +x Godot_v4.5.1-stable_linux.x86_64

PORT_ENV=${PORT:-8080}
echo "[server.sh] starting Godot on port $PORT_ENV..."
./Godot_v4.5.1-stable_linux.x86_64 --headless --main-pack server.pck -- --port=$PORT_ENV