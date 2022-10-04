extends ScriptCommand


var manager


func _init() -> void:
	usage_hint = "!setgame game"
	example_reply = "Successfully changed game to \"Super Mario Odyssey\"!"
	name = "setgame"
	permission_level = Command.Badge.MODERATOR


func get_response(parsedMessage: Dictionary) -> String:
	var params = parsedMessage.command.get("botCommandParams")
	var game = manager.api.get_games_by_name([params])
	if game.data.empty():
		return "Game \"" + params + "\" does not exist!"
	var game_id = game.data[0].id
	var result = manager.api.modify_channel_info(manager.channel_id, game_id)
	var err = int(result.status)
	match err:
		204:
			return "Successfully changed game to \"" + params + "\"!"
		
		400:
			return "${sender} usage of command \"" + name + "\": " + usage_hint
		
		401:
			return "${channel} has not allowed the bot to edit the stream information."
		
		500:
			return "Failed to update stream game!"
		
		_:
			return "Unknown error occured. Error code: " + str(err)
	
	return ""
