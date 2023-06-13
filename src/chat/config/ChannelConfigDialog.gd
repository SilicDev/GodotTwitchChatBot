extends Window


var channel

var join_message := ""


@onready var joinMessageInput := $PanelContainer/VBox/TabContainer/General/HBoxContainer/JoinMessage
@onready var commandLists := $PanelContainer/VBox/TabContainer/Commands


## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func load_data() -> void:
	channel.commands.load_data()
	
	update_data()


func update_data() -> void:
	commandLists.clear()
	joinMessageInput.text = join_message
	
	for c in channel.commands.commands.keys():
		var cmd = channel.commands.commands[c]
		
		if c in channel.commands.base_commands.keys():
			var panel: PanelContainer = preload("res://src/chat/config/DefaultCommand.tscn").instantiate()
			
			if cmd.permission_level == Command.Badge.NONE:
				commandLists.defaultEveryone.add_child(panel)
			elif cmd.permission_level == Command.Badge.MODERATOR:
				commandLists.defaultModerator.add_child(panel)
			
			panel.active.button_pressed = cmd.active
			panel.active.text = c
			
			if "usage_hint" in cmd:
				panel.hint.text = cmd.usage_hint
			if "example_reply" in cmd:
				panel.example.text = cmd.example_reply
		
		else:
			var panel: PanelContainer
			if "usage_hint" in cmd:
				panel = preload("res://src/chat/config/ScriptCommand.tscn").instantiate()
			else:
				panel = preload("res://src/chat/config/CustomCommand.tscn").instantiate()
			
			match cmd.permission_level:
				Command.Badge.NONE:
					commandLists.customEveryone.add_child(panel)
				
				Command.Badge.SUBSCRIBER:
					commandLists.customSubscriber.add_child(panel)
				
				Command.Badge.VIP:
					commandLists.customVIP.add_child(panel)
				
				Command.Badge.MODERATOR:
					commandLists.customModerator.add_child(panel)
				
				Command.Badge.BROADCASTER:
					commandLists.customBroadcaster.add_child(panel)
			
			panel._ready()
			panel.set_data(cmd)


func _on_Hide_pressed(save: bool) -> void:
	if save:
		join_message = joinMessageInput.text
		channel.commands.commands = channel.commands.base_commands.duplicate(true)
		channel.commands.commands.merge(commandLists.get_custom_commands())
		var active: Dictionary = commandLists.get_active_base_commands()
		for c in channel.commands.base_commands.keys():
			channel.commands.commands[c].active = active.get(c, true)
	hide()
	visible = false
	commandLists.clear()


func _on_Commands_reload() -> void:
	channel.commands.load_data()
	
	update_data()
