extends Node3D

@onready var interact_label = $Label3D

@onready var shape_cast: ShapeCast3D = $ShapeCast3D

var current_interactions := []
var can_interact = true 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
