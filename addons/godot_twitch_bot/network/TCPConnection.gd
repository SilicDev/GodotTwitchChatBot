extends Connection


var socket : StreamPeerTCP

func _init() -> void:
	socket = StreamPeerTCP.new()


func connect_to_host(host: String, port: int) -> int:
	status = Status.CONNECTING
	var err = socket.connect_to_host(host, port)
	if not err:
		status = Status.CONNECTED
	else:
		status = Status.ERROR
	return err


func disconnect_from_host() -> void:
	socket.disconnect_from_host()
	status = Status.DISCONNECTED


func send(message: String) -> void:
	print(message)
	socket.put_data((message + "\r\n").to_utf8())
	pass


func receive() -> String:
	if socket.get_available_bytes() != 0:
		return PoolByteArray(socket.get_data(socket.get_available_bytes())[1]).get_string_from_utf8()
	return ""


func has_message() -> bool:
	return socket.get_available_bytes() != 0


func is_connected_to_host() -> bool:
	return socket.is_connected_to_host()
