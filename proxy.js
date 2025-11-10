// proxy.js
const http = require("http");
const httpProxy = require("http-proxy");
const { spawn } = require("child_process");

const PORT = process.env.PORT || 10000;   // Render gives this
const GODOT_WS_PORT = 10000;             // where Godot will listen

// 1) start Godot in background
console.log("[proxy] starting Godot via server.sh …");
const godot = spawn("/app/server.sh", [], {
  stdio: "inherit"
});

// if Godot dies, log it (Render will restart container anyway)
godot.on("close", (code) => {
  console.log("[proxy] Godot exited with code", code);
});

// 2) HTTP server (health + placeholder)
const server = http.createServer((req, res) => {
  if (req.url === "/healthz") {
    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end("ok");
    return;
  }
    // you can serve a simple text for GET /
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Godot WS proxy");
});

// 3) WS → Godot
const wsProxy = httpProxy.createProxyServer({
  target: {
    host: "127.0.0.1",
    port: GODOT_WS_PORT
  },
  ws: true
});

server.on("upgrade", (req, socket, head) => {
  wsProxy.ws(req, socket, head);
});

server.listen(PORT, () => {
  console.log(`[proxy] listening on 0.0.0.0:${PORT}, proxying WS -> 127.0.0.1:${GODOT_WS_PORT}`);
});