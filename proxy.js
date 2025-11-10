// proxy.js
// HTTP + WebSocket forwarder to local Godot WS (10001)
// also accepts POST /register from the Godot overworld heartbeat

"use strict";

const http = require("http");
const { WebSocketServer, WebSocket } = require("ws");

const PORT = Number(process.env.PORT || 10000);               // exposed by Fly
const GODOT_HOST = process.env.TARGET_HOST || "127.0.0.1";
const GODOT_PORT = Number(process.env.TARGET_PORT || 10001);  // Godot WS port

// in-memory record of the last /register we saw
let lastRegister = {
	at: null,
	body: null,
};

// -----------------------------------------------------------------------------
// HTTP SERVER
// -----------------------------------------------------------------------------
const server = http.createServer((req, res) => {
	// Fly health
	if (req.method === "GET" && req.url === "/healthz") {
		res.writeHead(200, { "Content-Type": "text/plain" });
		res.end("ok");
		return;
	}

	// simple status
	if (req.method === "GET" && (req.url === "/" || req.url === "/status")) {
		res.writeHead(200, { "Content-Type": "application/json" });
		res.end(
			JSON.stringify({
				status: "ok",
				ws_target: `ws://${GODOT_HOST}:${GODOT_PORT}`,
				last_register: lastRegister,
			})
		);
		return;
	}

	// Godot → heartbeat
	if (req.method === "POST" && req.url === "/register") {
		const chunks = [];
		req.on("data", (c) => chunks.push(c));
		req.on("end", () => {
			const raw = Buffer.concat(chunks).toString("utf8");
			let parsed = null;
			try {
				parsed = raw ? JSON.parse(raw) : null;
			} catch (e) {
				console.warn("[proxy] /register: bad JSON:", e.message);
			}
			lastRegister = {
				at: new Date().toISOString(),
				body: parsed || raw,
			};
			console.log("[proxy] /register from game:", lastRegister);
			res.writeHead(200, { "Content-Type": "application/json" });
			res.end(JSON.stringify({ ok: true }));
		});
		return;
	}

	// anything else
	res.writeHead(404, { "Content-Type": "text/plain" });
	res.end("not found");
});

// -----------------------------------------------------------------------------
// WEBSOCKET BRIDGE
// -----------------------------------------------------------------------------
const wss = new WebSocketServer({ server });

wss.on("connection", (client, req) => {
	const backendUrl = `ws://${GODOT_HOST}:${GODOT_PORT}`;
	const backend = new WebSocket(backendUrl);

	console.log(
		`[proxy] client ${req.socket.remoteAddress} connected, dialing ${backendUrl} ...`
	);

	// relay client → godot (only when backend ready)
	client.on("message", (data) => {
		if (backend.readyState === WebSocket.OPEN) {
			backend.send(data);
		}
	});

	// relay godot → client (only when client ready)
	backend.on("message", (data) => {
		if (client.readyState === WebSocket.OPEN) {
			client.send(data);
		}
	});

	// unified shutdown
	const closeBoth = (why = "unknown", code = 1000) => {
		if (client.readyState === WebSocket.OPEN) {
			client.close(code, why);
		}
		if (backend.readyState === WebSocket.OPEN) {
			backend.close(code, why);
		}
		console.log(`[proxy] closed WS pair (${why})`);
	};

	client.on("close", (code, reason) => {
		console.log(
			`[proxy] client closed code=${code} reason=${reason?.toString() || ""}`
		);
		closeBoth("client closed", code || 1000);
	});

	backend.on("close", (code, reason) => {
		console.log(
			`[proxy] backend closed code=${code} reason=${reason?.toString() || ""}`
		);
		closeBoth("backend closed", code || 1000);
	});

	backend.on("error", (err) => {
		console.warn("[proxy] backend WS error:", err.message);
		closeBoth("backend error", 1011);
	});

	client.on("error", (err) => {
		console.warn("[proxy] client WS error:", err.message);
		closeBoth("client error", 1011);
	});
});

// -----------------------------------------------------------------------------
// START LISTENING
// -----------------------------------------------------------------------------
server.listen(PORT, "0.0.0.0", () => {
	console.log(
		`[proxy] listening on 0.0.0.0:${PORT}, forwarding WS -> ws://${GODOT_HOST}:${GODOT_PORT}`
	);
});