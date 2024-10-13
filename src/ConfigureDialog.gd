extends Window

var read_only := false
var bot_name := ""
var oauth := ""
var protocol := 0

var channels := PackedStringArray([])
var join_message := ""

var clientID := ""


@onready var readOnlyToggle = $PanelContainer/VBoxContainer/ReadOnly/ReadOnly

@onready var botNameInput = $PanelContainer/VBoxContainer/BotName/Name
@onready var botOauthInput = $PanelContainer/VBoxContainer/OAuth/Key
@onready var botProtocolOptions = $PanelContainer/VBoxContainer/Protocol/Protocol

@onready var botChannelsList = $PanelContainer/VBoxContainer/Channels/List
@onready var botJoinMessage = $PanelContainer/VBoxContainer/JoinMessage/Message

@onready var twitchClientID = $PanelContainer/VBoxContainer/ClientID/ID


## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass


func update_data() -> void:
	readOnlyToggle.button_pressed = read_only
	botNameInput.text = bot_name
	botOauthInput.text = oauth
	botProtocolOptions.selected = protocol
	
	var s := ""
	for c in channels:
		s += c + ", "
	botChannelsList.text = s.substr(0, s.length() - 2)
	
	botJoinMessage.text = join_message
	twitchClientID.text = clientID
	
	botNameInput.editable = not readOnlyToggle.button_pressed
	botOauthInput.editable = not readOnlyToggle.button_pressed
	botJoinMessage.editable = not readOnlyToggle.button_pressed


func _on_ReadOnly_toggled(button_pressed: bool) -> void:
	botNameInput.editable = not button_pressed
	botOauthInput.editable = not button_pressed
	botJoinMessage.editable = not button_pressed


func _on_Hide_pressed(save: bool) -> void:
	if save:
		read_only = readOnlyToggle.button_pressed
		bot_name = botNameInput.text
		oauth = botOauthInput.text
		protocol = botProtocolOptions.selected
		
		channels = botChannelsList.text.replace(" ", "").split(",")
		join_message = botJoinMessage.text
		
		clientID = twitchClientID.text
	hide()

func _on_auth_pressed() -> void:
	var redirect_url := "http://localhost:3000"
	var scopes: Array[String] = [
		"chat:read",
		"chat:write",
		"chat:edit",
		"clips:edit",
		"moderator:manage:announcements",
		"moderator:manage:banned_users",
		"moderator:manage:chat_messages",
		"moderator:manage:shoutouts",
		"user:manage:whispers",
		"channel:manage:broadcast",
		"user:manage:chat_color"
	]
	var scopes_str = scopes.reduce(func(acc: String, s: String):
			if not acc.is_empty():
				acc += "+"
			return acc + s.uri_encode(), "")
	var url := "https://id.twitch.tv/oauth2/authorize?response_type=token&client_id=%s&redirect_uri=%s&scope=%s&token_type=bearer" % [clientID, redirect_url, scopes_str]
	OS.shell_open(url)
	pass # Replace with function body.
