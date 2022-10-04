extends ScriptCommand


var manager


func _init() -> void:
	usage_hint = "!setgame game"
	example_reply = "Successfully changed game to \"Super Mario Odyssey\"!"
	name = "setgame"
	permission_level = Command.Badge.MODERATOR


func get_response(parsedMessage: Dictionary) -> String:
	var params = parsedMessage.command.get("botCommandParams")
	var game_id = manager.api.get_game_by_name([params])
	var result = manager.api.modify_channel_info(manager.channel_id, game_id)
	var err = result.status
	match err:
		400:
			return "${sender} usage of command \"" + name + "\": " + usage_hint
		
		500:
			return "Failed to update stream game!"
		
		204:
			return "Successfully changed game to \"" + params + "\"!"
		
		_:
			return "Unknown error occured. Error code: " + err
	
	return ""
