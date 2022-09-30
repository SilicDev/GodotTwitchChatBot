extends PopupDialog

var commandManager

var join_message := ""

onready var joinMessageInput := $PanelContainer/VBox/TabContainer/General/HBoxContainer/JoinMessage

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_Hide_pressed(save: bool) -> void:
	if save:
		join_message = joinMessageInput.text
		pass
	hide()
	pass # Replace with function body.


func _on_Commands_reload() -> void:
	commandManager.load_data()
	pass # Replace with function body.
