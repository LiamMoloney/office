extends Node3D

@onready var time_label: Label3D = get_node_or_null("TimeLabel")

const WORKDAY_START_MINUTES := 9 * 60
const WORKDAY_END_MINUTES := 17 * 60

func _ready() -> void:
	if !GameManager.round_time_changed.is_connected(_on_round_time_changed):
		GameManager.round_time_changed.connect(_on_round_time_changed)
	if !GameManager.round_ended.is_connected(_on_round_ended):
		GameManager.round_ended.connect(_on_round_ended)

	_update_time(GameManager.get_round_progress())

func _on_round_time_changed(_elapsed_s: float, _duration_s: float, progress: float) -> void:
	_update_time(progress)

func _on_round_ended() -> void:
	_update_time(1.0)

func _update_time(progress: float) -> void:
	if !time_label:
		return

	var day_minutes := roundi(lerpf(WORKDAY_START_MINUTES, WORKDAY_END_MINUTES, clampf(progress, 0.0, 1.0)))
	var hour_24 := int(day_minutes / 60)
	var minute := day_minutes % 60
	var suffix := "   AM"
	if hour_24 >= 12:
		suffix = "   PM"

	var hour_12 := hour_24 % 12
	if hour_12 == 0:
		hour_12 = 12

	time_label.text = "%d:%02d %s" % [hour_12, minute, suffix]
