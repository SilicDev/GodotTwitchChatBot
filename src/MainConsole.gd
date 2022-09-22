extends Panel


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
onready var bot := $Bot
onready var connectButton := $MarginContainer/VBoxContainer/HBoxContainer/Connect

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
	pass # Replace with function body.
