extends Connection


var socket : WebSocketPeer

var host : String = "irc-ws.chat.twitch.tv"
var port : int = 443


func _init():
	socket = WebSocketPeer.new()


func connect_to_host() -> Error:
	status = Status.CONNECTING
	var err = socket.connect_to_url("wss://" + host + ":" + str(port))
	if not err:
		pass
	else:
		status = Status.ERROR
	return err


func update() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN and status == Status.CONNECTING:
		status = Status.CONNECTED
	elif socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		status = Status.DISCONNECTED
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		socket.poll()


func disconnect_from_host() -> void:
	socket.close(1000, "Client disconnected")
	status = Status.DISCONNECTED


func send(message: String) -> void:
	if OS.is_debug_build():
		if message.begins_with("PASS"):
			print("< PASS oauth:" + "*".repeat(message.length() - 11))
		else:
			print("< " + message)
	
	var err := socket.send_text(message + "\r\n")
	if err:
		push_error("Error occured while sending message: " + str(err))
		status = Status.ERROR


func receive() -> String:
	if socket.get_available_packet_count() != 0:
		return socket.get_packet().get_string_from_utf8()
	return ""


func has_message() -> bool:
	return socket.get_available_packet_count() != 0


func is_connected_to_host() -> bool:
	return socket.get_ready_state() == WebSocketPeer.STATE_OPEN
