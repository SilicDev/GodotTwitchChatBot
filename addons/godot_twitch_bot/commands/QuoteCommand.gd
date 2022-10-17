extends ScriptCommand


var no_formating := true


func _init() -> void:
	usage_hint = "!quote [add|edit|remove|ID] [number] quote"
	example_reply = "Successfully added quote #42 \"May Kappa rest in peace Sadge\"!"
	name = "quote"
	permission_level = Command.Badge.NONE


func get_response(parsedMessage: Dictionary) -> String:
	var params := PoolStringArray()
	if parsedMessage.command.has("botCommandParams"):
		params = parsedMessage.command.botCommandParams.split(" ")
	var sender = parsedMessage.get("tags", {}).get("display-name", "")
	var channel = parsedMessage.command.channel
	
	var quoteDict := get_quotes(channel)
	
	if params.empty():
		if quoteDict.keys().size() > 0:
			var quoteID = quoteDict.keys()[randi() % quoteDict.keys().size()]
			return "Quote #" + quoteID + ": " + quoteDict[quoteID]
		else:
			return sender + " usage of command \"" + name + "\": " + usage_hint
	
	match params[0].to_lower():
		"edit":
			var quoteID = params[1].replace("#", "")
			var quote = ""
			for i in range(2, params.size()):
				quote += params[i] + " "
			quote = quote.substr(0, quote.length() - 1)
			if quoteID in quoteDict:
				quoteDict[quoteID] = quote
				save_quotes(channel, quoteDict)
				return sender + ", successfully edited quote #" + quoteID + ": " + quoteDict[quoteID]
			
			return "Quote with ID #" + quoteID + " doesn't exist!"
		
		"add":
			var quote = ""
			for i in range(1, params.size()):
				quote += params[i] + " "
			quote = quote.substr(0, quote.length() - 1)
			
			var nextID = quoteDict.get("size", quoteDict.keys().size() - 1)
			#var nextID = 1
			#while str(nextID) in quoteDict.keys():
				#nextID += 1
				#if nextID < 0:
					#return "Quote capacity reached!"
			
			var ID = str(nextID)
			quoteDict[ID] = quote
			save_quotes(channel, quoteDict)
			return sender + ", successfully added quote #" + ID + ": " + quoteDict[ID]
		
		"remove":
			var quoteID = params[1].replace("#", "")
			var res = quoteDict.erase(quoteID)
			save_quotes(channel, quoteDict)
			if res:
				return sender + ", successfully removed quote #" + quoteID + "!"
			else:
				return "Quote with ID #" + quoteID + " doesn't exist!"
		
		_:
			var quoteID = params[0].replace("#", "")
			if quoteID in quoteDict:
				return "Quote #" + quoteID + ": " + quoteDict[quoteID]
			return "Quote with ID #" + quoteID + " doesn't exist!"
		
	return ""


func get_quotes(channel: String) -> Dictionary:
	var c := channel.to_lower()
	if c.begins_with("#"):
		c = c.substr(1)
	
	var file := File.new()
	var path = "user://channels/" + c + "/quotes.json"
	var err := file.open(path, File.READ)
	if err:
		return {}
	
	var res := JSON.parse(file.get_as_text())
	file.close()
	if not res.error:
		if not res.result.has("size"):
			res.result.size = res.result.keys().size()
		return res.result
	return {}


func save_quotes(channel: String, quotes: Dictionary) -> int:
	var c := channel.to_lower()
	if c.begins_with("#"):
		c = c.substr(1)
	
	var file := File.new()
	var path = "user://channels/" + c + "/quotes.json"
	var err := file.open(path, File.WRITE)
	if err:
		push_error("Unable to save quotes!")
		return err
	
	file.store_string(JSON.print(quotes, "\t"))
	file.close()
	return OK
