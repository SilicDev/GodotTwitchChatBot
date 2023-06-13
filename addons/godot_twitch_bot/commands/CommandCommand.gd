extends ScriptCommand


var manager
var no_formating := true


func _init():
	usage_hint = "!command add|edit|remove <command> msg"
	example_reply = "Successfully added command \"test\"!"
	name = "command"
	permission_level = Command.Badge.MODERATOR
	timeout = 10


func get_response(parsedMessage: Dictionary) -> String:
	var params := PackedStringArray()
	if parsedMessage.command.has("botCommandParams"):
		params = parsedMessage.command.botCommandParams.split(" ")
	
	var sender = parsedMessage.get("tags", {}).get("display-name", "")
	
	if params.is_empty() or params.size() < 2:
		return sender + " usage of command \"" + name + "\": " + usage_hint
	
	var cmd = params[1].to_lower()
	if cmd.begins_with("!"):
		cmd = cmd.substr(1)
	if cmd in manager.base_commands.keys():
		return sender + " usage of command \"" + name + "\": " + usage_hint
	
	var cmd_response = ""
	for i in range(2, params.size()):
		cmd_response += params[i] + " "
	cmd_response = cmd_response.substr(0, cmd_response.length() - 1)
	
	match params[0].to_lower():
		"edit":
			var res = manager.edit_command(cmd, cmd_response)
			if res:
				return "Successfully edited command \"" + cmd + "\": \"" + cmd_response + "\"!"
			else:
				return "Command with name \"" + cmd + "\" doesn't exist!"
		
		"add":
			var res = manager.add_command(cmd, cmd_response)
			if res:
				return "Successfully added command \"" + cmd + "\"!"
			else:
				return "Command with name \"" + cmd + "\" already exists!"
		
		"remove":
			var res = manager.remove_command(cmd)
			if res:
				return "Successfully removed command \"" + cmd + "\"!"
			else:
				return "Command with name \"" + cmd + "\" doesn't exist!"
	
	return ""
