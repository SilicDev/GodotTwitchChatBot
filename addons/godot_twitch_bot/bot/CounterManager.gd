extends RefCounted


var file : FileAccess

var channel_path : String

var counters := {}


func load_data(base_path := channel_path) -> void:
	load_counters(base_path + "/counters.json")


func save_data(base_path := channel_path) -> void:
	save_counters(base_path + "/counters.json")


func load_counters(path: String) -> int:
	file = FileAccess.open(path, FileAccess.READ)
	var err := FileAccess.get_open_error()
	if err:
		save_counters(path)
		file = FileAccess.open(path, FileAccess.READ)
	
	var test_json_conv = JSON.new()
	err = test_json_conv.parse(file.get_as_text())
	var result := test_json_conv.get_data()
	file.close()
	if err:
		push_error("Error loading counters: line " + str(test_json_conv.get_error_line()) + 
				": " + test_json_conv.get_error_message()
		)
	
	counters = result
	return OK


func save_counters(path: String) -> int:
	var dir := DirAccess.open("user://")
	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())
	
	file = FileAccess.open(path, FileAccess.WRITE)
	var err := FileAccess.get_open_error()
	if err:
		push_error("Failed to save counters! Unable to open destination file (Error #" + 
				str(err) + ")"
		)
		return err
	
	file.store_string(JSON.stringify(counters))
	file.close()
	return OK
