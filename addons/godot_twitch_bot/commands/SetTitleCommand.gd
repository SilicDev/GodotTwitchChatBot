extends ScriptCommand


var api


func _init() -> void:
	usage_hint = "!settitle title"
	example_reply = "Successfully changed title to \"Playing Super Mario Odyssey for the first time!\"!"
	name = "settitle"
	permission_level = Command.Badge.MODERATOR


func get_response(parsedMessage: Dictionary) -> String:
	var params = parsedMessage.command.get("botCommandParams")
	var result = api.modify_channel_info(parsedMessage.tags.get("room-id", ""), null, null, params)
	var err = int(result.status)
	match err:
		204:
			return "Successfully changed title to \"" + params + "\"!"
		
		400:
			return "${sender} usage of command \"" + name + "\": " + usage_hint
		
		401:
			return "${channel} has not allowed the bot to edit the stream information."
		
		500:
			return "Failed to update stream title!"
		
		_:
			return "Unknown error occured. Error code: " + str(err)
	
	return ""
