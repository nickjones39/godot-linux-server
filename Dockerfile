# Dockerfile
FROM node:22-slim

# we need curl + unzip to fetch Godot, CA certs so curl works,
# and libfontconfig1 so the Godot binary doesn’t complain
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
     curl \
     unzip \
     ca-certificates \
     libfontconfig1 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# your Godot pack + scripts
COPY server.pck /app/server.pck
COPY server.sh /app/server.sh
COPY proxy.js /app/proxy.js
COPY package.json /app/package.json

# install node deps (you have "ws" in package.json)
RUN npm install --omit=dev

# make the launcher executable
RUN chmod +x /app/server.sh

# Godot listens on 10000 internally;
# Render will hit the Node proxy on $PORT,
# but exposing 10000 is fine for local/docker runs
EXPOSE 10000

# start everything
CMD ["./server.sh"]