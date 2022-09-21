tool
class_name Command
extends Resource


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
export(String) var name := ""
export(String, MULTILINE) var regex := ""
enum Badge {
	NONE,
	SUBSCRIBER,
	VIP,
	MODERATOR,
	BROADCASTER,
}
export(Badge) var permission_level := Badge.NONE
export(PoolStringArray) var aliases := PoolStringArray([])
export(String, MULTILINE) var response := ""
var matcher = RegEx.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func should_fire(parsedMessage: Dictionary) -> bool:
	if permission_level == Badge.NONE or (parsedMessage.has("tags") and parsedMessage.tags["user-type"] and get_badge_from_user_type(parsedMessage.tags["user-type"]) >= permission_level):
		if parsedMessage.command.has("botCommand") and parsedMessage.command.botCommand == name:
			return true
		if not regex.empty():
			matcher.compile(regex)
			if matcher.search(parsedMessage.parameters):
				return true
	return false


func get_badge_from_user_type(user_type: String) -> int:
	match user_type:
		"broadcaster":
			return Badge.BROADCASTER
		"mod":
			return Badge.MODERATOR
		"vip":
			return Badge.VIP
		"subscriber":
			return Badge.SUBSCRIBER
		_:
			return Badge.NONE
