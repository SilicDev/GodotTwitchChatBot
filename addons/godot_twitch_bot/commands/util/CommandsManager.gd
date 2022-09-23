extends Reference


var file := File.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func load_command(path: String):
	file.open(path, File.READ)
	var result := JSON.parse(file.get_as_text())
	file.close()
	if result.error:
		push_error("Error loading command: line " + str(result.error_line) + ": " + result.error_string)
		return result.error
	var res := Command.new()
	res.name = result.result["name"]
	res.regex = result.result["regex"]
	res.permission_level = result.result["permission"]
	res.aliases = result.result["aliases"]
	res.response = result.result["response"]
	return res


func save_command(path: String, cmd: Command) -> int:
	var file := File.new()
	var err := file.open(path, File.WRITE)
	if err:
		push_error("Failed to save command! Unable to open destination file (Error #" + str(err) + ")")
		return err
	var dict = {
		"name" : cmd.name,
		"regex" : cmd.regex,
		"permission" : cmd.permission_level,
		"aliases" : cmd.aliases,
		"response" : cmd.response,
	}
	file.store_string(JSON.print(dict))
	file.close()
	return OK
