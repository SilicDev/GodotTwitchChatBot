extends Command
enum Mode {
	NONE,
	EDIT,
	ADD,
	REMOVE,
}

var mode : int = Mode.NONE

var cmd := ""
var cmd_response := ""

var manager

func _init() -> void:
	name = "command"
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
			"edit":
				mode = Mode.EDIT
			"add":
				mode = Mode.ADD
			"remove":
				mode = Mode.REMOVE
		cmd = params[1].to_lower()
		if cmd in manager.base_commands.keys():
			return false
		cmd_response = ""
		for i in range(2, params.size()):
			cmd_response += params[i] + " "
		cmd_response = cmd_response.substr(0, cmd_response.length() - 1)
		return true
	return false

func get_response() -> String:
	match mode:
		Mode.ADD:
			var res = manager.add_command(cmd, cmd_response)
			if res:
				return "Successfully added command \"" + cmd + "\"!"
			else:
				return "Command with name \"" + cmd + "\" already exists!"
		Mode.EDIT:
			var res = manager.edit_command(cmd, cmd_response)
			if res:
				return "Successfully edited command \"" + cmd + "\": \"" + cmd_response + "\"!"
			else:
				return "Command with name \"" + cmd + "\" doesn't exist!"
		Mode.REMOVE:
			var res = manager.remove_command(cmd)
			if res:
				return "Successfully removed command \"" + cmd + "\"!"
			else:
				return "Command with name \"" + cmd + "\" doesn't exist!"
	return response
