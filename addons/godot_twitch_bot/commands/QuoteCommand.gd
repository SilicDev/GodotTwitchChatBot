extends ScriptCommand


var no_formating := true
var rng = RandomNumberGenerator.new()


func _init() -> void:
	usage_hint = "!quote [add|edit|remove|ID] [number] quote"
	example_reply = "Successfully added quote #42 \"May Kappa rest in peace Sadge\"!"
	name = "quote"
	permission_level = Command.Badge.NONE
	rng.randomize()


func get_response(parsedMessage: Dictionary) -> String:
	var params := PackedStringArray()
	if parsedMessage.command.has("botCommandParams"):
		params = parsedMessage.command.botCommandParams.split(" ")
	var sender = parsedMessage.get("tags", {}).get("display-name", "")
	var channel = parsedMessage.command.channel
	
	var quoteDict := get_quotes(channel)
	
	if params.is_empty():
		if quoteDict.keys().size() > 0:
			var quoteID = quoteDict.keys()[rng.randi() % quoteDict.keys().size()]
			while not quoteID.is_valid_int():
				quoteID = quoteDict.keys()[rng.randi() % quoteDict.keys().size()]
			return "Quote #" + str(quoteID) + ": " + quoteDict[quoteID]
		else:
			return sender + " usage of command \"" + name + "\": " + usage_hint
	
	match params[0].to_lower():
		"edit":
			var quoteID = params[1].replace("#", "")
			if quoteID.is_valid_int():
				var quote = ""
				for i in range(2, params.size()):
					quote += params[i] + " "
				quote = quote.substr(0, quote.length() - 1)
				if quoteID in quoteDict:
					quoteDict[quoteID] = quote
					save_quotes(channel, quoteDict)
					return sender + ", successfully edited quote #" + quoteID + ": " + quoteDict[quoteID]
				
				return "Quote with ID #" + quoteID + " doesn't exist!"
			else:
				return "Requested ID #" + quoteID + " is invalid!"
		
		"add":
			var quote = "";
			for i in range(1, params.size()): 
				quote += params[i] + " "
			if quote.is_empty():
				return "Can't save empty quote!"
			quote = quote.substr(0, quote.length() - 1)
			
			var nextID = quoteDict.get("size", quoteDict.keys().size()) + 1
			#var nextID = 1
			#while str(nextID) in quoteDict.keys():
				#nextID += 1
				#if nextID < 0:
					#return "Quote capacity reached!"
			
			var ID = str(nextID)
			print(ID)
			quoteDict[ID] = quote
			quoteDict["size"] = nextID
			save_quotes(channel, quoteDict)
			return sender + ", successfully added quote #" + ID + ": " + quoteDict[ID]
		
		"remove":
			var quoteID = params[1].replace("#", "")
			if quoteID.is_valid_int():
				var res = quoteDict.erase(quoteID)
				save_quotes(channel, quoteDict)
				if res:
					return sender + ", successfully removed quote #" + quoteID + "!"
				else:
					return "Quote with ID #" + quoteID + " doesn't exist!"
			else:
				return "Requested ID #" + quoteID + " is invalid!"
		
		_:
			var quoteID = params[0].replace("#", "")
			if quoteID.is_valid_int():
				if quoteID in quoteDict:
					return "Quote #" + quoteID + ": " + quoteDict[quoteID]
				return "Quote with ID #" + quoteID + " doesn't exist!"
			else:
				return "Requested ID #" + quoteID + " is invalid!"
		
	return ""


func get_quotes(channel: String) -> Dictionary:
	var c := channel.to_lower()
	if c.begins_with("#"):
		c = c.substr(1)
	
	var path = "user://channels/" + c + "/quotes.json"
	var file := FileAccess.open(path, FileAccess.READ)
	var err := FileAccess.get_open_error()
	if err:
		push_warning("Failed to load quotes file")
		return {}
	
	var test_json_conv = JSON.new()
	err = test_json_conv.parse(file.get_as_text())
	var res := test_json_conv.get_data()
	file.close()
	if not err:
		if not res.has("size"):
			res.size = res.keys().size()
		return res
	push_warning("Failed to parse quotes json! %s (%d)" % [test_json_conv.get_error_message(), test_json_conv.get_error_line()])
	return {}


func save_quotes(channel: String, quotes: Dictionary) -> int:
	var c := channel.to_lower()
	if c.begins_with("#"):
		c = c.substr(1)
	
	var path = "user://channels/" + c + "/quotes.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	var err := FileAccess.get_open_error()
	if err:
		push_error("Unable to save quotes!")
		return err
	
	file.store_string(JSON.stringify(quotes, "\t"))
	file.close()
	return OK
