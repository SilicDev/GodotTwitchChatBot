class_name Command
extends Resource


enum Badge {
	NONE,
	SUBSCRIBER,
	VIP,
	MODERATOR,
	BROADCASTER,
}


var name := ""
var regex := ""
var permission_level: int = Badge.NONE
var response := ""

var aliases := PoolStringArray([])
var keywords := PoolStringArray([])

var timeout := 5
var user_timeout := 15

var active := true

var last_sent := Time.get_ticks_msec()
var matcher := RegEx.new()


func get_response(parsedMessage: Dictionary) -> String:
	return response


func should_fire(parsedMessage: Dictionary) -> bool:
	if Time.get_ticks_msec() - last_sent > timeout * 1000:
		if is_broadcaster(parsedMessage) or get_permission(parsedMessage) >= permission_level:
			var cmd = parsedMessage.get("command", {}).get("botCommand", "")
			if cmd == name.to_lower() or cmd in aliases:
				return true
			
			var parameters = parsedMessage.get("parameters", "")
			for keyword in keywords:
				if keyword in parameters:
					return true
			
			if not regex.empty():
				matcher.compile(regex)
				if matcher.search(parameters):
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
	var badges = parsedMessage.get("tags", {}).get("badges", "")
	return badges and "broadcaster" in badges


func get_save_dict() -> Dictionary:
	return {
			"name" : name,
			"regex" :regex,
			"permission" : permission_level,
			"keywords" : keywords,
			"aliases" : aliases,
			"response" : response,
			"timeout" : timeout,
			"user_timeout" : user_timeout,
			"type" : "default",
	}
