class_name DebugThread


var start_object
var start_method
var start_data

var result

var thread = Thread.new()


func start(instance, method: String, userdata = null, priority: int = 1) -> int:
	call_deferred("update")
	start_object = instance
	start_method = method
	start_data = userdata
	return thread.start(Callable(instance,method).bind(userdata),priority)


func update() -> void:
	if thread.is_active() and not thread.is_alive():
		var id = thread.get_id()
		result = thread.wait_to_finish()
		print("thread ", id, " finished [start: (", str(start_object), ", ", start_method, "), result: (", str(result), ")", "]")
	elif thread.is_active():
		await (Engine.get_main_loop() as SceneTree).create_timer(0.016).timeout
		update()


func get_id() -> int:
	return thread.get_id()


func is_active() -> int:
	return thread.is_active()


func is_alive() -> int:
	return thread.is_alive()


func wait_to_finish() -> int:
	if is_alive():
		return thread.wait_to_finish()
	return -1
