class_name Channel
extends RefCounted


signal command_fired(cmd, params, cnl)


var channel : String
var channel_id : String : set = set_channel_id

var connected := false

var active_threads := []
var message_queue := []

var file : FileAccess
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


func _to_string() -> String:
	return "[Channel(" + channel + ":" + channel_id + "):" + str(get_instance_id()) + "]"


func handle_message(parsedMessage: Dictionary) -> void:
	var t = Thread.new()
	active_threads.append(t)
	t.start(trigger_command.bind(parsedMessage))
	print("Thread started: ", t.get_id())
	timers.update()


func trigger_command(parsedMessage: Dictionary) -> void:
	var cmd : String = commands.test_commands(parsedMessage)
	if not cmd.is_empty():
		var commandDict = parsedMessage.command
		var resp : String = commands.get_response(cmd, parsedMessage)
		var params : PackedStringArray = commandDict.get("botCommandParams", "").split(" ")
		call_deferred("emit_signal", "command_fired", cmd, params, channel)
		if not resp.is_empty():
			var msgs := PackedStringArray()
			while resp.length() >= 500:
				var pos := 0
				while resp.find(" ", pos) < 500:
					pos = resp.find(" ", pos)
				if pos == 0:
					pos = 499
				msgs.append(resp.left(pos))
				resp = resp.right(-pos)
			msgs.append(resp)
			queue_mutex.lock()
			for msg in msgs:
				message_queue.push_back(msg)
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
	var temp = []
	for t in active_threads:
		if not t.is_alive():
			print(t.get_id(), ": ", t.wait_to_finish())
			temp.append(t)
	for t in temp:
		active_threads.erase(t)
	temp.clear()


func set_channel_id(new_channel_id: String) -> void:
	channel_id = new_channel_id
	formatter.channel_id = channel_id
