class_name ScriptCommand
extends Command


var usage_hint := ""
var example_reply := ""


# Fixes error messages when reloading script with injected code
# warning-ignore-all:unused_argument
# warning-ignore-all:unreachable_code
func get_response(parsedMessage: Dictionary) -> String:
	#${response}
	return response


func get_save_dict() -> Dictionary:
	var dict := super.get_save_dict()
	dict["response"] = response
	dict["usage_hint"] = usage_hint
	dict["example_reply"] = example_reply
	dict["type"] = "scripted"
	return dict
