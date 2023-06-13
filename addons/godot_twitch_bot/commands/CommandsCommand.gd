extends ScriptCommand


var manager
var no_formating := true


func _init():
	usage_hint = "!commands"
	example_reply = "Here is a list of all of our commands:"
	name = "commands"
	permission_level = Command.Badge.NONE
	timeout = 10


func get_response(parsedMessage: Dictionary) -> String:
	var params := PackedStringArray()
	if parsedMessage.command.has("botCommandParams"):
		params = parsedMessage.command.botCommandParams.split(" ")
	
	var sender = parsedMessage.get("tags", {}).get("display-name", "")
	
	var cmd_response = "Here is a list of all of our commands: "
	
	var cmds = " --- "
	var activeCmds = PackedStringArray()
	for cmd in manager.commands.values():
		if cmd.active and cmd.permission_level <= get_permission(parsedMessage):
			activeCmds.append(cmd.name)
	cmds = cmds.join(activeCmds)
	print(activeCmds)
	cmd_response += cmds
	return cmd_response
