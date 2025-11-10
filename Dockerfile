# Dockerfile
FROM node:22-slim

# we need curl + unzip to fetch Godot, and libfontconfig1 for the Godot binary
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     curl \
     unzip \
     libfontconfig1 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# app files
COPY server.pck /app/server.pck
COPY server.sh /app/server.sh
COPY proxy.js /app/proxy.js
COPY package.json /app/package.json

# install only what package.json says (you said it's just "ws")
RUN npm install --omit=dev

# make sure our script can run
RUN chmod +x /app/server.sh

# Godot will listen on 10000 (and Render will map $PORT → container)
EXPOSE 10000

# start the Godot launcher script (which also starts the WS proxy, if you do that there)
CMD ["./server.sh"]