class_name Connection
extends RefCounted


enum Status {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	ERROR,
}


var status = Status.DISCONNECTED


func connect_to_host() -> Error:
	return OK


func update() -> void:
	pass


func disconnect_from_host() -> void:
	pass


func send(message: String) -> void:
	pass


func receive() -> String:
	return ""


func has_message() -> bool:
	return false


func is_connected_to_host() -> bool:
	return false
