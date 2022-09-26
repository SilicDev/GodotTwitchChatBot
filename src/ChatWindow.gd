extends PanelContainer

signal send_button_pressed(msg, channel)
signal part_requested(channel)

onready var chat := $VBoxContainer/PanelContainer/RichTextLabel
onready var messageInput := $VBoxContainer/HBoxContainer/LineEdit
onready var botLabel := $VBoxContainer/HBoxContainer/Label

var bot_color := ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	chat.bbcode_enabled = true
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func add_message(message: Dictionary) -> void:
	var tags = message.get("tags", {})
	chat.append_bbcode("[b][color=" + tags.get("color") + "]" + tags.get("display-name", "Anonymous") + "[/color][/b]: " + message.parameters + "\n")
	pass


func add_bot_message(message: String) -> void:
	if bot_color.empty():
		chat.append_bbcode("[b]" + botLabel.text + "[/b]: " + message + "\n")
	else:
		chat.append_bbcode("[b][color=" + bot_color + "]" + botLabel.text + "[/color][/b]: " + message + "\n")
	pass


func _on_Send_pressed() -> void:
	emit_signal("send_button_pressed", messageInput.text, name)
	messageInput.text = ""
	pass # Replace with function body.


func _on_Part_pressed() -> void:
	emit_signal("part_requested", name)
	pass # Replace with function body.
