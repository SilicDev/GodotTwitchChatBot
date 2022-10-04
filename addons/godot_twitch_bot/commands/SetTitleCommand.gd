extends ScriptCommand


var manager


func _init() -> void:
	usage_hint = "!settitle title"
	example_reply = "Successfully changed title to \"Playing Super Mario Odyssey for the first time!\"!"
	name = "settitle"
	permission_level = Command.Badge.MODERATOR


func get_response(parsedMessage: Dictionary) -> String:
	var params = parsedMessage.command.get("botCommandParams")
	var result = manager.api.modify_channel_info(manager.channel_id, null, null, params)
	var err = result.status
	match err:
		400:
			return "${sender} usage of command \"" + name + "\": " + usage_hint
		
		500:
			return "Failed to update stream title!"
		
		204:
			return "Successfully changed title to \"" + params + "\"!"
		
		_:
			return "Unknown error occured. Error code: " + err
	
	return ""
