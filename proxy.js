// proxy.js
// tiny HTTP + WS forwarder -> Godot WS on 10000

const http = require("http");
const { WebSocketServer, WebSocket } = require("ws");

const PORT = process.env.PORT || 10000;
const GODOT_HOST = "127.0.0.1";
const GODOT_PORT = 10000;

// 1) HTTP for Render
const server = http.createServer((req, res) => {
  if (req.url === "/healthz") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("ok");
    return;
  }
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Godot WS proxy");
});

// 2) WS proxy
const wss = new WebSocketServer({ server });

wss.on("connection", (client, req) => {
  const backend = new WebSocket(`ws://${GODOT_HOST}:${GODOT_PORT}`);

  // pipe client -> backend
  client.on("message", (data) => {
    if (backend.readyState === WebSocket.OPEN) {
      backend.send(data);
    }
  });

  // pipe backend -> client
  backend.on("message", (data) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data);
    }
  });

  // close both ends together
  const closeBoth = () => {
    try { client.close(); } catch {}
    try { backend.close(); } catch {}
  };
  client.on("close", closeBoth);
  backend.on("close", closeBoth);
  backend.on("error", closeBoth);
});

server.listen(PORT, () => {
  console.log(`[proxy] listening on ${PORT}, forwarding WS -> ws://127.0.0.1:${GODOT_PORT}`);
});