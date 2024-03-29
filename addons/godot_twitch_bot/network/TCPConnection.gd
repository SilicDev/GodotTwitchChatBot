extends Connection


var socket : StreamPeerTCP

var host : String = "irc.chat.twitch.tv"
var port : int = 6667


func _init():
	socket = StreamPeerTCP.new()


func connect_to_host() -> Error:
	if not is_connected_to_host():
		status = Status.CONNECTING
		var err = socket.connect_to_host(host, port)
		if err:
			status = Status.ERROR
		return err
	else:
		push_error("Already connected to a host! Disconnect before attempting to reconnect!")
		return ERR_CONNECTION_ERROR


func update() -> void:
	if socket.get_status() == socket.STATUS_CONNECTED:
		status = Status.CONNECTED
	elif status == Status.CONNECTED:
		status == Status.DISCONNECTED


func disconnect_from_host() -> void:
	if is_connected_to_host():
		socket.disconnect_from_host()
		status == Status.DISCONNECTED
	else:
		push_warning("Must be connected to a host to disconnect!")


func send(message: String) -> void:
	if is_connected_to_host():
		if OS.is_debug_build():
			if message.begins_with("PASS"):
				print("< PASS oauth:" + "*".repeat(message.length() - 11))
			else:
				print("< " + message)
		socket.put_data((message + "\r\n").to_utf8_buffer())
	
	else:
		push_warning("Must be connected to send a message!")


func receive() -> String:
	if socket.get_status() == socket.STATUS_CONNECTED:
		if socket.get_available_bytes() > 0:
			var data := socket.get_data(socket.get_available_bytes())
			if data[0]:
				status = Status.ERROR
				push_error(str(data[0]) + ": Error occured while receiving message")
			return PackedByteArray(data[1]).get_string_from_utf8()
	
	else:
		push_error("Must be connected to receive messages!")
	return ""


func has_message() -> bool:
	return socket.get_status() == socket.STATUS_CONNECTED and socket.get_available_bytes() > 0


func is_connected_to_host() -> bool:
	return status == Status.CONNECTED
