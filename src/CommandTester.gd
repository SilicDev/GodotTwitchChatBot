extends Node


export(String) var oauth = ""
export(String) var client_id = ""


var test = preload("res://addons/godot_twitch_bot/util/TwitchAPI.gd").new()
var messageParser = preload("res://addons/godot_twitch_bot/util/IRCMessageParser.gd")


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## These should authenticate the application you program
	## Never share your OAuth key on stream or otherwise
	test.headers.append_array([
		"Authorization: Bearer " + oauth,
		"Client-Id: " + client_id,
	])
	var manager = ManagerMock.new()
	## Create new command object
	var cmd: Command #= preload("res://addons/godot_twitch_bot/commands/YourCommand.gd").new()
	## Add manager if requested
	if "manager" in cmd:
		cmd.manager = manager
	## Create message
	var msg = create_mock_message("!settitle params")
	## test command
	if cmd.should_fire(msg):
		print(manager.formatter.format_message(cmd.get_response(msg), "broadcaster", msg))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


## Generates a parsed message with the user being treated as broadcaster of the channel
## Message should match a valid usage of your command
func create_mock_message(
		message: String, 
		sender := "User", 
		channel := "broadcaster", 
		room_id := "0"
) -> Dictionary:
	var login := sender.to_lower()
	var msg := "@badge-info=;badges=broadcaster/1;client-nonce=ffffffffffffffffffffffffffffffff;color=;" + \
			"display-name=" + sender + ";emotes=;first-msg=0;flags=;id=ffffffff-ffff-ffff-ffff-ffffffffffff;" + \
			"mod=0;returning-chatter=0;room-id=" + room_id + ";subscriber=0;tmi-sent-ts=" + \
			str(OS.get_unix_time()) + ";turbo=0;" + "user-id=0;user-type= :" + login + "!" + login + \
			"@" + login + ".tmi.twitch.tv PRIVMSG #" + channel + " :" + \
			message
	return messageParser.parse_message(msg)


## Simplified interface of the CommandManager class
class ManagerMock:
	var channel_id := ""
	var api := TwitchAPI.new()
	var formatter = load("res://addons/godot_twitch_bot/commands/util/MessageFormater.gd").new()
	
	func _init() -> void:
		formatter.manager = self
