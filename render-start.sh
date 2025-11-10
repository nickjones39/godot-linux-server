#!/usr/bin/env bash
set -e

# 1) download godot 4.5.1 linux x86_64
curl -L -o godot.x86_64 https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_linux.x86_64
chmod +x godot.x86_64

# 2) run it headless with your pack
./godot.x86_64 --headless --main-pack server.pck
