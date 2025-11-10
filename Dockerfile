# Dockerfile
FROM node:22-slim

# 1) tools + the lib Godot wants
#    - curl/unzip: to fetch the Godot binary at runtime (your server.sh does that)
#    - libfontconfig1: fixes "libfontconfig.so.1: cannot open shared object file"
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     curl \
     unzip \
     libfontconfig1 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2) app files
COPY server.pck /app/server.pck
COPY server.sh /app/server.sh
COPY proxy.js /app/proxy.js
COPY package.json /app/package.json

# 3) install the node deps declared in package.json (you had just "ws")
RUN npm install --omit=dev

# 4) make sure our launcher is executable
RUN chmod +x /app/server.sh

# 5) Godot listens on 10000; Render maps $PORT -> container
EXPOSE 10000

# 6) start it
CMD ["./server.sh"]