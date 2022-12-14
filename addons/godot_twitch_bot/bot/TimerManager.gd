extends Reference


var file := File.new()

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
	var err = file.open(path, File.READ)
	if err:
		save_timers(path)
		file.open(path, File.READ)
	
	var result := JSON.parse(file.get_as_text())
	file.close()
	if result.error:
		push_error("Error loading timers: line " + str(result.error_line) + 
				": " + result.error_string
		)
	
	timers = result.result
	return OK


func save_timers(path: String) -> int:
	var dir := Directory.new()
	if not dir.dir_exists(path.get_base_dir()):
		dir.make_dir_recursive(path.get_base_dir())
	
	var err := file.open(path, File.WRITE)
	if err:
		push_error("Failed to save timers! Unable to open destination file (Error #" + 
				str(err) + ")"
		)
		return err
	
	file.store_string(JSON.print(timers))
	file.close()
	return OK
