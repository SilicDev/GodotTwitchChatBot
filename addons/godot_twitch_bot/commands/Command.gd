tool
class_name Command
extends Resource


export(String) var name := ""
export(String, MULTILINE) var regex := ""
enum Badge {
	NONE,
	SUBSCRIBER,
	VIP,
	MODERATOR,
	BROADCASTER,
}
export(Badge) var permission_level := Badge.NONE
export(PoolStringArray) var aliases := PoolStringArray([])
export(String, MULTILINE) var response := ""
var matcher = RegEx.new()


func get_response() -> String:
	return response


func should_fire(parsedMessage: Dictionary) -> bool:
	if permission_level == Badge.NONE or (parsedMessage.has("tags") and parsedMessage.tags["user-type"] and has_permission(parsedMessage.tags["user-type"]) >= permission_level):
		if parsedMessage.command.has("botCommand") and parsedMessage.command.botCommand == name:
			return true
		if not regex.empty():
			matcher.compile(regex)
			if matcher.search(parsedMessage.parameters):
				return true
	return false


func has_permission(user_type: String) -> int:
	match user_type:
		"broadcaster":
			return Badge.BROADCASTER
		"mod":
			return Badge.MODERATOR
		"vip":
			return Badge.VIP
		"subscriber":
			return Badge.SUBSCRIBER
		_:
			return Badge.NONE
