extends Reference


var file := File.new()

var commands := {}

var base_commands := {}

var modules := {}
var counters := {}

var channel : String


func _init(cnl: String) -> void:
	channel = cnl
	add_command("test", "Hello ${touser}!")
	var commandCmd = CommandCommand.new()
	commandCmd.manager = self
	base_commands["command"] = commandCmd
	for c in base_commands:
		commands[c] = base_commands[c]


func test_commands(message: Dictionary) -> String:
	for c in commands.values():
		if c.active and c.should_fire(message):
			return c.name
	return ""


func get_response(cmd: String, message: Dictionary) -> String:
	if cmd in commands.keys():
		var msg : String = commands[cmd].get_response()
		var params := PoolStringArray()
		if message.command.has("botCommandParams"):
			params = message.command.botCommandParams.split(" ")
		msg = msg.replace("${sender}", message.tags["display-name"])
		msg = msg.replace("${touser}", params[0] if not params.empty() else message.tags["display-name"])
		msg = msg.replace("${channel}", channel)
		return msg
	return ""


func load_command(path: String):
	file.open(path, File.READ)
	var result := JSON.parse(file.get_as_text())
	file.close()
	if result.error:
		push_error("Error loading command: line " + str(result.error_line) + ": " + result.error_string)
		return result.error
	var res := Command.new()
	res.name = result.result["name"]
	res.regex = result.result["regex"]
	res.permission_level = result.result["permission"]
	res.aliases = result.result["aliases"]
	res.response = result.result["response"]
	return res


func save_command(path: String, cmd: Command) -> int:
	var file := File.new()
	var err := file.open(path, File.WRITE)
	if err:
		push_error("Failed to save command! Unable to open destination file (Error #" + str(err) + ")")
		return err
	var dict = {
		"name" : cmd.name,
		"regex" : cmd.regex,
		"permission" : cmd.permission_level,
		"aliases" : cmd.aliases,
		"response" : cmd.response,
	}
	file.store_string(JSON.print(dict))
	file.close()
	return OK


func toggle_module(module: String, on_off: bool) -> void:
	if module in modules.keys():
		for cmd in modules[module].commands:
			toggle_command(cmd, on_off)
	push_warning("Module with this name doesn't exists!")
	pass


func toggle_command(cmd: String, on_off: bool) -> void:
	cmd = cmd.to_lower()
	if cmd in commands.keys():
		commands[cmd].active = on_off
	push_warning("Command with this name doesn't exists!")
	pass


func add_command(name: String, response: String) -> bool:
	name = name.to_lower()
	if not name in commands.keys():
		var cmd = Command.new()
		cmd.name = name
		cmd.response = response
		commands[name] = cmd
		return true
	push_warning("Command with this name already exists!")
	return false


func remove_command(name: String) -> bool:
	name = name.to_lower()
	if name in commands.keys():
		if name in base_commands:
			commands[name].active = false
		else:
			commands.erase(name)
		return true
	push_warning("Command with this name doesn't exists!")
	return false


func edit_command(name: String, response: String) -> bool:
	name = name.to_lower()
	if name in commands.keys():
		if name in base_commands:
			return false
		commands[name].response = response
		return true
	push_warning("Command with this name doesn't exists!")
	return false


class Module:
	var commands := PoolStringArray([])
	var active := true


class CommandCommand extends Command:
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
			if params.empty():
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
