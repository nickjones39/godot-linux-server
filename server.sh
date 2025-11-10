#!/usr/bin/env bash
set -e

# Godot 4.5.1 Linux x86_64 from the official mirror
GODOT_URL="https://downloads.tuxfamily.org/godotengine/4.5.1/Godot_v4.5.1-stable_linux.x86_64.zip"

echo "[server.sh] downloading Godot from $GODOT_URL ..."
curl -L -o godot.zip "$GODOT_URL"

echo "[server.sh] unpacking..."
unzip -o godot.zip
# after unzip you usually get: Godot_v4.5.1-stable_linux.x86_64
chmod +x Godot_v4.5.1-stable_linux.x86_64

# Render gives us the port in $PORT — pass it through
PORT_ENV=${PORT:-8080}
echo "[server.sh] starting Godot on port $PORT_ENV ..."

# run headless with your packed game
./Godot_v4.5.1-stable_linux.x86_64 --headless --main-pack server.pck -- --port=$PORT_ENV