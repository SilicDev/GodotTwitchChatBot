extends TabContainer


signal reload()


onready var defaultEveryone := $Default/VBox/Everyone/Everyone
onready var defaultModerator := $Default/VBox/Moderator/Moderator

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


func _on_Reload_pressed() -> void:
	emit_signal("reload")
	pass # Replace with function body.
