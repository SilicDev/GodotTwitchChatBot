extends Popup

var regex := RegEx.new()


@onready var regexInput := $PanelCon/VBox/HBox/Regex
@onready var testInput := $PanelCon/VBox/Test
@onready var output := $PanelCon/VBox/Output


## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func test() -> void:
	if regex.is_valid():
		var res := regex.search_all(testInput.text)
		output.text = ""
		for m in res:
			output.text += m.strings[0] + "\n"


func _on_Regex_text_changed(new_text: String) -> void:
	var err := regex.compile(new_text)
	if err:
		regexInput.add_theme_color_override("font_color", Color.RED)
	else:
		regexInput.add_theme_color_override("font_color", Color.WHITE)
		test()


func _on_Test_text_changed(_new_text: String) -> void:
	test()
