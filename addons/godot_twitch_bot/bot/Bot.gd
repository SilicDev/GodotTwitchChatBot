@icon("res://addons/godot_twitch_bot/assets/icon.png")
class_name TwitchBot
extends Node


signal joined_channel(channel)
signal parted_channel(channel)

signal chat_message_received(message, channel)
signal chat_message_send(message, channel, reply_id)

signal userstate_received(tags, channel)
signal roomstate_received(tags, channel)

signal command_fired(cmd, params, channel)

signal chat_message_deleted(id, channel)
signal user_messages_deleted(id, channel)

signal connected()
signal disconnected()
signal pinged()

signal auth_token_expired()

enum ConnectionMethod {
	WEBSOCKET,
	TCP,
}


var bot_name := ""
var join_message := ""

var connection : Connection
var connection_method := ConnectionMethod.WEBSOCKET

var oauth := ""
var refresh_token := ""
var client_id := ""

var display_name := ""
var chat_color := ""
var bot_id := ""

var connected_to_twitch := false

var read_only := false
var request_membership := true

var full_IRC := true#false
var authenticated := false

var reconnect_attempts = 0

var default_channels := []
var channels : Dictionary[String, Channel] = {}

var active_threads := []

var config := ConfigFile.new()

var channelManagerScript = preload("res://addons/godot_twitch_bot/bot/Channel.gd")


var last_ping = -1

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_ini()


func _notification(what: int) -> void:
	## Handle quiting gracefully
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if connected_to_twitch:
			disconnect_from_twitch()
		save_ini()


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not connection:
		return
	connection.update()
	if last_ping != -1 and (Time.get_unix_time_from_system() - last_ping) > 300:
		disconnect_from_twitch()
		connect_to_twitch.call_deferred()
		push_warning("Missed Ping!")
		last_ping = -1
	if connection.status == Connection.Status.CONNECTED:
		
		if not connected_to_twitch:
			connected_to_twitch = true
			authenticated = false
			print("Authorizing...")
			
			if not read_only:
				if request_membership:
					send("CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands")
				else:
					send("CAP REQ :twitch.tv/tags twitch.tv/commands")
				
				send("PASS oauth:" + oauth)
				send("NICK " + bot_name)
			else:
				send("NICK " + "justinfan12345")
		
		if connection.has_message():
			var messages := connection.receive().split("\r\n")
			for msg in messages:
				var parsedMessage: Dictionary[String, Variant] = _IRCMessageParser.parse_message(msg)
				if OS.is_debug_build():
					if not msg.is_empty():
						if full_IRC:
							print("> " + msg)
					
				
				if not parsedMessage.is_empty():
					var tags = parsedMessage.get("tags", {})
					var commandDict = parsedMessage.get("command", {})
					var parameters = parsedMessage.get("parameters", "")
					var c := ""
					c = commandDict.get("channel", "")
					if c.begins_with("#"):
						c = c.substr(1)
					
					match commandDict.get("command", ""):
						"PRIVMSG":
							emit_signal("chat_message_received", parsedMessage, c)
							print()
							if parsedMessage.tags.get("source-room-id", channels[c].channel_id) == channels[c].channel_id:
								channels[c].handle_message(parsedMessage)
							if not full_IRC:
								var display_name = tags.get("display-name", "Anonymous")
								print("> " + display_name + ": " + parameters)
						
						"PING":
							if last_ping != -1:
								print("Ping time: %fs" % (Time.get_unix_time_from_system() - last_ping))
							last_ping = Time.get_unix_time_from_system()
							emit_signal("pinged")
							send("PONG :" + parameters)
						
						"001":
							print("Successfully authorized!")
							authenticated = true
							reconnect_attempts = 0
							for cnl in default_channels:
								join_channel(cnl)
						
						"JOIN":
							if is_sender_self(parsedMessage) or read_only:
								print("joined " + commandDict.channel)
								if not c in channels.keys():
									channels[c] = channelManagerScript.new(c)
									channels[c].api.authentication_failed.connect(on_API_authentication_failed)
									channels[c].connect("command_fired",_on_Channel_command_fired)
								channels[c].connected = true
								channels[c].formatter.bot_id = bot_id
								emit_signal("joined_channel", c)
						
						"PART":
							if (is_sender_self(parsedMessage) and channels[c].connected) \
									or read_only:
								send("JOIN #" + c.to_lower())
						
						"NOTICE":
							parse_notice(tags, parameters, c)
						
						"GLOBALUSERSTATE":
							display_name = tags.get("display-name", "")
							var color = tags.get("color", "#ffffff")
							chat_color = color if color != null else Color.WHITE 
							bot_id = tags.get("user-id", "")
						
						"USERSTATE":
							emit_signal("userstate_received", tags, c)
						
						"ROOMSTATE":
							emit_signal("roomstate_received", tags, c)
						
						"CLEARMSG":
							if tags.has("target-msg-id"):
								emit_signal("chat_message_deleted", tags.get("target-msg-id"), c)
						
						"CLEARCHAT":
							if tags.has("target-user-id"):
								emit_signal("user_messages_deleted", tags.get("target-user-id"), c)
							else:
								emit_signal("chat_message_deleted", "", c)
						
						"RECONNECT":
							save_ini()
		for c in channels.keys():
			if channels[c].connected and not channels[c].message_queue.is_empty():
				var data = channels[c].message_queue.pop_front()
				if data is String:
					chat(c, data)
				
				elif data is Array:
					if data.size() == 1:
						chat(c, data[0])
					
					elif data.size() == 2:
						chat(c, data[0], data[1])
		
	else:
		if connection.status == Connection.Status.ERROR:
			push_warning("Lost Connection")
			disconnect_from_twitch()
			get_window().request_attention()
			get_window().grab_focus()
		
		if connection.status == Connection.Status.DISCONNECTED and connected_to_twitch:
			push_warning("Lost Connection")
			get_window().request_attention()
			get_window().grab_focus()
			disconnect_from_twitch()
			var thread = Thread.new()
			thread.start(func ():
				while not authenticated and reconnect_attempts < 10:
					await get_tree().create_timer(pow(2, reconnect_attempts)).timeout
					if connection.status == Connection.Status.DISCONNECTED:
						connect_to_twitch()
						reconnect_attempts += 1
			)
			active_threads.append(thread)

func connect_to_twitch() -> int:
	load_ini()
	
	if connection_method == ConnectionMethod.WEBSOCKET:
		print("Connecting via WebSocket...")
		connection = preload("res://addons/godot_twitch_bot/network/WSConnection.gd").new()
	elif connection_method == ConnectionMethod.TCP:
		print("Connecting via TCP...")
		connection = preload("res://addons/godot_twitch_bot/network/TCPConnection.gd").new()
	
	var err := connection.connect_to_host()
	if not err:
		emit_signal("connected")
		print("Connected")
	else:
		connected_to_twitch = false
	return err


func disconnect_from_twitch() -> void:
	for c in channels.keys():
		part_channel(c)
	connection.disconnect_from_host()
	connected_to_twitch = false
	authenticated = false
	emit_signal("disconnected")
	print("Disconnected")


func join_channel(channel: String) -> void:
	var c := channel.to_lower()
	if c.begins_with("#"):
		c = c.substr(1)
	if not channels.has(c) or not channels[c].connected:
		send("JOIN #" + c)


func part_channel(channel: String) -> void:
	var c := channel.to_lower()
	if c.begins_with("#"):
		c = c.substr(1)
	send("PART #" + c)
	channels[c].save_data()
	channels[c].connected = false
	emit_signal("parted_channel", c)


func chat(channel: String, msg: String, reply_id: String = "") -> void:
	if not read_only:
		var c := channel.to_lower()
		if c.begins_with("#"):
			c = c.substr(1)
		if not reply_id.is_empty():
			send("@reply-parent-msg-id=" + reply_id + " PRIVMSG #" + c + " :" + msg)
		else:
			send("PRIVMSG #" + c + " :" + msg)
		emit_signal("chat_message_send", msg, c, reply_id)


func send(msg: String) -> void:
	if not connection:
		push_warning("Must be connected to send messages!")
		return
	connection.send(msg)


func load_ini() -> void:
	var err := config.load("user://config.ini")
	if err:
		save_ini()
		config.load("user://config.ini")
	
	bot_name = config.get_value("auth", "bot_name", "")
	oauth = config.get_value("auth", "oauth", "")
	refresh_token = config.get_value("auth", "refresh", "")
	
	var protocol = config.get_value("auth", "protocol", "TCP").to_upper()
	if protocol in ConnectionMethod.keys():
		connection_method = ConnectionMethod[protocol]
	else:
		connection_method = ConnectionMethod.WEBSOCKET
	
	read_only = config.get_value("auth", "read_only", false)
	default_channels = config.get_value("channels", "channels", [])
	join_message = config.get_value("channels", "join_message", "")
	client_id = config.get_value("twitch", "client_id", "")
	
	config.clear()


func save_ini(update_channels = true) -> void:
	config.set_value("auth", "bot_name", bot_name)
	config.set_value("auth", "oauth", oauth)
	config.set_value("auth", "refresh", refresh_token)
	config.set_value("auth", "protocol", ConnectionMethod.keys()[connection_method])
	config.set_value("auth", "read_only", read_only)
	if update_channels:
		config.set_value("channels", "channels", channels.keys())
	else:
		config.set_value("channels", "channels", default_channels)
	config.set_value("channels", "join_message", join_message)
	config.set_value("twitch", "client_id", client_id)
	
	var path = "user://config.ini"
	var dir := DirAccess.open("user://")
	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())
	
	config.save(path)
	config.clear()


func is_connected_to_channel(channel: String) -> bool:
	var c := channel.to_lower()
	if c.begins_with("#"):
		c = c.substr(1)
	if not c in channels.keys():
		return false
	return channels[c].connected


func parse_notice(tags, parameters: String, channel: String):
	var c := channel.to_lower()
	if c.begins_with("#"):
		c = c.substr(1)
	
	var msg_id = ""
	if tags:
		msg_id = tags.get("msg-id", "")
	if msg_id.is_empty():
		## If the authentication failed, leave the channel.
		## The server will close the connection.
		if "Login authentication failed" == parameters or "Invalid NICK" == parameters:
			push_error("Authentication failed; left " + str(channels))
			on_API_authentication_failed()
			for cnl in channels:
				part_channel(cnl)
	
	else:
		match msg_id:
			"msg_suspended":
				push_error("No permission. Check if the access token is still valid.\n" +
						"Left " + str(channels)
				)
				for cnl in channels:
					part_channel(cnl)
			
			## Failed to reconnect after receiving own part message
			## The bot probably was banned
			"msg_banned":
				push_warning("The stream must have banned (/ban) the bot!")
				part_channel(c)


func is_sender_self(parsedMessage: Dictionary[String, Variant]) -> bool:
	return parsedMessage.get("source", {}).get("nick", "") == bot_name


func get_channel_by_id(id: String) -> Channel:
	for c in channels.keys():
		if channels[c].channel_id == id:
			return channels[c]
	return null


func _on_Channel_command_fired(cmd, parsedMessage, channel) -> void:
	emit_signal("command_fired", cmd, parsedMessage, channel)


func on_API_authentication_failed() -> void:
	var url = "/oauth2/token"
	var body = "grant_type=refresh_token&refresh_token={}&client_id={}".format([refresh_token, client_id], "{}")
	var headers = [
		"Content-Type: application/x-www-form-urlencoded", 
		"Content-Length: " + str(body.length())
	]
	var http_client = HTTPClient.new()
	http_client.connect_to_host("https://id.twitch.tv")
	http_client.poll()
	var client_alive = true
	var request_timeout = 0
	var token_found = false
	while client_alive:
		match http_client.get_status():
			HTTPClient.STATUS_DISCONNECTED:
				client_alive = false
				print("Disconnected")
			HTTPClient.STATUS_RESOLVING:
				http_client.poll()
			HTTPClient.STATUS_CANT_RESOLVE:
				client_alive = false
			HTTPClient.STATUS_CONNECTING:
				http_client.poll()
			HTTPClient.STATUS_CANT_CONNECT:
				client_alive = false
			HTTPClient.STATUS_CONNECTED:
				if request_timeout <= Time.get_ticks_msec():
					var err := http_client.request(HTTPClient.METHOD_POST, url, headers, body)
					if err:
						client_alive = false
			HTTPClient.STATUS_REQUESTING:
				http_client.poll()
			HTTPClient.STATUS_BODY:
				var status = http_client.get_response_code()
				# If there is a response...
				var rb = PackedByteArray() # Array that will hold the data.
				
				while http_client.get_status() == HTTPClient.STATUS_BODY:
					# Get a chunk.
					var chunk = http_client.read_response_body_chunk()
					if chunk.size() == 0:
						OS.delay_msec(10)
					else:
						rb.append_array(chunk) # Append to read buffer.
					# While there is body left to be read
					http_client.poll()
				# Done!
				
				var message = rb.get_string_from_utf8()
				var test_json_conv = JSON.new()
				var err := test_json_conv.parse(message)
				if err:
					request_timeout = Time.get_ticks_msec() + 5000
					continue
				var result: Dictionary = test_json_conv.get_data()
				if status != 200 || not result.has("access_token"):
					print(str(status) + ": " + str(result.get("message")))
					client_alive = false
				else:
					oauth = result.get("access_token")
					refresh_token = result.get("refresh_token")
					print("Auth time: " + str(result.get("expires_in")))
					save_ini(false)
					for c in channels.values():
						c.api.headers = [
								"Authorization: Bearer " + oauth,
								"Client-Id: " + client_id,
						]
					http_client.close()
					return
			HTTPClient.STATUS_CONNECTION_ERROR:
				print("Connection Error")
				http_client.close()
				await get_tree().physics_frame
				http_client.connect_to_host("https://id.twitch.tv")
				http_client.poll()
			HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
				client_alive = false
				print("TLS Handshake Error")
			_:
				pass
	auth_token_expired.emit()
	pass
