extends PopupDialog


var read_only := false
var bot_name := ""
var oauth := ""
var protocol := 0
var channels := PoolStringArray([])
var join_message := ""
var clientID := ""

onready var readOnlyToggle = $PanelContainer/VBoxContainer/ReadOnly/ReadOnly
onready var botNameInput = $PanelContainer/VBoxContainer/BotName/Name
onready var botOauthInput = $PanelContainer/VBoxContainer/OAuth/Key
onready var botProtocolOptions = $PanelContainer/VBoxContainer/Protocol/Protocol
onready var botChannelsList = $PanelContainer/VBoxContainer/Channels/List
onready var botJoinMessage = $PanelContainer/VBoxContainer/JoinMessage/Message
onready var twitchClientID = $PanelContainer/VBoxContainer/ClientID/ID

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func update_data() -> void:
	readOnlyToggle.pressed = read_only
	botNameInput.text = bot_name
	botOauthInput.text = oauth
	botProtocolOptions.selected = protocol
	var s := ""
	for c in channels:
		s += c + ", "
	botChannelsList.text = s.substr(0, s.length() - 3)
	botJoinMessage.text = join_message
	twitchClientID.text = clientID
	
	botNameInput.editable = not readOnlyToggle.pressed
	botOauthInput.editable = not readOnlyToggle.pressed
	botJoinMessage.editable = not readOnlyToggle.pressed
	
	pass


func _on_ReadOnly_toggled(button_pressed: bool) -> void:
	botNameInput.editable = not button_pressed
	botOauthInput.editable = not button_pressed
	botJoinMessage.editable = not button_pressed
	pass # Replace with function body.


func _on_Hide_pressed(save: bool) -> void:
	if save:
		read_only = readOnlyToggle.pressed
		bot_name = botNameInput.text
		oauth = botOauthInput.text
		protocol = botProtocolOptions.selected
		channels = botChannelsList.text.replace(" ", "").split(",")
		join_message = botJoinMessage.text
		clientID = twitchClientID.text
	hide()
	pass # Replace with function body.
