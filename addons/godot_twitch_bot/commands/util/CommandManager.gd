extends Reference


var file := File.new()

var channel : String

var commands := {}
var base_commands := {}

var modules := {}

var counters := {}

var formatter = _load("cmd://util/MessageFormater.gd").new()

func _init(cnl: String) -> void:
	formatter.manager = self
	channel = cnl
	load_data()


func test_commands(message: Dictionary) -> String:
	for c in commands.values():
		if c.active and c.should_fire(message):
			return c.name
	return ""


func get_response(cmd: String, message: Dictionary) -> String:
	if cmd in commands.keys():
		var msg : String = commands[cmd].get_response()
		if cmd != "command":
			msg = formatter.format_message(msg, channel, message)
		return msg
	return ""


func load_data() -> void:
	_load_base_commands()
	load_command_list("user://channels/" + channel + "/commands.json")
	load_counters("user://channels/" + channel + "/counters.json")


func save_data() -> void:
	save_command_list()
	save_counters("user://channels/" + channel + "/counters.json")


func load_command_list(path: String):
	var err = file.open(path, File.READ)
	if err:
		save_command_list(path)
		file.open(path, File.READ)
	var result := JSON.parse(file.get_as_text())
	file.close()
	if result.error:
		push_error("Error loading commands: line " + str(result.error_line) + ": " + result.error_string)
		return result.error
	var dict = result.result
	var active = result.result._active_commands
	for cmd in dict:
		if cmd == "_active_commands":
			continue
		var cmd_dict = dict[cmd]
		var res := Command.new()
		res.name = cmd_dict["name"]
		res.regex = cmd_dict["regex"]
		res.permission_level = cmd_dict["permission"]
		res.aliases = cmd_dict["aliases"]
		res.response = cmd_dict["response"]
		commands[cmd] = res
	for cmd in commands:
		if cmd in active:
			commands[cmd].active = active[cmd]
	return OK


func save_command_list(path: String = "") -> int:
	if path.empty():
		path = "user://channels/" + channel + "/commands.json"
	var dir := Directory.new()
	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())
	var err := file.open(path, File.WRITE)
	if err:
		push_error("Failed to save commands! Unable to open destination file (Error #" + str(err) + ")")
		return err
	var dict := {}
	var active = {}
	for cmd in commands:
		active[cmd] = commands[cmd].active
		if not cmd in base_commands:
			dict[commands[cmd].name] = {
				"name" : commands[cmd].name,
				"regex" :commands[cmd].regex,
				"permission" : commands[cmd].permission_level,
				"aliases" : commands[cmd].aliases,
				"response" : commands[cmd].response,
			}
	dict["_active_commands"] = active
	file.store_string(JSON.print(dict))
	file.close()
	return OK


func save_counters(path: String) -> int:
	var dir := Directory.new()
	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())
	var err := file.open(path, File.WRITE)
	if err:
		push_error("Failed to save counters! Unable to open destination file (Error #" + str(err) + ")")
		return err
	file.store_string(JSON.print(counters))
	file.close()
	return OK


func load_counters(path: String) -> int:
	var err = file.open(path, File.READ)
	if err:
		save_counters(path)
		file.open(path, File.READ)
	var result := JSON.parse(file.get_as_text())
	file.close()
	if result.error:
		push_error("Error loading counters: line " + str(result.error_line) + ": " + result.error_string)
	counters = result.result
	return OK


func toggle_module(module: String, on_off: bool) -> bool:
	if module in modules.keys():
		for cmd in modules[module].commands:
			toggle_command(cmd, on_off)
		return true
	push_warning("Module with this name doesn't exists!")
	return false


func toggle_command(cmd: String, on_off: bool) -> bool:
	cmd = cmd.to_lower()
	if cmd in commands.keys():
		commands[cmd].active = on_off
		return true
	push_warning("Command with this name doesn't exists!")
	return false


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


func _load_base_commands() -> void:
	var commandCmd = _load("cmd://CommandCommand.gd").new()
	commandCmd.manager = self
	base_commands["command"] = commandCmd
	
	var moduleCmd = _load("cmd://ModuleCommand.gd").new()
	moduleCmd.manager = self
	base_commands["module"] = moduleCmd
	
	for c in base_commands:
		commands[c] = base_commands[c]


func _load(path: String) -> Resource:
	path = path.replace("cmd://", "res://addons/godot_twitch_bot/commands/")
	return load(path)


class Module:
	var commands := PoolStringArray([])
	var active := true
