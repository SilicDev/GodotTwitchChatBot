extends PanelContainer


@onready var active := $VBox/HBox/CheckBox
@onready var usageLabel := $VBox/HBox/UsageHint
@onready var exampleLabel := $VBox/HBox/ExampleReply
@onready var timeoutLabel := $VBox/HBox/Timeout
@onready var userTimeoutLabel := $VBox/HBox/UserTimeout
@onready var permissionLabel := $VBox/HBox/Permission

@onready var tabs := $VBox/TabBar

@onready var commandName := $VBox/TabBar/Settings/HBox/CommandName
@onready var usageHint := $VBox/TabBar/Settings/HBox4/UsageHint
@onready var exampleReply := $VBox/TabBar/Settings/HBox5/ExampleReply
@onready var userLevel := $VBox/TabBar/Settings/HBox2/UserLevel
@onready var responseInput := $VBox/TabBar/Settings/HBox3/Response

@onready var cooldown := $VBox/TabBar/Advanced/HBox/HBox/GlobalCooldown
@onready var userCooldown := $VBox/TabBar/Advanced/HBox/HBox2/UserCooldown
@onready var aliases := $VBox/TabBar/Advanced/HBox2/Aliases
@onready var keywords := $VBox/TabBar/Advanced/HBox3/Keywords
@onready var regex := $VBox/TabBar/Advanced/HBox4/RegEx
@onready var regexRemaining := $VBox/TabBar/Advanced/HBox4/Label2

@onready var regexTester := $RegexTester
@onready var regexTesterRegex := $RegexTester/PanelCon/VBox/HBox/Regex


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func set_data(cmd: Command) -> void:
	active.button_pressed = cmd.active
	active.text = cmd.name
	
	usageLabel.text = cmd.usage_hint
	exampleLabel.text = cmd.example_reply
	
	timeoutLabel.text = str(cmd.timeout)
	userTimeoutLabel.text = str(cmd.user_timeout)
	
	permissionLabel.text = Command.Badge.keys()[cmd.permission_level].capitalize()
	commandName.text = cmd.name
	
	usageHint.text = cmd.usage_hint
	exampleReply.text = cmd.example_reply
	
	userLevel.selected = cmd.permission_level
	responseInput.text = cmd.response
	
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


func get_data() -> Command:
	var cmd = ScriptCommand.new()
	cmd.active = active.pressed
	
	cmd.name = commandName.text
	cmd.permission_level = userLevel.selected
	cmd.response = responseInput.text
	
	cmd.timeout = cooldown.value
	cmd.user_timeout = userCooldown.value
	
	cmd.aliases = aliases.text.replace(" ", "").split(",")
	cmd.keywords = keywords.text.replace(" ", "").split(",")
	
	cmd.regex = regex.text
	cmd.usage_hint = usageHint.text
	cmd.example_reply = exampleReply.text
	return cmd


func _on_Test_pressed() -> void:
	regexTester.popup_centered(Vector2(200, 100))
	regexTesterRegex.text = regex.text
	regexTester.test()


func _on_RegexTester_popup_hide() -> void:
	regex.text = regexTesterRegex.text


func _on_Edit_pressed() -> void:
	tabs.visible = not tabs.visible


func _on_RegEx_text_changed(_new_text: String) -> void:
	regexRemaining.text = str(regex.max_length - regex.text.length())


func _on_Delete_pressed() -> void:
	call_deferred("free")


func _on_CommandName_text_changed(new_text: String) -> void:
	active.text = new_text


func _on_UserLevel_item_selected(index: int) -> void:
	permissionLabel.text = Command.Badge.keys()[index].capitalize()



func _on_UsageHint_text_changed() -> void:
	usageLabel.text = usageHint.text


func _on_ExampleReply_text_changed() -> void:
	exampleLabel.text = exampleReply.text
