extends PanelContainer


onready var active := $VBox/HBox/CheckBox
onready var responseLabel := $VBox/HBox/Response
onready var timeoutLabel := $VBox/HBox/Timeout
onready var userTimeoutLabel := $VBox/HBox/UserTimeout
onready var permissionLabel := $VBox/HBox/Permission

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


func _on_Test_pressed() -> void:
	
	pass # Replace with function body.
