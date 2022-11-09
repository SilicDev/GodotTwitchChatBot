extends Reference

var channel: String
var channel_id: String

var counterManager
var api : TwitchAPI


func format_message(msg: String, message: Dictionary) -> String:
	var params := PoolStringArray()
	if message.command.has("botCommandParams"):
		params = message.get("command", {}).get("botCommandParams", "").split(" ")
	
	var sender_name = message.get("tags", {}).get("display-name", "")
	
	msg = msg.replace("${sender}", sender_name)
	msg = msg.replace("${touser}", params[0] if not params.empty() else sender_name)
	
	msg = handle_args(msg, params)
	msg = handle_channel(msg, channel)
	msg = handle_game(msg)
	msg = handle_random(msg)
	msg = handle_counter(msg)
	
	return msg


func handle_args(msg: String, args: PoolStringArray) -> String:
	var regex = RegEx.new()
	regex.compile("\\$\\{[0-9]+\\}")
	
	var matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var arg = int(matched.substr(2, matched.length() - 3)) - 1
		if arg < args.size() and arg >= 0:
			var pos = msg.find(matched)
			msg.erase(pos, matched.length())
			var param = args[arg]
			if param.begins_with("@"):
				param = param.substr(1)
			msg = msg.insert(pos, param)
	
	regex.compile("\\$\\{[0-9]+:[0-9]*\\}")
	
	matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var length := matched.length()
		var arg = int(matched.substr(2, length - 2 - (length - matched.find(":")))) - 1
		var arg2 = matched.substr(matched.find(":"), length - 2)
		var out = ""
		var pos = msg.find(matched)
		msg.erase(pos, length)
		if arg2.empty():
			if arg < args.size() and arg >= 0:
				for i in range(arg, args.size()):
					out += " " + args[i] 
				out.substr(1)
		
		else:
			arg2 = int(arg2) - 1
			if arg2 >= args.size():
				for i in range(arg, args.size()):
					out += " " + args[i] 
				out.substr(1)
			elif arg2 > arg and arg >= 0 and arg2 > 0:
				for i in range(arg, arg2):
					out += " " + args[i] 
				out.substr(1)
		
		msg = msg.insert(pos, out)
	return msg


func handle_channel(msg: String, channel: String) -> String:
	if "${channel}" in msg:
		msg = msg.replace("${channel}", channel)
	
	var regex = RegEx.new()
	regex.compile("\\$\\{channel (@)?[a-zA-Z0-9_]+\\}")
	var matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var cnl = matched.substr(10, matched.length() - 11).to_lower()
		if cnl.begins_with("@"):
			cnl = cnl.substr(1)
		
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(cnl))
	
	return msg


func handle_game(msg: String) -> String:
	if "${game}" in msg:
		var result = api.get_channel_info([channel_id])
		var own_game_name = result.data[0].game_name
		if own_game_name.empty():
			own_game_name = "[No Game found]"
		msg = msg.replace("${game}", own_game_name)
	var regex = RegEx.new()
	regex.compile("\\$\\{game (@)?[a-zA-Z0-9_]+\\}")
	var matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var cnl = matched.substr(7, matched.length() - 8).to_lower()
		if cnl.begins_with("@"):
			cnl = cnl.substr(1)
		var channel = api.get_users_by_name([cnl])
		var cnl_id = channel.data[0].id
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		var game_name = api.get_channel_info([cnl_id]).data[0].game_name
		msg = msg.insert(pos, game_name)
	
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


func handle_counter(msg: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\$\\{count [a-zA-Z0-9]+\\}")
	var matches = regex.search_all(msg)
	for m in matches:
		var matched = m.strings[0]
		var counter = matched.substr(8, matched.length() - 9)
		if not counter in counterManager.counters.keys():
			counterManager.counters[counter] = 0
		counterManager.counters[counter] += 1
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(counterManager.counters[counter]))
	
	regex.compile("\\$\\{count [a-zA-Z0-9]+ [0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var length := matched.length()
		var counter = matched.substr(8, length - 8 - (length - matched.find_last(" ")))
		var val = int(matched.substr(matched.find_last(" "), length - 2))
		counterManager.counters[counter] = val
		var pos = msg.find(matched)
		msg.erase(pos, length)
		msg = msg.insert(pos, str(counterManager.counters[counter]))
	
	regex.compile("\\$\\{count [a-zA-Z0-9]+ (\\+|-)[0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var length := matched.length()
		var counter = matched.substr(8, length - 8 - (length - matched.find_last(" ")))
		var val = int(matched.substr(matched.find_last(" "), length - 2))
		
		if not counter in counterManager.counters.keys():
			counterManager.counters[counter] = 0
		
		counterManager.counters[counter] += val
		var pos = msg.find(matched)
		msg.erase(pos, length)
		msg = msg.insert(pos, str(counterManager.counters[counter]))
	
	regex.compile("\\$\\{getcount [a-zA-Z0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched = m.strings[0]
		var counter = matched.substr(11, matched.length() - 12)
		
		if not counter in counterManager.counters.keys():
			counterManager.counters[counter] = 0
		
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(counterManager.counters[counter]))
	
	return msg
