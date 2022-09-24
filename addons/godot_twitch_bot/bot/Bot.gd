class_name TwitchBot
extends Node


signal joined_channel(channel)
signal parted_channel(channel)
signal connected()
signal disconnected()
signal chat_message_received(message, channel)
signal chat_message_send(message, channel)
signal userstate_received(tags, channel)
signal roomstate_received(tags, channel)
signal pinged()


enum ConnectionMethod {
	TCP,
	WEBSOCKET,
}


export(PoolStringArray) var channels := PoolStringArray([])
export(String) var bot_name := ""
export(String, MULTILINE) var join_message := ""

var connection : Connection

var oauth := ""
var client_id := ""

var connection_method = ConnectionMethod.TCP

var display_name := ""
var chat_color := ""

var running = false
var connected = false
var close_requested = false

var read_only := true
var request_membership := true

var connected_channels := PoolStringArray([])
var commandManagers := {}

var config := ConfigFile.new()

var messageParser = load("res://addons/godot_twitch_bot/util/IRCMessageParser.gd")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_ini()
	#connect_to_twitch()
	running = true
	pass # Replace with function body.


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		if connected:
			disconnect_from_twitch()
		save_ini()

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
					print("> " + msg)
				var parsedMessage = messageParser.parse_message(msg)
				if parsedMessage:
					var c := ""
					if parsedMessage.command.has("channel"):
						c = parsedMessage.command.channel
						if c.begins_with("#"):
							c = c.substr(1)
					match parsedMessage.command.command:
						"PRIVMSG":
							emit_signal("chat_message_received", parsedMessage, c)
							if c in commandManagers.keys():
								var cmd : String = commandManagers[c].test_commands(parsedMessage)
								if not cmd.empty():
									chat(c, commandManagers[c].get_response(cmd))
						"PING":
							emit_signal("pinged")
							send("PONG :" + parsedMessage.parameters)
						"001":
							print("Successfully authorized!")
							for cnl in channels:
								join_channel(cnl)
						"JOIN":
							if parsedMessage.source.nick == bot_name or read_only:
								print("joined " + parsedMessage.command.channel)
								connected_channels.append(c)
								commandManagers[c] = load("res://addons/godot_twitch_bot/commands/util/CommandManager.gd").new(c)
								emit_signal("joined_channel", c)
								if not join_message.empty():
									chat(parsedMessage.command.channel, join_message)
							pass
						"PART":
							if (parsedMessage.source.nick == bot_name and c in connected_channels) or read_only:
								push_warning("The stream must have banned (/ban) the bot!")
								part_channel(parsedMessage.command.channel)
						"NOTICE":
							# If the authentication failed, leave the channel.
							# The server will close the connection.
							if "Login authentication failed" == parsedMessage.parameters:
								push_error("Authentication failed; left " + str(channels))
								for cnl in channels:
									part_channel(cnl)
							elif "You don’t have permission to perform that action" == parsedMessage.parameters:
								push_error("No permission. Check if the access token is still valid. Left " + str(channels))
								for cnl in channels:
									part_channel(cnl)
						"GLOBALUSERSTATE":
							display_name = parsedMessage.tags["display-name"]
							chat_color = parsedMessage.tags["color"]
						"USERSTATE":
							emit_signal("userstate_received", parsedMessage.tags, c)
						"ROOMSTATE":
							emit_signal("roomstate_received", parsedMessage.tags, c)
	
	elif connection.status == Connection.Status.DISCONNECTED and connected:
		push_warning("Lost Connection")
		connected = false
	pass


func connect_to_twitch() -> int:
	if connection_method == ConnectionMethod.TCP:
		print("Connecting via TCP...")
		connection = preload("res://addons/godot_twitch_bot/network/TCPConnection.gd").new()
	elif connection_method == ConnectionMethod.WEBSOCKET:
		print("Connecting via WebSocket...")
		connection = preload("res://addons/godot_twitch_bot/network/WSConnection.gd").new()
	var err := connection.connect_to_host()
	if not err:
		emit_signal("connected")
		print("Connected")
	else:
		connected = false
	return err


func disconnect_from_twitch() -> void:
	for c in channels:
		part_channel(c)
	connection.disconnect_from_host()
	connected = false
	emit_signal("disconnected")
	print("Disconnected")


func join_channel(channel: String) -> void:
	if not channel in connected_channels:
		send("JOIN #" + channel.to_lower())


func part_channel(channel: String) -> void:
	var c := channel
	if c.begins_with("#"):
		c = c.substr(1)
	send("PART #" + c)
	connected_channels.remove(connected_channels.find(c))
	emit_signal("parted_channel", c)


func chat(channel: String, msg: String) -> void:
	if not read_only:
		var c := channel
		if c.begins_with("#"):
			c = c.substr(1)
		# TODO: check if roomstate allows message to be sent
		send("PRIVMSG #" + c + " :" + msg)
		emit_signal("chat_message_send", msg, c)


func send(msg: String) -> void:
	if not connection:
		push_warning("Must be connected to send messages!")
		return
	connection.send(msg)


func load_ini() -> void:
	var err := config.load("user://config.ini")
	if err:
		save_ini()
	bot_name = config.get_value("auth", "bot_name", "")
	oauth = config.get_value("auth", "oauth", "")
	client_id = config.get_value("auth", "client_id", "")
	var protocol = config.get_value("auth", "protocol", "TCP").to_upper()
	if protocol in ConnectionMethod.keys():
		connection_method = ConnectionMethod[protocol]
	else:
		connection_method = ConnectionMethod.TCP
	channels = config.get_value("channels", "channels", [])
	join_message = config.get_value("channels", "join_message", "")
	pass


# oauth can only be set manually
func save_ini() -> void:
	config.set_value("auth", "bot_name", bot_name)
	config.set_value("auth", "oauth", oauth)
	config.set_value("auth", "client_id", client_id)
	config.set_value("auth", "protocol", ConnectionMethod.keys()[connection_method])
	config.set_value("channels", "channels", Array(channels))
	config.set_value("channels", "join_message", join_message)
	config.save("user://config.ini")
	pass
