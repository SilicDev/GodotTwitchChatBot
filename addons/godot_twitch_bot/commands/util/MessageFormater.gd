extends Reference


func format_message(msg: String, channel: String, message: Dictionary) -> String:
	var params := PoolStringArray()
	if message.command.has("botCommandParams"):
		params = message.command.botCommandParams.split(" ")
	msg = msg.replace("${sender}", message.tags["display-name"])
	msg = msg.replace("${touser}", params[0] if not params.empty() else message.tags["display-name"])
	msg = msg.replace("${channel}", channel)
	msg = handle_random(msg)
	return msg


func handle_random(msg: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\$\\{random.([0-9]{1,3})\\}")
	var matches = regex.search_all(msg)
	for m in matches:
		var matched = m.strings[0]
		var bound = int(matched.substr(9, matched.length() - 10))
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(randi() % bound + 1))
	return msg
