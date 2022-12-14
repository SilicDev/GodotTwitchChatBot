extends Reference


signal command_fired(cmd, params, cnl)


var channel : String
var channel_id : String setget set_channel_id

var connected := false

var active_threads := []
var message_queue := []

var file := File.new()
var queue_mutex = Mutex.new()

var api := TwitchAPI.new()

var commands = preload("res://addons/godot_twitch_bot/bot/CommandManager.gd").new()
var counters = preload("res://addons/godot_twitch_bot/bot/CounterManager.gd").new()
var timers = preload("res://addons/godot_twitch_bot/bot/TimerManager.gd").new()

var formatter = preload("res://addons/godot_twitch_bot/util/MessageFormater.gd").new()

func _init(cnl: String) -> void:
	channel = cnl
	formatter.api = api
	formatter.channel = channel
	formatter.counterManager = counters
	
	var channel_path = "user://channels/" + channel
	
	commands.formatter = formatter
	commands.channel_path = channel_path
	commands.load_data()
	
	timers.formatter = formatter
	timers.channel_path = channel_path
	timers.load_data()
	
	counters.channel_path = channel_path
	counters.load_data()


func handle_message(parsedMessage: Dictionary) -> void:
	var t = Thread.new()
	active_threads.append(t)
	t.start(self, "trigger_command", parsedMessage)
	timers.update()


func trigger_command(parsedMessage: Dictionary) -> void:
	var cmd : String = commands.test_commands(parsedMessage)
	if not cmd.empty():
		var commandDict = parsedMessage.command
		var resp : String = commands.get_response(cmd, parsedMessage)
		var params : PoolStringArray = commandDict.get("botCommandParams", "").split(" ")
		emit_signal("command_fired", cmd, params, channel)
		if not resp.empty():
			queue_mutex.lock()
			message_queue.push_back(resp)
			queue_mutex.unlock()


func load_data() -> void:
	commands.load_data()
	counters.load_data()
	timers.load_data()


func save_data() -> void:
	commands.save_data()
	counters.save_data()
	timers.save_data()


func cleanup_threads() -> void:
	var temp = PoolIntArray([])
	for i in range(active_threads.size()):
		if not active_threads[i].is_alive():
			active_threads[i].wait_to_finish()
			temp.append(i)
	temp.sort()
	temp.invert() # Highest to lowest to avoid wrong indices
	for i in temp:
		active_threads.pop_at(i)


func set_channel_id(new_channel_id: String) -> void:
	channel_id = new_channel_id
	formatter.channel_id = channel_id
