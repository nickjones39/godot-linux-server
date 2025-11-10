# res://ws_host.gd
extends Node

const DEFAULT_PORT := 8080
var ws_peer: WebSocketMultiplayerPeer

func _ready() -> void:
	# don’t try to listen in browser
	if OS.has_feature("web"):
		print("[WSHost] Web export – skipping WS server.")
		return

	var port := DEFAULT_PORT
	var env_port := OS.get_environment("PORT")
	if env_port != "":
		port = int(env_port)

	ws_peer = WebSocketMultiplayerPeer.new()
	var err := ws_peer.create_server(port)
	if err != OK:
		push_error("[WSHost] WS create_server failed: %s on port %d" % [str(err), port])
		return

	multiplayer.multiplayer_peer = ws_peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("[WSHost] WebSocket server listening on port %d" % port)
	set_process(true)

func _process(_delta: float) -> void:
	if ws_peer and ws_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		ws_peer.poll()

func _on_peer_connected(id: int) -> void:
	print("[WSHost] peer connected: ", id)

func _on_peer_disconnected(id: int) -> void:
	print("[WSHost] peer disconnected: ", id)
