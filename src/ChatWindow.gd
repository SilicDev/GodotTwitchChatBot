extends PanelContainer

signal send_button_pressed(msg, channel)
signal part_requested(channel)

onready var chat := $VBoxContainer/PanelContainer/RichTextLabel
onready var messageInput := $VBoxContainer/HBoxContainer/LineEdit
onready var botLabel := $VBoxContainer/HBoxContainer/Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chat.bbcode_enabled = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func add_message(message: Dictionary) -> void:
	if message.tags.color:
		chat.append_bbcode("[b][color=" + message.tags.color + "]" + message.tags["display-name"] + "[/color][/b]: " + message.parameters + "\n")
	else:
		chat.append_bbcode("[b]" + message.tags["display-name"] + "[/b]: " + message.parameters + "\n")
	pass


func add_bot_message(message: String) -> void:
	chat.append_bbcode("[b]" + botLabel.text + "[/b]: " + message + "\n")
	pass


func _on_Send_pressed() -> void:
	emit_signal("send_button_pressed", messageInput.text, name)
	messageInput.text = ""
	pass # Replace with function body.


func _on_Part_pressed() -> void:
	emit_signal("part_requested", name)
	pass # Replace with function body.
