class_name ScriptCommand
extends Command

var usage_hint := ""
var example_reply := ""

func get_response(parsedMessage: Dictionary) -> String:
	#${response}
	return response


func get_save_dict() -> Dictionary:
	var dict := .get_save_dict()
	dict["response"] = response
	dict["usage_hint"] = usage_hint
	dict["example_reply"] = example_reply
	dict["type"] = "scripted"
	return dict
