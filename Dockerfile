# Dockerfile
FROM node:22-slim

# curl + unzip + CA bundle + fontconfig for Godot
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     curl \
     unzip \
     ca-certificates \
     libfontconfig1 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# app files
COPY server.pck /app/server.pck
COPY server.sh /app/server.sh
COPY proxy.js /app/proxy.js
COPY package.json /app/package.json

# install what package.json says (you had just "ws")
RUN npm install --omit=dev

# make script runnable
RUN chmod +x /app/server.sh

EXPOSE 10000

CMD ["./server.sh"]