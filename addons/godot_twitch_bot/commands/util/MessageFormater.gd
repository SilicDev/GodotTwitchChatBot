extends Reference

var counters := {}

var file := File.new()

func format_message(msg: String, channel: String, message: Dictionary) -> String:
	var params := PoolStringArray()
	if message.command.has("botCommandParams"):
		params = message.command.botCommandParams.split(" ")
	msg = msg.replace("${sender}", message.tags["display-name"])
	msg = msg.replace("${touser}", params[0] if not params.empty() else message.tags["display-name"])
	msg = msg.replace("${channel}", channel)
	msg = handle_args(msg, params)
	msg = handle_random(msg)
	msg = handle_counter(msg)
	return msg


func save_counters(path: String) -> int:
	var dir := Directory.new()
	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())
	var err := file.open(path, File.WRITE)
	if err:
		push_error("Failed to save counters! Unable to open destination file (Error #" + str(err) + ")")
		return err
	file.store_string(JSON.print(counters))
	file.close()
	return OK


func load_counters(path: String) -> int:
	var err = file.open(path, File.READ)
	if err:
		save_counters(path)
		file.open(path, File.READ)
	var result := JSON.parse(file.get_as_text())
	file.close()
	if result.error:
		push_error("Error loading counters: line " + str(result.error_line) + ": " + result.error_string)
	return OK


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
			msg = msg.insert(pos, str(arg))
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
		if not counter in counters.keys():
			counters[counter] = 0
		counters[counter] += 1
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(counters[counter]))
	regex.compile("\\$\\{count [a-zA-Z0-9]+ [0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched = m.strings[0]
		var counter = matched.substr(8, matched.length() - 8 - (matched.length() - matched.find_last(" ")))
		var val = int(matched.substr(matched.find_last(" "), matched.length() - 2))
		counters[counter] = val
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(counters[counter]))
	regex.compile("\\$\\{count [a-zA-Z0-9]+ (\\+|-)[0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched = m.strings[0]
		var counter = matched.substr(8, matched.length() - 8 - (matched.length() - matched.find_last(" ")))
		var val = int(matched.substr(matched.find_last(" "), matched.length() - 2))
		if not counter in counters.keys():
			counters[counter] = 0
		counters[counter] += val
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(counters[counter]))
	regex.compile("\\$\\{getcount [a-zA-Z0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched = m.strings[0]
		var counter = matched.substr(11, matched.length() - 12)
		if not counter in counters.keys():
			counters[counter] = 0
		var pos = msg.find(matched)
		msg.erase(pos, matched.length())
		msg = msg.insert(pos, str(counters[counter]))
	return msg
