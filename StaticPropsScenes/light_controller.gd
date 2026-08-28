extends Node

@export var flicker_interval_s := 15.0

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.wait_time = maxf(0.05, flicker_interval_s)
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout() -> void:
	for light in get_tree().get_nodes_in_group("light"):
		if light.has_method("flicker"):
			light.flicker()
