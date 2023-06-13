extends RefCounted


signal timer_triggered(message)


var messages := {}

var cooldown := 30
var min_messages := 15

var message_counter := 0
var last_sent := Time.get_ticks_msec() - (cooldown / 2 * 60 * 1000)

var active := false


func update() -> void:
	message_counter += 1
	
