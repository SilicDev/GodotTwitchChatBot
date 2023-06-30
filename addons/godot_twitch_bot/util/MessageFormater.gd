extends RefCounted

var channel: String
var channel_id: String
var bot_id: String

var counterManager
var api : TwitchAPI


func format_message(msg: String, message: Dictionary) -> String:
	var params := PackedStringArray()
	if message.command.has("botCommandParams"):
		params = message.get("command", {}).get("botCommandParams", "").split(" ")
	
	var sender_name = message.get("tags", {}).get("display-name", "")
	
	msg = msg.replace("${sender}", sender_name)
	msg = msg.replace("${touser}", params[0] if not params.is_empty() else sender_name)
	
	msg = handle_args(msg, params)
	msg = handle_channel(msg, channel)
	msg = await handle_game(msg)
	msg = await handle_web_request(msg)
	msg = handle_random(msg)
	msg = handle_counter(msg)
	msg = await handle_shoutout(msg)
	
	return msg


func handle_args(msg: String, args: PackedStringArray) -> String:
	var regex = RegEx.new()
	regex.compile("\\$\\{[0-9]+\\}")
	
	var matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var arg = int(matched.substr(2, matched.length() - 3)) - 1
		if arg < args.size() and arg >= 0:
			var pos = msg.find(matched)
			msg = _str_erase(msg, pos, matched.length())
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
		msg = _str_erase(msg, pos, length)
		if arg2.is_empty():
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
		msg = _str_erase(msg, pos, matched.length())
		msg = msg.insert(pos, str(cnl))
	
	return msg


func handle_game(msg: String) -> String:
	if "${game}" in msg:
		var result = await api.get_channel_info([channel_id])
		var own_game_name = result.data[0].game_name
		if own_game_name.is_empty():
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
		var channel = await api.get_users_by_name([cnl])
		var cnl_id = channel.data[0].id
		var pos = msg.find(matched)
		msg = _str_erase(msg, pos, matched.length())
		var game_name = (await api.get_channel_info([cnl_id])).data[0].game_name
		msg = msg.insert(pos, game_name)
	
	return msg


func handle_shoutout(msg: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\$\\{shoutout (@)?[a-zA-Z0-9_]+\\}")
	var matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var cnl = matched.substr(11, matched.length() - 12).to_lower()
		if cnl.begins_with("@"):
			cnl = cnl.substr(1)
		var channel = await api.get_users_by_name([cnl])
		var cnl_id = channel.data[0].id
		var pos = msg.find(matched)
		msg = _str_erase(msg, pos, matched.length())
		var result = await api.send_shoutout(channel_id, cnl_id, bot_id)
		if result.status != 200:
			push_warning("HTTP Error %s: %s" % [result.status, result.message])
		msg = msg.insert(pos, "")
	
	return msg

func handle_web_request(msg: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\$\\{web [\\S]+\\}")
	var matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var address = matched.substr(6, matched.length() - 7).to_lower()
		var host = address.left(address.find("/", address.find(":") + 3))
		var connected = await connect_to_host(host)
		var err = _request(HTTPClient.METHOD_GET, 
				address.right(address.find("/", address.find(":") + 3)),
				base_headers)
		if err:
			disconnect_from_host()
			return "Failed to get web result: %s" % [client.get_response_code()]
		var data := await _get_response()
		disconnect_from_host()
		var xml := XMLParser.new()
		var text = ""
		xml.open_buffer(data.message.to_utf8_buffer())
		while not xml.read():
			if xml.get_node_type() == XMLParser.NODE_TEXT:
				text+= xml.get_node_data()
		return text
	regex.compile("\\$\\{webrl [\\S]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var address = matched.substr(8, matched.length() - 9)
		var host = address.left(address.find("/", address.find(":") + 3))
		var path = address.right(-address.find("/", address.find(":") + 3))
		var connected = await connect_to_host(host)
		var err = _request(HTTPClient.METHOD_GET, 
				path,
				base_headers)
		if err:
			disconnect_from_host()
			return "Failed to get web result: %s" % [client.get_response_code()]
		var data := await _get_response()
		disconnect_from_host()
		var xml := XMLParser.new()
		var text = ""
		xml.open_buffer(data.message.to_utf8_buffer())
		while not xml.read():
			if xml.get_node_type() == XMLParser.NODE_TEXT:
				text+= xml.get_node_data()
		var lines := text.split("\n")
		var result := lines[randi()% lines.size()]
		return result
	return msg


func handle_random(msg: String) -> String:
	var regex = RegEx.new()
	regex.compile("\\$\\{random.([0-9]{1,3})\\}")
	var matches = regex.search_all(msg)
	for m in matches:
		var matched = m.strings[0]
		var bound = int(matched.substr(9, matched.length() - 10))
		var pos = msg.find(matched)
		msg = _str_erase(msg, pos, matched.length())
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
		msg = _str_erase(msg, pos, matched.length())
		msg = msg.insert(pos, str(counterManager.counters[counter]))
	
	regex.compile("\\$\\{count [a-zA-Z0-9]+ [0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var length := matched.length()
		var counter = matched.substr(8, length - 8 - (length - matched.rfind(" ")))
		var val = int(matched.substr(matched.rfind(" "), length - 2))
		counterManager.counters[counter] = val
		var pos = msg.find(matched)
		msg = _str_erase(msg, pos, length)
		msg = msg.insert(pos, str(counterManager.counters[counter]))
	
	regex.compile("\\$\\{count [a-zA-Z0-9]+ (\\+|-)[0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched: String = m.strings[0]
		var length := matched.length()
		var counter = matched.substr(8, length - 8 - (length - matched.rfind(" ")))
		var val = int(matched.substr(matched.rfind(" "), length - 2))
		
		if not counter in counterManager.counters.keys():
			counterManager.counters[counter] = 0
		
		counterManager.counters[counter] += val
		var pos = msg.find(matched)
		msg = _str_erase(msg, pos, length)
		msg = msg.insert(pos, str(counterManager.counters[counter]))
	
	regex.compile("\\$\\{getcount [a-zA-Z0-9]+\\}")
	matches = regex.search_all(msg)
	for m in matches:
		var matched = m.strings[0]
		var counter = matched.substr(11, matched.length() - 12)
		
		if not counter in counterManager.counters.keys():
			counterManager.counters[counter] = 0
		
		var pos = msg.find(matched)
		msg = _str_erase(msg, pos, matched.length())
		msg = msg.insert(pos, str(counterManager.counters[counter]))
	
	return msg


func _str_erase(str: String, pos: int, len := 1) -> String:
	return str.left(max(0, pos)) + str.substr(pos + len)

var client := HTTPClient.new()
var headers := []
var base_headers := [
	"User-Agent: Pirulo/1.0 (Godot)",
	"Accept: application/json",
]
var mutex := Mutex.new()

func connect_to_host(host: String, args = null) -> bool:
	var err := client.connect_to_host(host)
	if err:
		return false
	print("Connecting...")
	while (client.get_status() == HTTPClient.STATUS_CONNECTING or 
			client.get_status() == HTTPClient.STATUS_RESOLVING):
		client.poll()
		printraw(".")
		if not OS.has_feature("web"):
			OS.delay_msec(500)
		else:
			await Engine.get_main_loop().process_frame
	return true

func disconnect_from_host() -> void:
	client.close()

## Helper functions
func _request(method: int, url: String, request_headers: PackedStringArray, body := "") -> int:
	mutex.lock()
	if not client.get_status() == HTTPClient.STATUS_CONNECTED:
		push_error(client.get_status())
		return FAILED
	print("Requesting...")
	return client.request(method, url, request_headers, body)


func _get_response() -> Dictionary:
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		client.poll()
		printraw(".")
		if OS.has_feature("web"):
			# Synchronous HTTP requests are not supported on the web,
			# so wait for the next main loop iteration.
			await Engine.get_main_loop().process_frame
		else:
			OS.delay_msec(500)
	
	if client.has_response():
		var status = client.get_response_code()
		# If there is a response...
		
		var rb = PackedByteArray() # Array that will hold the data.
		
		while client.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			client.poll()
			# Get a chunk.
			var chunk = client.read_response_body_chunk()
			if chunk.size() == 0:
				if not OS.has_feature("web"):
					# Got nothing, wait for buffers to fill a bit.
					OS.delay_usec(100)
				else:
					await Engine.get_main_loop().process_frame
			else:
				rb = rb + chunk # Append to read buffer.
		# Done!
		
		var message = rb.get_string_from_utf8()
		var test_json_conv = JSON.new()
		var err := test_json_conv.parse(message)
		var result = test_json_conv.get_data()
		if not err:
			if not "status" in result.keys():
				result["status"] = status
			mutex.unlock()
			return result
		var data = {
			"message": message,
			"status" : status,
		}
		mutex.unlock()
		return data
	mutex.unlock()
	return {}
