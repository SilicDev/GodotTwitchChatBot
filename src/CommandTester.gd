extends Node


@export var oauth: String = ""
@export var client_id: String = ""


var test = preload("res://addons/godot_twitch_bot/util/TwitchAPI.gd").new()
var messageParser = preload("res://addons/godot_twitch_bot/util/IRCMessageParser.gd")


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## These should authenticate the application you program
	## Never share your OAuth key on stream or otherwise
	test.headers = [
		"Authorization: Bearer " + oauth,
		"Client-Id: " + client_id,
	]
	await test.connect_to_twitch()
#	var manager = ManagerMock.new(test)
#	## Create new command object
#	var cmd: Command #= preload("res://addons/godot_twitch_bot/commands/YourCommand.gd").new()
#	## Add manager if requested
#	if "manager" in cmd:
#		cmd.manager = manager
#	## Create message
#	var msg = create_mock_message("!settitle params")
#	## test command
#	if cmd.should_fire(msg):
#		print(manager.formatter.format_message(cmd.get_response(msg), msg))
	var users = await test.get_users_by_name(["orbot_sa_55"])
	var orbot
	for d in users.data:
		if d.login == "orbot_sa_55":
			orbot = d
	print(await test.update_user_chat_color(orbot.id, " "))


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
			str(Time.get_unix_time_from_system()) + ";turbo=0;" + "user-id=0;user-type= :" + login + "!" + login + \
			"@" + login + ".tmi.twitch.tv PRIVMSG #" + channel + " :" + \
			message
	return messageParser.parse_message(msg)


## Simplified interface of the CommandManager class
class ManagerMock:
	var channel_id := ""
	var counters := {}
	var formatter = load("res://addons/godot_twitch_bot/util/MessageFormater.gd").new()
	
	func _init(api):
		formatter.counterManager = self
		formatter.api = api
