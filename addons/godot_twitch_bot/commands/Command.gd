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

var timeout := 5
var user_timeout := 15

var active := true
var matcher := RegEx.new()


func get_response() -> String:
	return response


func should_fire(parsedMessage: Dictionary) -> bool:
	if is_broadcaster(parsedMessage) or get_permission(parsedMessage) >= permission_level:
		var cmd = parsedMessage.get("command", {}).get("botCommand", "")
		if cmd == name or cmd in aliases:
			return true
		if not regex.empty():
			matcher.compile(regex)
			if matcher.search(parsedMessage.get("parameters", "")):
				return true
	return false


func get_permission(parsedMessage: Dictionary) -> int:
	if is_broadcaster(parsedMessage):
		return Badge.BROADCASTER
	var tags = parsedMessage.get("tags", {})
	if tags.get("mod", 0):
		return Badge.MODERATOR
	if tags.has("vip"):
		return Badge.VIP
	if tags.get("sub", 0):
		return Badge.SUBSCRIBER
	return Badge.NONE


func is_broadcaster(parsedMessage: Dictionary) -> bool:
	return "broadcaster" in parsedMessage.get("tags", {}).get("badges")
