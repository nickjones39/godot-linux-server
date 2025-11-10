# Dockerfile
FROM node:22-slim

# tools + libs Godot needs
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     curl \
     unzip \
     ca-certificates \
     libfontconfig1 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ─────────────────────────────
# 1) download Godot at BUILD time
# ─────────────────────────────
# if you change the release url, change it here
RUN curl -L -o godot.zip \
    https://github.com/nickjones39/godot-linux-server/releases/download/binary/Godot_v4.5.1-stable_linux.x86_64.zip \
 && unzip -o godot.zip \
 && rm godot.zip \
 && chmod +x /app/Godot_v4.5.1-stable_linux.x86_64

# ─────────────────────────────
# 2) app files
# ─────────────────────────────
COPY server.pck /app/server.pck
COPY proxy.js /app/proxy.js
COPY package.json /app/package.json
COPY server.sh /app/server.sh

# node deps (just "ws" in your package.json)
RUN npm install --omit=dev

RUN chmod +x /app/server.sh

EXPOSE 10000

CMD ["./server.sh"]