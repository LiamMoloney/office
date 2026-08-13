extends Node3D

@onready var time_label: Label3D = get_node_or_null("TimeLabel")

func _ready() -> void:
	_update_time()

func _process(_delta: float) -> void:
	_update_time()

func _update_time() -> void:
	if !time_label:
		return

	var now := Time.get_time_dict_from_system()
	var hour_24 := int(now.get("hour", 9))
	var minute := int(now.get("minute", 0))
	var suffix := "AM"
	if hour_24 >= 12:
		suffix = "PM"

	var hour_12 := hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12

	time_label.text = "%d:%02d %s" % [hour_12, minute, suffix]
