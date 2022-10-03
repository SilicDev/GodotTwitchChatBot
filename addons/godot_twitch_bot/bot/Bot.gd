class_name TwitchBot, "res://addons/godot_twitch_bot/assets/icon.png"
extends Node


signal joined_channel(channel)
signal parted_channel(channel)
signal connected()
signal disconnected()
signal chat_message_received(message, channel)
signal chat_message_send(message, channel, reply_id)
signal userstate_received(tags, channel)
signal roomstate_received(tags, channel)
signal command_fired(cmd, params)
signal chat_message_deleted(id, channel)
signal user_messages_deleted(id, channel)
signal pinged()


enum ConnectionMethod {
	WEBSOCKET,
	TCP,
}


var channels := PoolStringArray([])
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

var connected_channels := PoolStringArray([])
var commandManagers := {}

var config := ConfigFile.new()

var messageParser = load("res://addons/godot_twitch_bot/util/IRCMessageParser.gd")
var commandManagerScript = load("res://addons/godot_twitch_bot/commands/util/CommandManager.gd")
var api := preload("res://addons/godot_twitch_bot/util/TwitchAPI.gd").new()


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_ini()
	api.headers = [
		"Authorization: Bearer " + oauth,
		"Client-Id: " + client_id,
	]


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
							trigger_commands(c, parsedMessage)
						
						"PING":
							emit_signal("pinged")
							send("PONG :" + parameters)
						
						"001":
							print("Successfully authorized!")
							for cnl in channels:
								join_channel(cnl)
						
						"JOIN":
							if is_sender_self(parsedMessage) or read_only:
								print("joined " + commandDict.channel)
								connected_channels.append(c)
								commandManagers[c] = commandManagerScript.new(c)
								emit_signal("joined_channel", c)
						
						"PART":
							if (is_sender_self(parsedMessage) and c in connected_channels) \
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
		if connection.status == Connection.Status.ERROR:
			push_warning("Lost Connection")
			disconnect_from_twitch()
			OS.request_attention()
		
		if connection.status == Connection.Status.DISCONNECTED and connected:
			push_warning("Lost Connection")
			OS.request_attention()
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
	for c in connected_channels:
		part_channel(c)
	connection.disconnect_from_host()
	connected = false
	emit_signal("disconnected")
	print("Disconnected")


func join_channel(channel: String) -> void:
	if not channel in connected_channels:
		send("JOIN #" + channel.to_lower())


func part_channel(channel: String) -> void:
	var c := channel.to_lower()
	if c.begins_with("#"):
		c = c.substr(1)
	send("PART #" + c)
	commandManagers[c].save_data()
	connected_channels.remove(connected_channels.find(c))
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
	channels = config.get_value("channels", "channels", [])
	join_message = config.get_value("channels", "join_message", "")
	client_id = config.get_value("twitch", "client_id", "")
	
	config.clear()


func save_ini() -> void:
	config.set_value("auth", "bot_name", bot_name)
	config.set_value("auth", "oauth", oauth)
	config.set_value("auth", "protocol", ConnectionMethod.keys()[connection_method])
	config.set_value("auth", "read_only", read_only)
	config.set_value("channels", "channels", Array(channels))
	config.set_value("channels", "join_message", join_message)
	config.set_value("twitch", "client_id", client_id)
	
	var path = "user://config.ini"
	var file := File.new()
	var dir := Directory.new()
	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())
	
	config.save(path)
	config.clear()


func trigger_commands(channel: String, parsedMessage: Dictionary) -> void:
	var c := channel.to_lower()
	if c.begins_with("#"):
		c = c.substr(1)
	
	var commandDict = parsedMessage.command
	if c in commandManagers.keys():
		var cmd : String = commandManagers[c].test_commands(parsedMessage)
		if not cmd.empty():
			var resp : String = commandManagers[c].get_response(cmd, parsedMessage)
			var params : PoolStringArray = commandDict.get("botCommandParams", "").split(" ")
			emit_signal("command_fired", cmd, params)
			if not resp.empty():
				chat(c, resp)


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
	return parsedMessage.get("source", {}).get("nick", "")
