// proxy.js
// tiny HTTP + WS forwarder -> Godot WS on 10001

const http = require("http");
const { WebSocketServer, WebSocket } = require("ws");

const PORT = process.env.PORT || 10000;      // public (Render) port
const GODOT_HOST = "127.0.0.1";
const GODOT_PORT = process.env.TARGET_PORT || 10001;  // internal Godot port

const server = http.createServer((req, res) => {
  if (req.url === "/healthz") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("ok");
    return;
  }
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Godot WS proxy");
});

const wss = new WebSocketServer({ server });

wss.on("connection", (client) => {
  const backendUrl = `ws://${GODOT_HOST}:${GODOT_PORT}`;
  const backend = new WebSocket(backendUrl);
  console.log(`[proxy] client connected, dialing ${backendUrl} ...`);

  client.on("message", (data) => {
    if (backend.readyState === WebSocket.OPEN) backend.send(data);
  });

  backend.on("message", (data) => {
    if (client.readyState === WebSocket.OPEN) client.send(data);
  });

  const closeBoth = () => {
    if (client.readyState === WebSocket.OPEN) client.close();
    if (backend.readyState === WebSocket.OPEN) backend.close();
  };

  client.on("close", closeBoth);
  backend.on("close", closeBoth);
  backend.on("error", (err) => {
    console.warn("[proxy] backend WS error:", err.message);
    closeBoth();
  });
});

server.listen(PORT, () => {
  console.log(
    `[proxy] listening on 0.0.0.0:${PORT}, forwarding WS -> ws://${GODOT_HOST}:${GODOT_PORT}`
  );
});