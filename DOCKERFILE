# Dockerfile
FROM node:22-slim

# we need curl + unzip to fetch the Godot binary
RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# copy package files first (better for Docker caching)
COPY package.json package-lock.json /app/

# install deps (ws + http-proxy from your package.json)
RUN npm install --omit=dev

# now copy the rest
COPY server.pck /app/server.pck
COPY server.sh /app/server.sh
COPY proxy.js /app/proxy.js

# make scripts executable
RUN chmod +x /app/server.sh

# Godot will listen on 10000 internally
EXPOSE 10000

# Render will hit the main process -> start Node
# server.sh will be started by proxy.js (see next section)
CMD ["node", "proxy.js"]