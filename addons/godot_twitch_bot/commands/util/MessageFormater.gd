extends Reference

var manager

var file := File.new()

func format_message(msg: String, channel: String, message: Dictionary) -> String:
	var params := PoolStringArray()
	if message.command.has("botCommandParams"):
		params = message.command.botCommandParams.split(" ")
	msg = msg.replace("${sender}", message.tags["display-name"])
	msg = msg.replace("${touser}", params[0] if not params.empty() else message.tags["display-name"])
	msg = handle_args(msg, params)
	msg = handle_channel(msg, channel, message)
	msg = handle_random(msg)
	msg = handle_counter(msg)
	return msg


func handle_channel(msg: String, channel: String, message: Dictionary) -> String:
	msg = msg.replace("${channel}", channel)
	var regex = RegEx.new()
	regex.compile("\\$\\{channel [a-zA-Z0-9_]+\\}")
	var matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var cnl = matched.substr(10, matched.length() - 11)
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(cnl.to_lower()))
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
			msg = msg.insert(pos, str(args[arg]))
	regex.compile("\\$\\{[0-9]+:[0-9]*\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var arg = int(matched.substr(2, matched.length() - 2 - (matched.length() - matched.find(":")))) - 1
		var arg2 = matched.substr(matched.find(":"), matched.length() - 2)
		var out = ""
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
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
		var counter = matched.substr(8, matched.length() - 12)
		if not counter in manager.counters.keys():
			manager.counters[counter] = 0
		manager.counters[counter] += 1
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(manager.counters[counter]))
	regex.compile("\\$\\{count [a-zA-Z0-9]+ [0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched = m.strings[0]
		var counter = matched.substr(8, matched.length() - 8 - (matched.length() - matched.find_last(" ")))
		var val = int(matched.substr(matched.find_last(" "), matched.length() - 2))
		manager.counters[counter] = val
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(manager.counters[counter]))
	regex.compile("\\$\\{count [a-zA-Z0-9]+ (\\+|-)[0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched = m.strings[0]
		var counter = matched.substr(8, matched.length() - 8 - (matched.length() - matched.find_last(" ")))
		var val = int(matched.substr(matched.find_last(" "), matched.length() - 2))
		if not counter in manager.counters.keys():
			manager.counters[counter] = 0
		manager.counters[counter] += val
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(manager.counters[counter]))
	regex.compile("\\$\\{getcount [a-zA-Z0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched = m.strings[0]
		var counter = matched.substr(11, matched.length() - 12)
		if not counter in manager.counters.keys():
			manager.counters[counter] = 0
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(manager.counters[counter]))
	return msg
