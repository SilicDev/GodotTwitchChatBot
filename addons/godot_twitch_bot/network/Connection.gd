class_name Connection
extends Reference

enum Status {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	ERROR,
}

var status = Status.DISCONNECTED

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

func connect_to_host(host: String, port: int) -> int:
	return OK


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
