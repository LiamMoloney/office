extends Control
class_name OneShotDialog

@export_range(0.1, 10.0, 0.1) var visible_seconds := 1.5

@onready var text_label: Label = $BarkArea/TextLabel

var _hide_request_id := 0

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label.visible_characters = -1

func show_one_shot(text: String) -> void:
	_hide_request_id += 1
	var hide_request_id := _hide_request_id
	text_label.text = text
	visible = true
	get_tree().create_timer(visible_seconds).timeout.connect(_hide.bind(hide_request_id))

func _hide(hide_request_id: int) -> void:
	if hide_request_id != _hide_request_id:
		return

	visible = false
