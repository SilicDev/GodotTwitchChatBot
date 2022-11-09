class_name TwitchBot, "res://addons/godot_twitch_bot/assets/icon.png"
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


enum ConnectionMethod {
	WEBSOCKET,
	TCP,
}


var bot_name := ""
var join_message := ""

var connection : Connection
var connection_method = ConnectionMethod.WEBSOCKET

var oauth := ""
var client_id := ""

var display_name := ""
var chat_color := ""
var bot_id := ""

var connected = false

var read_only := false
var request_membership := true

var default_channels := []
var channels := {}

var active_threads := []

var config := ConfigFile.new()

var messageParser = preload("res://addons/godot_twitch_bot/util/IRCMessageParser.gd")
var channelManagerScript = preload("res://addons/godot_twitch_bot/bot/Channel.gd")


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_ini()


func _notification(what: int) -> void:
	## Handle quiting gracefully
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		if connected:
			disconnect_from_twitch()
		save_ini()


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not connection:
		return
	connection.update()
	
	if connection.status == Connection.Status.CONNECTED:
		
		if not connected:
			connected = true
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
				if OS.is_debug_build():
					if not msg.empty():
						print("> " + msg)
				
				var parsedMessage = messageParser.parse_message(msg)
				if parsedMessage:
					var commandDict = parsedMessage.get("command", {})
					var parameters = parsedMessage.get("parameters", "")
					var tags = parsedMessage.get("tags", {})
					
					var c := ""
					c = commandDict.get("channel", "")
					if c.begins_with("#"):
						c = c.substr(1)
					
					match commandDict.get("command", ""):
						"PRIVMSG":
							emit_signal("chat_message_received", parsedMessage, c)
							channels[c].handle_message(parsedMessage)
						
						"PING":
							emit_signal("pinged")
							send("PONG :" + parameters)
						
						"001":
							print("Successfully authorized!")
							for cnl in default_channels:
								join_channel(cnl)
						
						"JOIN":
							if is_sender_self(parsedMessage) or read_only:
								print("joined " + commandDict.channel)
								if not c in channels.keys():
									channels[c] = channelManagerScript.new(c)
									channels[c].connect("command_fired", self, "_on_Channel_command_fired")
								channels[c].connected = true
								emit_signal("joined_channel", c)
						
						"PART":
							if (is_sender_self(parsedMessage) and channels[c].connected) \
									or read_only:
								send("JOIN #" + c.to_lower())
						
						"NOTICE":
							parse_notice(tags, parameters, c)
						
						"GLOBALUSERSTATE":
							display_name = tags.get("display-name", "")
							chat_color = tags.get("color", "#ffffff")
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
								emit_signal("chat_message_deleted", null, c)
		for c in channels.keys():
			if channels[c].connected and not channels[c].message_queue.empty():
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
			OS.request_attention()
			OS.move_window_to_foreground()
		
		if connection.status == Connection.Status.DISCONNECTED and connected:
			push_warning("Lost Connection")
			OS.request_attention()
			OS.move_window_to_foreground()
			connected = false


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
		connected = false
	return err


func disconnect_from_twitch() -> void:
	for c in channels.keys():
		part_channel(c)
	connection.disconnect_from_host()
	connected = false
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
		if not reply_id.empty():
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


func save_ini() -> void:
	config.set_value("auth", "bot_name", bot_name)
	config.set_value("auth", "oauth", oauth)
	config.set_value("auth", "protocol", ConnectionMethod.keys()[connection_method])
	config.set_value("auth", "read_only", read_only)
	config.set_value("channels", "channels", channels.keys())
	config.set_value("channels", "join_message", join_message)
	config.set_value("twitch", "client_id", client_id)
	
	var path = "user://config.ini"
	var file := File.new()
	var dir := Directory.new()
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


func parse_notice(tags: Dictionary, parameters: String, channel: String):
	var c := channel.to_lower()
	if c.begins_with("#"):
		c = c.substr(1)
	
	var msg_id = tags.get("msg-id", "")
	if msg_id.empty():
		## If the authentication failed, leave the channel.
		## The server will close the connection.
		if "Login authentication failed" == parameters or "Invalid NICK" == parameters:
			push_error("Authentication failed; left " + str(channels))
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


func is_sender_self(parsedMessage: Dictionary) -> bool:
	return parsedMessage.get("source", {}).get("nick", "") == bot_name


func _on_Channel_command_fired(cmd, parsedMessage, channel) -> void:
	emit_signal("command_fired", cmd, parsedMessage, channel)
