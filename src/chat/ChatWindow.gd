extends PanelContainer

signal send_button_pressed(msg, channel)
signal part_requested(channel)
signal join_requested(channel)

signal ban_user_requested(channel, id)
signal timeout_user_requested(channel, id, length)
signal delete_message_requested(channel, id)

var bot_color := ""
var bot_name := ""
var bot_id := ""
var room_id := ""

var is_mod := false

var reply_id := ""

var lastBotMessage

var commandManager

var join_message := ""

var config := ConfigFile.new()

onready var chat := $VBoxContainer/PanelContainer/Scroll/VBox
onready var scroll := $VBoxContainer/PanelContainer/Scroll
onready var partButton := $VBoxContainer/HBoxContainer/CenterContainer3/Part
onready var messageInput := $VBoxContainer/HBoxContainer/VBox/LineEdit
onready var botLabel := $VBoxContainer/HBoxContainer/Label
onready var replyBox := $VBoxContainer/HBoxContainer/VBox/HBox
onready var replyText := $VBoxContainer/HBoxContainer/VBox/HBox/Label
onready var configMenu := $ChannelConfigDialog


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func add_message(message: Dictionary) -> void:
	var msgPanel = load("res://src/chat/ChatMessage.tscn").instance()
	chat.add_child(msgPanel)
	set_data(msgPanel, message)
	msgPanel.connect("ban_user_requested", self, "_on_ban_user_requested")
	msgPanel.connect("timeout_user_requested", self, "_on_timeout_user_requested")
	msgPanel.connect("delete_message_requested", self, "_on_delete_message_requested")
	msgPanel.connect("reply_requested", self, "_on_reply_requested")
	pass


func set_data(msgPanel, message: Dictionary) -> void:
	var tags = message.get("tags", {})
	if tags.color:
		msgPanel.message.append_bbcode("[b][color=" + tags.get("color", "#ffffff") + "]" + tags.get("display-name", "Anonymous") + "[/color][/b]: " + message.parameters)
	else:
		msgPanel.message.append_bbcode("[b]" + tags.get("display-name", "Anonymous") + "[/b]: " + message.parameters)
	msgPanel.id = tags.get("id", "")
	msgPanel.sender = tags.get("display-name", "Anonymous")
	msgPanel.sender_id = tags.get("user-id", "")
	msgPanel.reply.visible = tags.has("reply-parent-user-id")
	msgPanel.reply_sender_id = tags.get("reply-parent-user-id", "")
	msgPanel.reply_id = tags.get("reply-parent-msg-id", "")
	if not msgPanel.reply_id.empty():
		var reply = get_message_by_id(msgPanel.reply_id)
		if reply:
			msgPanel.reply.text = tags.get("reply-parent-display-name", "Anonymous") + ": " + reply.parsedMessage.get("parameters", "")
	msgPanel.modButtons.visible = not (tags.get("display-name", "Anonymous").to_lower() == name or int(tags.get("mod", "0"))) and is_mod
	msgPanel.parsedMessage = message
	yield(get_tree(),"idle_frame")
	scroll.scroll_vertical += msgPanel.rect_size.y


func add_bot_message(message: String, reply_id := "") -> void:
	var msgPanel = load("res://src/chat/ChatMessage.tscn").instance()
	chat.add_child(msgPanel)
	msgPanel.sender = bot_name
	msgPanel.sender_id = bot_id
	msgPanel.modButtons.visible = false
	msgPanel.reply.visible = not reply_id.empty()
	msgPanel.replyContainer.visible = not reply_id.empty()
	msgPanel.parsedMessage = {
		"tags" : {
			"display-name": bot_name,
			"user-id": bot_id,
			"color": bot_color,
			"room-id": room_id,
		},
		"source" : {
			"nick" : bot_name,
		},
		"command" : {
			"command" : "PRIVMSG",
		},
		"parameters" : message,
	}
	if not reply_id.empty():
		msgPanel.reply_id = reply_id
		msgPanel.parsedMessage.tags["reply-parent-msg-id"] = reply_id
	var reply = get_message_by_id(reply_id)
	if reply:
		msgPanel.reply.text = reply.parsedMessage.get("tags", {}).get("display-name", "Anonymous") + ": " + reply.parsedMessage.get("parameters", "")
	if bot_color.empty():
		msgPanel.message.append_bbcode("[b]" + bot_name + "[/b]: " + message + "\n")
	else:
		msgPanel.message.append_bbcode("[b][color=" + bot_color + "]" + bot_name + "[/color][/b]: " + message)
	yield(get_tree(),"idle_frame")
	msgPanel.connect("ban_user_requested", self, "_on_ban_user_requested")
	msgPanel.connect("timeout_user_requested", self, "_on_timeout_user_requested")
	msgPanel.connect("delete_message_requested", self, "_on_delete_message_requested")
	msgPanel.connect("reply_requested", self, "_on_reply_requested")
	lastBotMessage = msgPanel
	scroll.scroll_vertical += msgPanel.rect_size.y


func get_message_by_id(msg_id: String):
	for c in chat.get_children():
		if c is PanelContainer:
			if c.id == msg_id:
				return c
	return null


func get_messages_by_user_id(user_id) -> Array:
	var out = []
	for c in chat.get_children():
		if c is PanelContainer:
			if c.sender_id == user_id:
				out.append(c)
	return out


func load_ini() -> void:
	var path := "user://channels/" + name.to_lower() + "/config.ini"
	var err := config.load(path)
	if err:
		save_ini()
		config.load(path)
	join_message = config.get_value("general", "join_message", join_message)
	config.clear()
	pass


func save_ini() -> void:
	config.set_value("general", "join_message", join_message)
	var path = "user://channels/" + name.to_lower() + "/config.ini"
	var file := File.new()
	var dir := Directory.new()
	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())
	config.save(path)
	config.clear()
	pass


func _on_Send_pressed() -> void:
	emit_signal("send_button_pressed", messageInput.text, name, reply_id)
	reply_id = ""
	replyBox.visible = false
	messageInput.text = ""
	pass # Replace with function body.


func _on_Part_pressed() -> void:
	if partButton.text == "Part Channel":
		emit_signal("part_requested", name)
		partButton.text = "Rejoin"
	else:
		emit_signal("join_requested", name)
		partButton.text = "Part Channel"
	pass # Replace with function body.


func _on_EndReply_pressed() -> void:
	replyBox.visible = false
	reply_id = ""
	pass # Replace with function body.


func _on_ban_user_requested(id) -> void:
	emit_signal("ban_user_requested", name, id)
	pass


func _on_timeout_user_requested(id, length) -> void:
	emit_signal("timeout_user_requested", name, id, length)
	pass


func _on_delete_message_requested(id) -> void:
	emit_signal("delete_message_requested", name, id)
	pass


func _on_reply_requested(id) -> void:
	var reply = get_message_by_id(id)
	if reply:
		reply_id = id
		replyBox.visible = true
		replyText.text = reply.parsedMessage.get("tags", {}).get("display-name", "Anonymous") + ": " + reply.parsedMessage.get("parameters", "")
	pass


func _on_Config_pressed() -> void:
	configMenu.popup_centered(Vector2(800, 400))
	pass # Replace with function body.


func _on_ChannelConfigDialog_about_to_show() -> void:
	load_ini()
	configMenu.commandManager = commandManager
	configMenu.join_message = join_message
	configMenu.load_data()
	pass # Replace with function body.


func _on_ChannelConfigDialog_popup_hide() -> void:
	join_message = configMenu.join_message
	commandManager.save_data()
	commandManager.load_data()
	save_ini()
	load_ini()
	pass # Replace with function body.
