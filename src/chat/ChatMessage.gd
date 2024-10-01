extends PanelContainer


signal ban_user_requested(id)
signal timeout_user_requested(id, length)
signal delete_message_requested(id)

signal reply_requested(id)


var id := ""

var sender := ""
var sender_id := ""

var reply_sender_id := ""
var reply_id := ""

var parsedMessage := {}


@onready var message := $HBoxContainer/MessageBody/Message
@onready var reply := $HBoxContainer/MessageBody/Reply

@onready var modButtons := $HBoxContainer/ModButtons
@onready var replyContainer := $HBoxContainer/ReplyCont


## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	message.bbcode_enabled = true


func _on_Ban_pressed() -> void:
	ban_user_requested.emit(sender_id)


func _on_Timeout_pressed() -> void:
	timeout_user_requested.emit(sender_id, 60)


func _on_Delete_pressed() -> void:
	delete_message_requested.emit(id)


func _on_Reply_pressed() -> void:
	reply_requested.emit(id if reply_id.is_empty() else reply_id)
