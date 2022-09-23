extends Panel


onready var bot : TwitchBot = $Bot
onready var connectButton := $MarginContainer/VBox/HBox/Connect
onready var channelName := $MarginContainer/VBox/HBox/HBox/LineEdit
onready var joinButton := $MarginContainer/VBox/HBox/HBox/Join
onready var tabs := $MarginContainer/VBox/TabContainer

var chats = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_Connect_pressed() -> void:
	var err = bot.connect_to_twitch()
	if err:
		print("Connection failed")
	else:
		connectButton.disabled = true
		joinButton.disabled = false
	pass # Replace with function body.


func _on_Join_pressed() -> void:
	if not channelName.text.empty() and not channelName.text in bot.connected_channels:
		bot.join_channel(channelName.text)
		joinButton.disabled = true
		channelName.text = ""
	pass # Replace with function body.


func _on_LineEdit_text_changed(new_text: String) -> void:
	joinButton.disabled = new_text.empty() or new_text.to_lower() in bot.connected_channels
	pass # Replace with function body.


func _on_Bot_joined_channel(channel) -> void:
	if not channel in chats.keys():
		var chat = load("res://src/ChatWindow.tscn").instance()
		tabs.add_child(chat)
		chat.connect("on_send_button_pressed", self, "_on_Chat_send_button_pressed")
		chat.name = channel
		chat.botLabel.text = bot.bot_name
		chats[channel] = chat
		chats.chat.append_bbcode("[i]Joined channel.[/i]\n")
	pass # Replace with function body.


func _on_Bot_parted_channel(channel) -> void:
	if chats.has(channel):
		chats.chat.append_bbcode("[i]Parted channel.[/i]\n")
	pass # Replace with function body.


func _on_Bot_chat_message_received(message, channel) -> void:
	if chats.has(channel):
		chats[channel].add_message(message)
	pass # Replace with function body.


func _on_Bot_chat_message_send(message, channel) -> void:
	if chats.has(channel):
		chats[channel].add_bot_message(message)
	pass # Replace with function body.


func _on_Chat_send_button_pressed(message, channel) -> void:
	bot.chat(channel, message)


func _on_Chat_part_requested(channel) -> void:
	bot.part_channel(channel)
