#!/usr/bin/env bash
set -e

# pick the version you exported with
GODOT_URL="https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_linux.x86_64"

echo "[server.sh] downloading Godot headless/editor build..."
curl -L -o godot.x86_64 "$GODOT_URL"
chmod +x godot.x86_64

# Render gives us the port in $PORT — pass it to Godot
PORT_ENV=\${PORT:-8080}

echo "[server.sh] starting Godot on port \$PORT_ENV..."
./godot.x86_64 --headless --main-pack server.pck -- --port=\$PORT_ENV
