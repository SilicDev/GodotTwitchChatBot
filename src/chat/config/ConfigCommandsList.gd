extends TabContainer


signal reload()


var new_commands := []


onready var defaultEveryone := $Default/VBox/Everyone/Everyone
onready var defaultModerator := $Default/VBox/Moderator/Moderator

onready var customList := $Custom/VBox

onready var customEveryone := $Custom/VBox/Everyone/Everyone
onready var customSubscriber := $Custom/VBox/Subscriber/Subscriber
onready var customVIP := $Custom/VBox/VIP/VIP
onready var customModerator := $Custom/VBox/Moderator/Moderator
onready var customBroadcaster := $Custom/VBox/Broadcaster/Broadcaster


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
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
			if not cmd.name.empty() and not cmd.name in dict:
				dict[cmd.name] = cmd
	for c in new_commands:
		if is_instance_valid(c):
			var cmd = c.get_data()
			if not cmd.name.empty() and not cmd.name in dict:
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
			dict[c.active.text] = c.active.pressed
	return dict


func _on_Reload_pressed() -> void:
	emit_signal("reload")
	pass # Replace with function body.


func _on_New_pressed() -> void:
	var panel: PanelContainer = load("res://src/chat/config/CustomCommand.tscn").instance()
	customList.add_child_below_node(customBroadcaster.get_parent(), panel)
	new_commands.append(panel)
	pass # Replace with function body.


func _on_NewScripted_pressed() -> void:
	var panel: PanelContainer = load("res://src/chat/config/ScriptCommand.tscn").instance()
	customList.add_child_below_node(customBroadcaster.get_parent(), panel)
	new_commands.append(panel)
	pass # Replace with function body.
