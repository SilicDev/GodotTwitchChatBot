extends RefCounted


var file : FileAccess

var channel_path : String

var timers := {}

var formatter


func update() -> void:
	pass


func load_data(base_path := channel_path) -> void:
	load_timers(base_path + "/timers.json")


func save_data(base_path := channel_path) -> void:
	save_timers(base_path + "/timers.json")


func load_timers(path: String) -> int:
	file = FileAccess.open(path, FileAccess.READ)
	var err := FileAccess.get_open_error()
	if err:
		save_timers(path)
		file = FileAccess.open(path, FileAccess.READ)
	
	var test_json_conv = JSON.new()
	err = test_json_conv.parse(file.get_as_text())
	var result := test_json_conv.get_data()
	file.close()
	if err:
		push_error("Error loading timers: line " + str(test_json_conv.get_error_line()) + 
				": " + test_json_conv.get_error_message()
		)
	
	timers = result
	return OK


func save_timers(path: String) -> int:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())
	
	file = FileAccess.open(path, FileAccess.WRITE)
	var err := FileAccess.get_open_error()
	if err:
		push_error("Failed to save timers! Unable to open destination file (Error #" + 
				str(err) + ")"
		)
		return err
	
	file.store_string(JSON.stringify(timers))
	file.close()
	return OK
