extends Window

signal popup_hide()

var read_only := false
var bot_name := ""
var oauth := ""
var refresh_token := ""
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

var scopes: Array[String] = [
	"chat:read",
	"user:write:chat",
	"user:read:chat",
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
	popup_hide.emit()

func _on_auth_pressed() -> void:
	var res = await request_device_code()
	botOauthInput.text = res[0]
	refresh_token = res[1]
	return
	var redirect_url := "http://localhost:3000"
	var scopes_str = scopes.reduce(func(acc: String, s: String):
			if not acc.is_empty():
				acc += "+"
			return acc + s.uri_encode(), "")
	var url := "https://id.twitch.tv/oauth2/authorize?response_type=token&client_id=%s&redirect_uri=%s&scope=%s&token_type=bearer" % [clientID, redirect_url, scopes_str]
	OS.shell_open(url)
	pass # Replace with function body.

func request_device_code() -> Array[String]:
	var url = "/oauth2/device"
	var scopes_str = scopes.reduce(func(acc: String, s: String):
			if not acc.is_empty():
				acc += " "
			return acc + s.uri_encode(), "")
	var body = "client_id={}&scopes={}".format([clientID, scopes_str], "{}")
	var headers = [
		"Content-Type: application/x-www-form-urlencoded", 
		"Content-Length: " + str(body.length())
	]
	var http_client = HTTPClient.new()
	http_client.connect_to_host("https://id.twitch.tv")
	http_client.poll()
	var client_alive = true
	var device_code_received = false
	var request_timeout = 0
	var user_code = ""
	var device_code = ""
	var access_token = ""
	var refresh_token = ""
	var expires_in = -1
	while not device_code_received and client_alive:
		match http_client.get_status():
			HTTPClient.STATUS_DISCONNECTED:
				client_alive = false
				print("Disconnected")
			HTTPClient.STATUS_RESOLVING:
				http_client.poll()
			HTTPClient.STATUS_CANT_RESOLVE:
				client_alive = false
			HTTPClient.STATUS_CONNECTING:
				http_client.poll()
			HTTPClient.STATUS_CANT_CONNECT:
				client_alive = false
			HTTPClient.STATUS_CONNECTED:
				if request_timeout <= Time.get_ticks_msec():
					var err := http_client.request(HTTPClient.METHOD_POST, url, headers, body)
					if err:
						client_alive = false
			HTTPClient.STATUS_REQUESTING:
				http_client.poll()
			HTTPClient.STATUS_BODY:
				var status = http_client.get_response_code()
				# If there is a response...
				var rb = PackedByteArray() # Array that will hold the data.
				
				while http_client.get_status() == HTTPClient.STATUS_BODY:
					# Get a chunk.
					var chunk = http_client.read_response_body_chunk()
					if chunk.size() == 0:
						OS.delay_msec(10)
					else:
						rb.append_array(chunk) # Append to read buffer.
					# While there is body left to be read
					http_client.poll()
				# Done!
				
				var message = rb.get_string_from_utf8()
				var test_json_conv = JSON.new()
				var err := test_json_conv.parse(message)
				if err:
					request_timeout = Time.get_ticks_msec() + 5000
					continue
				var result: Dictionary = test_json_conv.get_data()
				if user_code.is_empty() and status != 200:
					print(str(status) + ": " + str(result.get("message")))
				if result.has("user_code"):
					user_code = result.get("user_code")
					device_code = result.get("device_code")
					OS.shell_open(result.get("verification_uri"))
					request_timeout = Time.get_ticks_msec() + 5000
					url = "/oauth2/token"
					var grant_type = "urn:ietf:params:oauth:grant-type:device_code".uri_encode()
					body = "client_id={}&scopes={}&device_code={}&grant_type={}".format(
						[clientID, scopes_str, device_code, grant_type], "{}"
					)
					headers = [
						"Content-Type: application/x-www-form-urlencoded", 
						"Content-Length: " + str(body.length())
					]
				elif result.has("access_token"):
					access_token = result.get("access_token")
					refresh_token = result.get("refresh_token")
					expires_in = Time.get_unix_time_from_system() + result.get("expires_in", 0)
					#print("Access Token: " + access_token + "\nRefresh Token: " + refresh_token)
					print("Auth time: " + str(result.get("expires_in")))
					oauth = access_token
					device_code_received = true
					pass
			HTTPClient.STATUS_CONNECTION_ERROR:
				print("Connection Error")
				http_client.close()
				await get_tree().physics_frame
				http_client.connect_to_host("https://id.twitch.tv")
				http_client.poll()
			HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
				client_alive = false
				print("TLS Handshake Error")
			_:
				pass
	return [access_token, refresh_token]
	pass
