extends Node
class_name CardfrontNetworkManager

signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal message_received(data: Dictionary)
signal connection_failed(reason: String)
signal host_started(port: int)
signal join_succeeded()

const Protocol = preload("res://scripts/cardfront/network/CardfrontNetworkProtocol.gd")
const DEFAULT_PORT: int = 25678
const DEFAULT_IP: String = "127.0.0.1"

var peer: ENetMultiplayerPeer = null
var role: int = 0
var is_active: bool = false
var remote_peer_id: int = 0


func host_game(port: int = DEFAULT_PORT) -> bool:
	if peer != null:
		close()
	peer = ENetMultiplayerPeer.new()
	var err: int = peer.create_server(port, 1)
	if err != OK:
		connection_failed.emit("Failed to create server on port %d (error %d)" % [port, err])
		peer = null
		return false
	role = Protocol.ROLE_HOST
	is_active = true
	multiplayer.multiplayer_peer = peer
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	host_started.emit(port)
	return true


func join_game(ip: String = DEFAULT_IP, port: int = DEFAULT_PORT) -> bool:
	if peer != null:
		close()
	peer = ENetMultiplayerPeer.new()
	var err: int = peer.create_client(ip, port)
	if err != OK:
		connection_failed.emit("Failed to connect to %s:%d (error %d)" % [ip, port, err])
		peer = null
		return false
	role = Protocol.ROLE_GUEST
	is_active = true
	multiplayer.multiplayer_peer = peer
	if not multiplayer.connected_to_server.is_connected(_on_join_succeeded):
		multiplayer.connected_to_server.connect(_on_join_succeeded)
	if not multiplayer.connection_failed.is_connected(_on_join_failed):
		multiplayer.connection_failed.connect(_on_join_failed)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return true


func close() -> void:
	if multiplayer != null:
		if multiplayer.multiplayer_peer == peer and peer != null:
			multiplayer.multiplayer_peer = null
	if peer != null:
		peer.close()
		peer = null
	is_active = false
	role = 0
	remote_peer_id = 0


func send(data: Dictionary) -> void:
	if not is_active or remote_peer_id == 0:
		return
	rpc_id(remote_peer_id, "_receive_message", data)


func is_connected_to_peer() -> bool:
	return is_active and remote_peer_id != 0


func is_host() -> bool:
	return role == Protocol.ROLE_HOST


@rpc("any_peer", "reliable")
func _receive_message(data: Dictionary) -> void:
	message_received.emit(data)


func _on_peer_connected(peer_id: int) -> void:
	remote_peer_id = int(peer_id)
	peer_connected.emit(int(peer_id))


func _on_peer_disconnected(peer_id: int) -> void:
	if int(peer_id) == remote_peer_id:
		remote_peer_id = 0
	peer_disconnected.emit(int(peer_id))


func _on_join_succeeded() -> void:
	remote_peer_id = 1
	join_succeeded.emit()


func _on_join_failed() -> void:
	connection_failed.emit("Connection to server failed")
	close()
