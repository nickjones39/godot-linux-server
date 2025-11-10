FROM node:22-slim

RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# copy app files
COPY server.pck /app/server.pck
COPY server.sh /app/server.sh
COPY proxy.js /app/proxy.js
COPY package.json /app/package.json

# install only ws (no http-proxy)
RUN npm install --omit=dev

RUN chmod +x /app/server.sh

EXPOSE 10000
CMD ["./server.sh"]