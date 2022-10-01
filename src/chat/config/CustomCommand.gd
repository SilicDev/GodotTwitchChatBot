extends PanelContainer


var oldResponse := ""


onready var active := $VBox/HBox/CheckBox
onready var responseLabel := $VBox/HBox/Response
onready var timeoutLabel := $VBox/HBox/Timeout
onready var userTimeoutLabel := $VBox/HBox/UserTimeout
onready var permissionLabel := $VBox/HBox/Permission

onready var tabs := $VBox/Tabs

onready var commandName := $VBox/Tabs/Settings/HBox/CommandName
onready var userLevel := $VBox/Tabs/Settings/HBox2/UserLevel
onready var responseInput := $VBox/Tabs/Settings/HBox3/Response
onready var responseInputRemaining := $VBox/Tabs/Settings/HBox3/Label2

onready var cooldown := $VBox/Tabs/Advanced/HBox/HBox/GlobalCooldown
onready var userCooldown := $VBox/Tabs/Advanced/HBox/HBox2/UserCooldown
onready var aliases := $VBox/Tabs/Advanced/HBox2/Aliases
onready var keywords := $VBox/Tabs/Advanced/HBox3/Keywords
onready var regex := $VBox/Tabs/Advanced/HBox4/RegEx
onready var regexRemaining := $VBox/Tabs/Advanced/HBox4/Label2

onready var regexTester := $RegexTester
onready var regexTesterRegex := $RegexTester/PanelCon/VBox/HBox/Regex


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func set_data(cmd: Command) -> void:
	active.pressed = cmd.active
	active.text = cmd.name
	responseLabel.text = cmd.get_response({})
	timeoutLabel.text = str(cmd.timeout)
	userTimeoutLabel.text = str(cmd.user_timeout)
	permissionLabel.text = Command.Badge.keys()[cmd.permission_level].capitalize()
	commandName.text = cmd.name
	userLevel.selected = cmd.permission_level
	responseInput.text = cmd.get_response({})
	responseInputRemaining.text = str(500 - responseInput.text.length())
	cooldown.value = cmd.timeout
	userCooldown.value = cmd.user_timeout
	var s := ""
	for a in cmd.aliases:
		s += a + ", "
	if s.length() > 1:
		s = s.substr(0, s.length() - 2)
	aliases.text = s
	s = ""
	for k in cmd.keywords:
		s += k + ", "
	if s.length() > 1:
		s = s.substr(0, s.length() - 2)
	keywords.text = s
	regex.text = cmd.regex
	regexRemaining.text = str(regex.max_length - regex.text.length())
	oldResponse = responseInput.text


func get_data() -> Command:
	var cmd = Command.new()
	cmd.active = active.pressed
	cmd.name = commandName.text
	cmd.permission_level = userLevel.selected
	cmd.response = responseInput.text
	cmd.timeout = cooldown.value
	cmd.user_timeout = userCooldown.value
	cmd.aliases = aliases.text.replace(" ", "").split(",")
	cmd.keywords = keywords.text.replace(" ", "").split(",")
	cmd.regex = regex.text
	return cmd


func _on_Test_pressed() -> void:
	regexTester.popup_centered(Vector2(200, 100))
	regexTesterRegex.text = regex.text
	regexTester.test()
	pass # Replace with function body.


func _on_RegexTester_popup_hide() -> void:
	regex.text = regexTesterRegex.text
	pass # Replace with function body.


func _on_Edit_pressed() -> void:
	tabs.visible = not tabs.visible
	pass # Replace with function body.


func _on_Response_text_changed() -> void:
	if responseInput.text.length() > 500:
		responseInput.text = oldResponse
	else:
		responseInputRemaining.text = str(500 - responseInput.text.length())
		oldResponse = responseInput.text
	responseLabel.text = responseInput.text
	pass # Replace with function body.


func _on_RegEx_text_changed(new_text: String) -> void:
	regexRemaining.text = str(regex.max_length - regex.text.length())
	pass # Replace with function body.


func _on_Delete_pressed() -> void:
	call_deferred("free")
	pass # Replace with function body.


func _on_CommandName_text_changed(new_text: String) -> void:
	active.text = new_text
	pass # Replace with function body.


func _on_UserLevel_item_selected(index: int) -> void:
	permissionLabel.text = Command.Badge.keys()[index].capitalize()
	pass # Replace with function body.
