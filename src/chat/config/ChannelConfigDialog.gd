extends PopupDialog


var commandManager

var join_message := ""


onready var joinMessageInput := $PanelContainer/VBox/TabContainer/General/HBoxContainer/JoinMessage
onready var commandLists := $PanelContainer/VBox/TabContainer/Commands


## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func load_data() -> void:
	commandManager.load_data()
	
	update_data()


func update_data() -> void:
	commandLists.clear()
	joinMessageInput.text = join_message
	
	for c in commandManager.commands.keys():
		var cmd = commandManager.commands[c]
		
		if c in commandManager.base_commands.keys():
			var panel: PanelContainer = load("res://src/chat/config/DefaultCommand.tscn").instance()
			
			if cmd.permission_level == Command.Badge.NONE:
				commandLists.defaultEveryone.add_child(panel)
			elif cmd.permission_level == Command.Badge.MODERATOR:
				commandLists.defaultModerator.add_child(panel)
			
			panel.active.pressed = cmd.active
			panel.active.text = c
			
			if "usage_hint" in cmd:
				panel.hint.text = cmd.usage_hint
			if "example_reply" in cmd:
				panel.example.text = cmd.example_reply
		
		else:
			var panel: PanelContainer
			if "usage_hint" in cmd:
				panel = load("res://src/chat/config/ScriptCommand.tscn").instance()
			else:
				panel = load("res://src/chat/config/CustomCommand.tscn").instance()
			
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
				
			
			panel.set_data(cmd)


func _on_Hide_pressed(save: bool) -> void:
	if save:
		join_message = joinMessageInput.text
		commandManager.commands = commandManager.base_commands.duplicate(true)
		commandManager.commands.merge(commandLists.get_custom_commands())
		var active: Dictionary = commandLists.get_active_base_commands()
		for c in commandManager.base_commands.keys():
			commandManager.commands[c].active = active.get(c, true)
	hide()
	commandLists.clear()


func _on_Commands_reload() -> void:
	commandManager.load_data()
	
	update_data()
