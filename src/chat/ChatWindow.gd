extends PanelContainer


signal send_button_pressed(msg, channel)
signal part_requested(channel)
signal join_requested(channel)

signal ban_user_requested(channel, id)
signal timeout_user_requested(channel, id, length)
signal delete_message_requested(channel, id)


const msgPanelScene := preload("res://src/chat/ChatMessage.tscn")


var bot_color := ""
var bot_name := ""
var bot_id := ""
var room_id := ""

var is_mod := false

var join_message := ""

var reply_id := ""
var lastBotMessage

var channelInstance: Channel

var config := ConfigFile.new()

var _colors := [
	"#ff0000",
	"#0000ff",
	"#008000",
	"#b22222",
	"#ff7f50",
	"#9acd32",
	"#ff4500",
	"#2e8b57",
	"#daa520",
	"#d2691e",
	"#5f9ea0",
	"#1e90ff",
	"#ff69b4",
	"#8a2be2",
	"#00ff7f",
]

var users := {}


onready var chat := $VBoxContainer/PanelContainer/Scroll/VBox
onready var scroll := $VBoxContainer/PanelContainer/Scroll

onready var botLabel := $VBoxContainer/HBoxContainer/Label
onready var replyBox := $VBoxContainer/HBoxContainer/VBox/HBox
onready var replyText := $VBoxContainer/HBoxContainer/VBox/HBox/Label
onready var messageInput := $VBoxContainer/HBoxContainer/VBox/LineEdit

onready var partButton := $VBoxContainer/HBoxContainer/CenterContainer3/Part

onready var configMenu := $ChannelConfigDialog

var last_message_time := Time.get_ticks_msec()


## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass 


## Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if channelInstance:
		channelInstance.cleanup_threads()
		if Time.get_ticks_msec() - last_message_time > 60000000:
			var res = channelInstance.api.get_users_by_id([bot_id])
			last_message_time = Time.get_ticks_msec()
	pass


func add_message(message: Dictionary) -> void:
	var msgPanel = msgPanelScene.instance()
	chat.add_child(msgPanel)
	set_data(msgPanel, message)
	
	msgPanel.connect("ban_user_requested", self, "_on_ban_user_requested")
	msgPanel.connect("timeout_user_requested", self, "_on_timeout_user_requested")
	msgPanel.connect("delete_message_requested", self, "_on_delete_message_requested")
	msgPanel.connect("reply_requested", self, "_on_reply_requested")


func set_data(msgPanel, message: Dictionary) -> void:
	var tags = message.get("tags", {})
	var display_name = tags.get("display-name", "Anonymous")
	
	msgPanel.id = tags.get("id", "")
	msgPanel.sender = display_name
	msgPanel.sender_id = tags.get("user-id", "")
	msgPanel.reply.visible = tags.has("reply-parent-user-id")
	msgPanel.reply_sender_id = tags.get("reply-parent-user-id", "")
	msgPanel.reply_id = tags.get("reply-parent-msg-id", "")
	if not msgPanel.sender_id in users:
		users[msgPanel.sender_id] = _colors[randi() % _colors.size()]
	if tags.has("color"):
		var color = tags.get("color", "#ffffff")
		if color:
			users[msgPanel.sender_id] = color
	print(message.parameters)
	if message.parameters.begins_with("\u0001ACTION"):
		print("ACTION")
		message.parameters = message.parameters.substr(8)
		msgPanel.message.append_bbcode("[b][color=" + users[msgPanel.sender_id] + "]" + display_name 
				+ "[/color][/b]: [i]" + message.parameters + "[/i]"
		)
	else:
		msgPanel.message.append_bbcode("[b][color=" + users[msgPanel.sender_id] + "]" + display_name 
				+ "[/color][/b]: " + message.parameters
		)
	
	if not msgPanel.reply_id.empty():
		var reply = get_message_by_id(msgPanel.reply_id)
		if reply:
			msgPanel.reply.text = get_reply_message(reply)
	
	msgPanel.modButtons.visible = can_moderate(tags)
	msgPanel.parsedMessage = message
	
	yield(get_tree(),"idle_frame")
	scroll.scroll_vertical += msgPanel.rect_size.y


func add_bot_message(message: String, msg_reply_id := "") -> void:
	var msgPanel = msgPanelScene.instance()
	chat.add_child(msgPanel)
	
	msgPanel.sender = bot_name
	msgPanel.sender_id = bot_id
	msgPanel.modButtons.visible = false
	msgPanel.reply.visible = not msg_reply_id.empty()
	msgPanel.replyContainer.visible = not msg_reply_id.empty()
	
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
	
	if not msg_reply_id.empty():
		msgPanel.reply_id = msg_reply_id
		msgPanel.parsedMessage.tags["reply-parent-msg-id"] = msg_reply_id
	
	var reply = get_message_by_id(msg_reply_id)
	if reply:
		msgPanel.reply.text = get_reply_message(reply)
	
	if bot_color.empty():
		msgPanel.message.append_bbcode("[b]" + bot_name + "[/b]: " + message + "\n")
	else:
		msgPanel.message.append_bbcode("[b][color=" + bot_color + "]" + bot_name +
				"[/color][/b]: " + message
		)
	
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
			if c.id == msg_id || not msg_id:
				return c
	return null


## Deletes all messagess of the specified user or all messages if [code]user_id == null[/code]
func get_messages_by_user_id(user_id) -> Array:
	var out = []
	for c in chat.get_children():
		if c is PanelContainer:
			if c.sender_id == user_id or not user_id:
				out.append(c)
	return out


func load_ini() -> void:
	var path := "user://channels/" + name.to_lower() + "/config.ini"
	var err := config.load(path)
	if err:
		save_ini()
		err = config.load(path)
		if err:
			push_error("Failed to load channel config!")
	
	join_message = config.get_value("general", "join_message", join_message)
	config.clear()


func save_ini() -> void:
	config.set_value("general", "join_message", join_message)
	
	var path = "user://channels/" + name.to_lower() + "/config.ini"
	var dir := Directory.new()
	if not dir.dir_exists(path.get_base_dir()):
		var err := dir.make_dir_recursive(path.get_base_dir())
		if err:
			push_error("Unable to create channel save directory")
	
	var err := config.save(path)
	if err:
		push_error("Failed to save channel config!")
	config.clear()


func get_reply_message(reply) -> String:
	var display_name = reply.parsedMessage.get("tags", {}).get("display-name", "Anonymous")
	return display_name + ": " + reply.parsedMessage.get("parameters", "")


func can_moderate(tags: Dictionary) -> bool:
	var sender_is_self = tags.get("display-name", "Anonymous").to_lower() == name
	var sender_is_mod = int(tags.get("mod", "0"))
	return not (sender_is_self or sender_is_mod) and is_mod


func _on_Send_pressed() -> void:
	emit_signal("send_button_pressed", messageInput.text, name, reply_id)
	reply_id = ""
	replyBox.visible = false
	messageInput.text = ""


func _on_Part_pressed() -> void:
	if partButton.text == "Part Channel":
		emit_signal("part_requested", name)
		partButton.text = "Rejoin"
	else:
		emit_signal("join_requested", name)
		partButton.text = "Part Channel"


func _on_EndReply_pressed() -> void:
	replyBox.visible = false
	reply_id = ""


func _on_ban_user_requested(id) -> void:
	emit_signal("ban_user_requested", name, id)


func _on_timeout_user_requested(id, length) -> void:
	emit_signal("timeout_user_requested", name, id, length)


func _on_delete_message_requested(id) -> void:
	emit_signal("delete_message_requested", name, id)


func _on_reply_requested(id) -> void:
	var reply = get_message_by_id(id)
	if reply:
		reply_id = id
		replyBox.visible = true
		var display_name = reply.parsedMessage.get("tags", {}).get("display-name", "Anonymous")
		replyText.text = display_name + ": " + reply.parsedMessage.get("parameters", "")


func _on_Config_pressed() -> void:
	configMenu.popup_centered(Vector2(800, 400))


func _on_ChannelConfigDialog_about_to_show() -> void:
	load_ini()
	configMenu.channel = channelInstance
	configMenu.join_message = join_message
	configMenu.load_data()


func _on_ChannelConfigDialog_popup_hide() -> void:
	join_message = configMenu.join_message
	channelInstance.save_data()
	channelInstance.load_data()
	save_ini()
	load_ini()
