extends Panel

var chats = {}


onready var bot : TwitchBot = $Bot
onready var connectButton := $MarginContainer/VBox/HBox/Connect
onready var channelName := $MarginContainer/VBox/HBox/HBox/LineEdit
onready var joinButton := $MarginContainer/VBox/HBox/HBox/Join
onready var tabs := $MarginContainer/VBox/TabContainer
onready var configMenu := $ConfigureDialog

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_Connect_pressed() -> void:
	connectButton.disabled = true
	if not bot.connected:
		var err = bot.connect_to_twitch()
		if err:
			print("Connection failed")
	else:
		bot.disconnect_from_twitch()
	pass # Replace with function body.


func _on_Join_pressed() -> void:
	if not channelName.text.empty() and not channelName.text in bot.connected_channels:
		bot.join_channel(channelName.text)
		joinButton.disabled = true
		channelName.text = ""
	pass # Replace with function body.


func _on_LineEdit_text_changed(new_text: String) -> void:
	joinButton.disabled = not bot.connected or (new_text.empty() or new_text.to_lower() in bot.connected_channels)
	pass # Replace with function body.


func _on_Bot_joined_channel(channel) -> void:
	if not channel in chats.keys():
		var chat = load("res://src/chat/ChatWindow.tscn").instance()
		tabs.add_child(chat)
		chat.connect("send_button_pressed", self, "_on_Chat_send_button_pressed")
		chat.connect("part_requested", self, "_on_Chat_part_requested")
		chat.connect("join_requested", self, "_on_Chat_join_requested")
		chat.name = channel
		chat.botLabel.text = bot.display_name
		chat.bot_name = bot.display_name
		chat.bot_color = bot.chat_color
		chat.bot_id = bot.bot_id
		chat.join_message = bot.join_message
		chats[channel] = chat
	var label = Label.new()
	label.text = "Joined channel."
	chats[channel].chat.add_child(label)
	chats[channel].partButton.text = "Part Channel"
	chats[channel].commandManager = bot.commandManagers[channel]
	chats[channel].load_ini()
	if not chats[channel].join_message.empty():
		bot.chat(channel, chats[channel].join_message)
	pass # Replace with function body.


func _on_Bot_parted_channel(channel) -> void:
	if chats.has(channel):
		var label = Label.new()
		label.text = "Parted channel."
		chats[channel].save_ini()
		chats[channel].chat.add_child(label)
		chats[channel].partButton.text = "Rejoin"
	pass # Replace with function body.


func _on_Bot_chat_message_received(message, channel) -> void:
	if chats.has(channel):
		chats[channel].add_message(message)
	pass # Replace with function body.


func _on_Bot_chat_message_send(message, channel, reply_id = "") -> void:
	if chats.has(channel):
		chats[channel].add_bot_message(message, reply_id)
	pass # Replace with function body.


func _on_Chat_send_button_pressed(message, channel, reply_id = "") -> void:
	bot.chat(channel, message, reply_id)


func _on_Chat_part_requested(channel) -> void:
	bot.part_channel(channel)


func _on_Chat_join_requested(channel) -> void:
	bot.join_channel(channel)


func _on_Bot_connected() -> void:
	connectButton.disabled = false
	connectButton.text = "Disconnect"
	pass # Replace with function body.


func _on_Bot_disconnected() -> void:
	joinButton.disabled = true
	connectButton.disabled = false
	connectButton.text = "Connect to Twitch"
	pass # Replace with function body.


func _on_ConfigureDialog_about_to_show() -> void:
	configMenu.read_only = bot.read_only
	configMenu.bot_name = bot.bot_name
	configMenu.oauth = bot.oauth
	configMenu.protocol = bot.connection_method
	configMenu.channels = bot.channels
	configMenu.join_message = bot.join_message
	configMenu.clientID = bot.client_id
	configMenu.update_data()
	pass # Replace with function body.


func _on_ConfigureDialog_popup_hide() -> void:
	var config = ConfigFile.new()
	config.set_value("auth", "bot_name", configMenu.bot_name)
	config.set_value("auth", "oauth", configMenu.oauth)
	config.set_value("auth", "protocol", bot.ConnectionMethod.keys()[configMenu.protocol])
	config.set_value("auth", "read_only", configMenu.read_only)
	bot.channels = configMenu.channels
	config.set_value("channels", "channels", Array(configMenu.channels))
	bot.join_message = configMenu.join_message
	config.set_value("channels", "join_message", configMenu.join_message)
	config.set_value("twitch", "client_id", configMenu.clientID)
	config.save("user://config.ini")
	config.clear()
	if not bot.connected:
		bot.load_ini()
	pass # Replace with function body.


func _on_Config_pressed() -> void:
	configMenu.popup_centered(Vector2(600, 400))
	pass # Replace with function body.


func _on_Bot_userstate_received(tags, channel) -> void:
	chats[channel].bot_color = tags.get("color", "#ffffff")
	chats[channel].bot_name = tags.get("display-name", "")
	chats[channel].is_mod = tags.get("mod", 0)
	if chats[channel].lastBotMessage:
		chats[channel].lastBotMessage.id = tags.get("id", "")
	pass # Replace with function body.


func _on_Bot_roomstate_received(tags, channel) -> void:
	chats[channel].room_id = tags.get("room-id", "")
	pass # Replace with function body.


func _on_Bot_chat_message_deleted(id, channel) -> void:
	var message: Control = chats[channel].get_message_by_id(id)
	if message:
		message.call_deferred("free")
		chats[channel].scroll.scroll_vertical -= message.rect_size.y
	pass # Replace with function body.


func _on_Bot_user_messages_deleted(id, channel) -> void:
	var messages = chats[channel].get_messages_by_user_id(id)
	for msg in messages:
		msg.call_defferred("free")
		chats[channel].scroll.scroll_vertical -= msg.rect_size.y
	pass # Replace with function body.


func _on_ban_user_requested(channel, id) -> void:
	pass


func _on_timeout_user_requested(channel, id, length) -> void:
	pass


func _on_delete_message_requested(channel, id) -> void:
	pass
