// proxy.js
// tiny HTTP + WS forwarder -> Godot WS on 10000

const http = require("http");
const { WebSocketServer, WebSocket } = require("ws");

const PORT = process.env.PORT || 10000;   // what Render exposes
const GODOT_HOST = "127.0.0.1";
const GODOT_PORT = 10000;

// 1) plain HTTP so Render health checks succeed
const server = http.createServer((req, res) => {
  if (req.url === "/healthz") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("ok");
    return;
  }
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Godot WS proxy");
});

// 2) WS proxy: every incoming WS → make a WS to Godot, then pipe both ways
const wss = new WebSocketServer({ server });

wss.on("connection", (client, req) => {
  // try to connect to Godot
  const backendUrl = `ws://${GODOT_HOST}:${GODOT_PORT}`;
  const backend = new WebSocket(backendUrl);

  console.log(`[proxy] client connected, dialing ${backendUrl} ...`);

  // client -> backend
  client.on("message", (data) => {
    if (backend.readyState === WebSocket.OPEN) {
      backend.send(data);
    }
  });

  // backend -> client
  backend.on("message", (data) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data);
    }
  });

  // if Godot isn't up yet, close client cleanly
  backend.on("error", (err) => {
    console.warn("[proxy] backend WS error:", err.message);
    if (client.readyState === WebSocket.OPEN) {
      client.close();
    }
  });

  const closeBoth = () => {
    if (client.readyState === WebSocket.OPEN) {
      client.close();
    }
    if (backend.readyState === WebSocket.OPEN) {
      backend.close();
    }
  };

  client.on("close", closeBoth);
  backend.on("close", closeBoth);
});

server.listen(PORT, () => {
  console.log(
    `[proxy] listening on ${PORT}, forwarding WS -> ws://${GODOT_HOST}:${GODOT_PORT}`
  );
});