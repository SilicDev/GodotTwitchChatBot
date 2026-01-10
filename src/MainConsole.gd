extends Panel


const chatWindowScene := preload("res://src/chat/ChatWindow.tscn")


var chats = {}

var active_threads := []


@onready var bot : TwitchBot = $Bot

@onready var connectButton := $MarginContainer/VBox/HBox/Connect
@onready var channelName := $MarginContainer/VBox/HBox/HBox/LineEdit
@onready var joinButton := $MarginContainer/VBox/HBox/HBox/Join

@onready var tabs := $MarginContainer/VBox/TabContainer

@onready var configMenu := $ConfigureDialog


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var valid_token = await validate_token()
	if not valid_token:
		bot.on_API_authentication_failed()
	pass


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func cleanup_threads() -> void:
	var temp = []
	for t in active_threads:
		if not t.is_alive():
			print(t.get_id(), ": ", t.wait_to_finish())
			temp.append(t)
	for t in temp:
		active_threads.erase(t)
	temp.clear()


func ban_user(arguments: Dictionary) -> void:
	bot.get_channel_by_id(arguments.get("broadcaster_id", "")).api.ban_user(
		arguments.get("broadcaster_id", ""), 
		arguments.get("moderator_id", ""), 
		arguments.get("user_id", "")
	)


func timeout_user(arguments: Dictionary) -> void:
	bot.get_channel_by_id(arguments.get("broadcaster_id", "")).api.ban_user(
		arguments.get("broadcaster_id", ""), 
		arguments.get("moderator_id", ""), 
		arguments.get("user_id", ""),
		"", arguments.get("duration", 600)
	)


func delete_message(arguments: Dictionary) -> void:
	bot.get_channel_by_id(arguments.get("broadcaster_id", "")).api.delete_chat_messages(
		arguments.get("broadcaster_id", ""), 
		arguments.get("moderator_id", ""), 
		arguments.get("msg_id", "")
	)


func validate_token() -> bool:
	var url = "/oauth2/validate"
	var headers = [
		"Authorization: OAuth " + bot.oauth, 
	]
	var http_client = HTTPClient.new()
	http_client.connect_to_host("https://id.twitch.tv")
	http_client.poll()
	var client_alive = true
	var request_timeout = 0
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
					var err := http_client.request(HTTPClient.METHOD_GET, url, headers)
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
					return false
				else:
					return true
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
	return false


func _on_Connect_pressed() -> void:
	connectButton.disabled = true
	if not bot.connected_to_twitch:
		var err = bot.connect_to_twitch()
		if err:
			print("Connection failed")
	else:
		bot.disconnect_from_twitch()


func _on_Join_pressed() -> void:
	if not channelName.text.is_empty() and not bot.is_connected_to_channel(channelName.text):
		bot.join_channel(channelName.text)
		joinButton.disabled = true
		channelName.text = ""


func _on_LineEdit_text_changed(new_text: String) -> void:
	var invalid_channel := (new_text.is_empty() or bot.is_connected_to_channel(new_text))
	joinButton.disabled = not bot.connected_to_twitch or invalid_channel


func _on_LineEdit_text_submitted(_new_text: String) -> void:
	_on_Join_pressed()
	pass # Replace with function body.


func _on_Bot_joined_channel(channel) -> void:
	if not channel in chats.keys():
		var chat = chatWindowScene.instantiate()
		tabs.add_child(chat)
		
		chat.connect("send_button_pressed", _on_Chat_send_button_pressed)
		chat.connect("part_requested", _on_Chat_part_requested)
		chat.connect("join_requested", _on_Chat_join_requested)
		
		chat.connect("ban_user_requested", _on_Chat_ban_user_requested)
		chat.connect("timeout_user_requested", _on_Chat_timeout_user_requested)
		chat.connect("delete_message_requested", _on_Chat_delete_message_requested)
		
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
	
	chats[channel].channelInstance = bot.channels[channel]
	chats[channel].channelInstance.api.headers = [
		"Authorization: Bearer " + bot.oauth,
		"Client-Id: " + bot.client_id,
	]
	var t = Thread.new()
	active_threads.append(t)
	t.start(chats[channel].channelInstance.api.connect_to_twitch)
	print("Thread started: ", t.get_id())
	
	chats[channel].load_ini()
	
	if not chats[channel].join_message.is_empty():
		bot.chat(channel, chats[channel].join_message)


func _on_Bot_parted_channel(channel) -> void:
	cleanup_threads()
	if chats.has(channel):
		var label = Label.new()
		label.text = "Parted channel."
		chats[channel].save_ini()
		chats[channel].chat.add_child(label)
		chats[channel].partButton.text = "Rejoin"
		chats[channel].channelInstance.api.disconnect_from_twitch()


func _on_Bot_chat_message_received(message, channel) -> void:
	cleanup_threads()
	if chats.has(channel):
		chats[channel].add_message(message)


func _on_Bot_chat_message_send(message, channel, reply_id = "") -> void:
	if chats.has(channel):
		chats[channel].add_bot_message(message, reply_id)


func _on_Chat_send_button_pressed(message, channel, reply_id = "") -> void:
	bot.chat(channel, message, reply_id)


func _on_Chat_part_requested(channel) -> void:
	bot.part_channel(channel)


func _on_Chat_join_requested(channel) -> void:
	bot.join_channel(channel)


func _on_Bot_connected() -> void:
	connectButton.disabled = false
	connectButton.text = "Disconnect"


func _on_Bot_disconnected() -> void:
	joinButton.disabled = true
	connectButton.disabled = false
	connectButton.text = "Connect to Twitch"
	cleanup_threads()


func _on_ConfigureDialog_about_to_show() -> void:
	configMenu.read_only = bot.read_only
	configMenu.bot_name = bot.bot_name
	configMenu.oauth = bot.oauth
	configMenu.refresh_token = bot.refresh_token
	configMenu.protocol = bot.connection_method
	
	configMenu.channels = bot.default_channels
	configMenu.join_message = bot.join_message
	
	configMenu.clientID = bot.client_id
	configMenu.update_data()


func _on_ConfigureDialog_popup_hide() -> void:
	var config = ConfigFile.new()
	config.set_value("auth", "bot_name", configMenu.bot_name)
	config.set_value("auth", "oauth", configMenu.oauth)
	config.set_value("auth", "refresh", configMenu.refresh_token)
	config.set_value("auth", "protocol", bot.ConnectionMethod.keys()[configMenu.protocol])
	config.set_value("auth", "read_only", configMenu.read_only)
	
	bot.default_channels = configMenu.channels
	config.set_value("channels", "channels", Array(configMenu.channels))
	
	bot.join_message = configMenu.join_message
	config.set_value("channels", "join_message", configMenu.join_message)
	
	config.set_value("twitch", "client_id", configMenu.clientID)
	
	config.save("user://config.ini")
	config.clear()
	
	if not bot.connected_to_twitch:
		bot.load_ini()


func _on_Config_pressed() -> void:
	configMenu.popup_centered(Vector2(600, 400))


func _on_Bot_userstate_received(tags, channel) -> void:
	chats[channel].bot_color = tags.get("color", "#ffffff")
	chats[channel].bot_name = tags.get("display-name", "")
	chats[channel].is_mod = tags.get("mod", "0") == "1"
	
	if chats[channel].lastBotMessage:
		chats[channel].lastBotMessage.id = tags.get("id", "")


func _on_Bot_roomstate_received(tags, channel) -> void:
	chats[channel].room_id = tags.get("room-id", "")
	chats[channel].channelInstance.channel_id = chats[channel].room_id


func _on_Bot_chat_message_deleted(id, channel) -> void:
	var message: Control = chats[channel].get_message_by_id(id)
	if message:
		message.call_deferred("free")
		chats[channel].scroll.scroll_vertical -= message.size.y


func _on_Bot_user_messages_deleted(id, channel) -> void:
	var messages = chats[channel].get_messages_by_user_id(id)
	for msg in messages:
		msg.call_deferred("free")
		chats[channel].scroll.scroll_vertical -= msg.size.y


func _on_Chat_ban_user_requested(channel, id) -> void:
	cleanup_threads()
	var t = Thread.new()
	var args = {
		"broadcaster_id" : chats[channel].room_id,
		"moderator_id" : bot.bot_id,
		"user_id" : id,
	}
	t.start(ban_user.bind(args))


func _on_Chat_timeout_user_requested(channel, id, length) -> void:
	cleanup_threads()
	var t = Thread.new()
	active_threads.append(t)
	var args = {
		"broadcaster_id" : chats[channel].room_id,
		"moderator_id" : bot.bot_id,
		"user_id" : id,
		"duration": length
	}
	t.start(timeout_user.bind(args))


func _on_Chat_delete_message_requested(channel, id) -> void:
	cleanup_threads()
	var t = Thread.new()
	active_threads.append(t)
	var args = {
		"broadcaster_id" : chats[channel].room_id,
		"moderator_id" : bot.bot_id,
		"msg_id" : id,
	}
	t.start(delete_message.bind(args))


func _on_Bot_command_fired(_cmd, _params, _channel):
	pass # Replace with function body.


func _on_Bot_pinged():
	pass # Replace with function body.


func _on_bot_auth_token_expired() -> void:
	configMenu.request_device_code()
	pass # Replace with function body.
