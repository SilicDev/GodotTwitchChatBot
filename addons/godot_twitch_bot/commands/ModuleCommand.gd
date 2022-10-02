extends ScriptCommand

func _init() -> void:
	usage_hint = "!module on|off <module>"
	example_reply = "Successfully enabled module \"quote\"!"
	name = "module"
	permission_level = Command.Badge.MODERATOR


func get_response(parsedMessage: Dictionary) -> String:
	var params := PoolStringArray()
	if parsedMessage.command.has("botCommandParams"):
		params = parsedMessage.command.botCommandParams.split(" ")
	if params.empty() or params.size() < 2:
		return "${sender} usage of command \"" + name + "\": " + usage_hint
	var toggle = false
	match params[0].to_lower():
		"on", "true", "yes":
			toggle = true
		"off", "false", "no":
			toggle = false
	var module = params[1].to_lower()
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
	return ""
