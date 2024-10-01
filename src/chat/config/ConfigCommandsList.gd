extends TabContainer


signal reload()


var new_commands := []


@onready var defaultEveryone := $Default/VBox/Everyone/Everyone
@onready var defaultModerator := $Default/VBox/Moderator/Moderator

@onready var customList := $Custom/VBox

@onready var customEveryone := $Custom/VBox/Everyone/Everyone
@onready var customSubscriber := $Custom/VBox/Subscriber/Subscriber
@onready var customVIP := $Custom/VBox/VIP/VIP
@onready var customModerator := $Custom/VBox/Moderator/Moderator
@onready var customBroadcaster := $Custom/VBox/Broadcaster/Broadcaster


## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass 


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func clear() -> void:
	var arr := [
		defaultEveryone,
		defaultModerator,
		customEveryone,
		customSubscriber,
		customVIP,
		customModerator,
		customBroadcaster,
	]
	
	for list in arr:
		for c in list.get_children():
			c.call_deferred("free")
	
	for c in new_commands:
		if is_instance_valid(c):
			c.call_deferred("free")
	
	new_commands.resize(0)


func get_custom_commands() -> Dictionary:
	var dict := {}
	var arr := [
		customEveryone,
		customSubscriber,
		customVIP,
		customModerator,
		customBroadcaster,
	]
	
	for list in arr:
		for c in list.get_children():
			var cmd = c.get_data()
			if not cmd.name.is_empty() and not cmd.name in dict:
				dict[cmd.name] = cmd
	
	for c in new_commands:
		if is_instance_valid(c):
			var cmd = c.get_data()
			if not cmd.name.is_empty() and not cmd.name in dict:
				dict[cmd.name] = cmd
	
	return dict


func get_active_base_commands() -> Dictionary:
	var dict := {}
	var arr := [
		defaultEveryone,
		defaultModerator,
	]
	
	for list in arr:
		for c in list.get_children():
			dict[c.active.text] = c.active.button_pressed
	
	return dict


func _on_Reload_pressed() -> void:
	reload.emit()


func _on_New_pressed() -> void:
	var panel: PanelContainer = load("res://src/chat/config/CustomCommand.tscn").instantiate()
	customBroadcaster.add_sibling(panel, true)
	new_commands.append(panel)


func _on_NewScripted_pressed() -> void:
	var panel: PanelContainer = load("res://src/chat/config/ScriptCommand.tscn").instantiate()
	customBroadcaster.add_sibling(panel, true)
	new_commands.append(panel)
