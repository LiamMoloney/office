extends Area3D
class_name Sabotagable

signal sabotage_changed(is_sabotaged: bool)

const JIM_COLLISION_MASK := 1 << 3

@export var sabotagable_id := ""

var sabotaged := false

func _ready() -> void:
	if sabotagable_id == "" and get_parent() != null:
		sabotagable_id = get_parent().name

	add_to_group("sabotagable")
	collision_layer = 0
	collision_mask = JIM_COLLISION_MASK
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().call_group("jim", "unregister_sabotagable", self)

func sabotage() -> void:
	if sabotaged:
		return

	sabotaged = true
	sabotage_changed.emit(sabotaged)

func fix() -> void:
	if !sabotaged:
		return

	sabotaged = false
	sabotage_changed.emit(sabotaged)

func get_sabotage_owner() -> Node:
	return get_parent()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("jim") and body.has_method("register_sabotagable"):
		body.call("register_sabotagable", self)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("jim") and body.has_method("unregister_sabotagable"):
		body.call("unregister_sabotagable", self)
