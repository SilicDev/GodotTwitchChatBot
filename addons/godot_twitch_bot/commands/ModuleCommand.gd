extends Command

var toggle : bool = true

var module := ""

var manager

func _init() -> void:
	name = "module"
	permission_level = Command.Badge.MODERATOR


func should_fire(parsedMessage: Dictionary) -> bool:
	var res = .should_fire(parsedMessage)
	if res:
		var params := PoolStringArray()
		if parsedMessage.command.has("botCommandParams"):
			params = parsedMessage.command.botCommandParams.split(" ")
		if params.empty() or params.size() < 2:
			return false
		match params[0].to_lower():
			"on", "true", "yes":
				toggle = true
			"off", "false", "no":
				toggle = false
		module = params[1].to_lower()
		return true
	return false

func get_response() -> String:
	if toggle:
		var res = manager.toggle_module(module, true)
		if res:
			return "Successfully enabled module \"" + module + "\"!"
		else:
			return "Module with the name \"" + module + "\" doesn't exist!"
	else:
		var res = manager.toggle_module(module, false)
		if res:
			return "Successfully disabled module \"" + module + "\"!"
		else:
			return "Module with the name \"" + module + "\" doesn't exist!"
	return response
