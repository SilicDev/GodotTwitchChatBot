extends Connection


var socket : WebSocketClient

var host : String = "irc-ws.chat.twitch.tv"
var port : int = 443

func _init() -> void:
	socket = WebSocketClient.new()
	socket.verify_ssl = true


func connect_to_host() -> int:
	status = Status.CONNECTING
	var err = socket.connect_to_url("wss://" + host + ":" + str(port))
	if not err:
		pass
	else:
		status = Status.ERROR
	return err


func update() -> void:
	if socket.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED and status == Status.CONNECTING:
		status = Status.CONNECTED
		socket.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	elif socket.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:
		status == Status.DISCONNECTED
	if socket.get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:
		socket.poll()


func disconnect_from_host() -> void:
	socket.get_peer(1).close(1000, "Client disconnected")
	status = Status.DISCONNECTED
	pass


func send(message: String) -> void:
	socket.get_peer(1).put_packet((message + "\r\n").to_utf8())
	pass


func receive() -> String:
	if socket.get_peer(1).get_available_packet_count() != 0:
		return socket.get_peer(1).get_packet().get_string_from_utf8()
	return ""

func has_message() -> bool:
	socket.poll()
	return socket.get_peer(1).get_available_packet_count() != 0
