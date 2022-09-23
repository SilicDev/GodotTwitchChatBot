class_name TwitchBot
extends Node


signal joined_channel(channel)
signal parted_channel(channel)
signal chat_message_received(message, channel)
signal chat_message_send(message, channel)
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

var connected_channels := PoolStringArray([])
var commands := []

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
			for c in channels:
				part_channel(c)
			connection.disconnect_from_host()
			print("Disconnected")
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
			send("CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands")
			send("PASS oauth:" + oauth)
			send("NICK " + bot_name)
		if connection.has_message():
			var messages := connection.receive().split("\r\n")
			for msg in messages:
				if OS.is_debug_build():
					print("> " + msg)
				var parsedMessage = messageParser.parse_message(msg)
				if parsedMessage:
					match parsedMessage.command.command:
						"PRIVMSG":
							emit_signal("chat_message_received", parsedMessage, parsedMessage.command.channel.substr(1))
							for c in commands:
								if c.should_fire(parsedMessage):
									chat(parsedMessage.command.channel, c.get_response())
									break
							pass
						"PING":
							emit_signal("pinged")
							send("PONG :" + parsedMessage.parameters)
						"001":
							print("Successfully authorized!")
							for c in channels:
								join_channel(c)
						"JOIN":
							print("joined " + parsedMessage.command.channel)
							var c : String = parsedMessage.command.channel
							if c.begins_with("#"):
								c = c.substr(1)
							connected_channels.append(c)
							emit_signal("joined_channel", c)
							if not join_message.empty():
								chat(parsedMessage.command.channel, join_message)
							pass
						"PART":
							var c : String = parsedMessage.command.channel
							if c.begins_with("#"):
								c = c.substr(1)
							if parsedMessage.source.nick == bot_name and c in connected_channels:
								push_warning("The stream must have banned (/ban) the bot!")
								part_channel(parsedMessage.command.channel)
						"NOTICE":
							# If the authentication failed, leave the channel.
							# The server will close the connection.
							if "Login authentication failed" == parsedMessage.parameters:
								push_error("Authentication failed; left " + str(channels))
								for c in channels:
									part_channel(c)
							elif "You don’t have permission to perform that action" == parsedMessage.parameters:
								push_error("No permission. Check if the access token is still valid. Left " + str(channels))
								for c in channels:
									part_channel(c)
						"GLOBALUSERSTATE":
							display_name = parsedMessage.tags["display-name"]
							chat_color = parsedMessage.tags["color"]
	
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
		print("Connected")
	else:
		connected = false
	return err


func join_channel(channel: String) -> void:
	if not channel in connected_channels:
		send("JOIN #" + channel.to_lower())


func part_channel(channel: String) -> void:
	var c := channel
	if c.begins_with("#"):
		c = c.substr(1)
	send("PART #" + c)
	connected_channels.remove(connected_channels.find(c))
	print(connected_channels)
	emit_signal("parted_channel", c)


func chat(channel: String, msg: String) -> void:
	var c := channel
	if c.begins_with("#"):
		c = c.substr(1)
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
