extends Panel


onready var bot := $Bot
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
	pass # Replace with function body.


func _on_LineEdit_text_changed(new_text: String) -> void:
	joinButton.disabled = new_text.empty() or new_text.to_lower() in bot.connected_channels
	pass # Replace with function body.


func _on_Bot_joined_channel(channel) -> void:
	if not channel in chats.keys():
		var chat = RichTextLabel.new() # Replace with a chat window
		chat.bbcode_enabled = true
		tabs.add_child(chat)
		chat.name = channel
		chats[channel] = chat
	pass # Replace with function body.


func _on_Bot_parted_channel(channel) -> void:
	if chats.has(channel):
		chats.erase(chats[channel])
	pass # Replace with function body.


func _on_Bot_chat_message_received(message, channel) -> void:
	if chats.has(channel):
		chats[channel].append_bbcode("[b][color=" + message.tags.color + "]" + message.tags["display-name"] + "[/color][/b]: " + message.parameters + "\n")
		
	pass # Replace with function body.


func _on_Bot_chat_message_send(message, channel) -> void:
	if chats.has(channel):
		chats[channel].append_bbcode("[b]" + bot.bot_name + "[/b]: " + message + "\n")
	pass # Replace with function body.
