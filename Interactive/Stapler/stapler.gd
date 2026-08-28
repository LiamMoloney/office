extends RigidBody3D
class_name StaplerStatic

@export var held_rotation_offset_degrees := Vector3(0.0, 90.0, 0.0)

@onready var interactable: Interactable = $Interactable

var holder: Player
var is_held := false
var body_collision_layer := 0
var body_collision_mask := 0
var interactable_collision_layer := 0

func _ready() -> void:
	body_collision_layer = collision_layer
	body_collision_mask = collision_mask
	interactable_collision_layer = interactable.collision_layer
	freeze = true

func get_pickup_type() -> String:
	return "stapler"

func drop_from(actor: Player) -> void:
	if holder != actor:
		return

	holder.clear_held_item(self)
	holder = null
	is_held = false
	_reparent_to_world()
	global_position = actor.get_drop_transform().origin
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = body_collision_layer
	collision_mask = body_collision_mask
	interactable.is_interactable = true
	interactable.collision_layer = interactable_collision_layer
	freeze = false
	sleeping = false

func _on_interactable_interacted(actor: Node) -> void:
	if !(actor is Player):
		return

	var player := actor as Player
	if SaleStatus.currSaleState == SaleStatus.SaleState.STAPLE_REPORT and player.is_holding_pickup_type("paper"):
		var held_paper = player.get_held_item()
		if held_paper != null and held_paper.has_method("staple"):
			held_paper.staple()
			print("report stapled")
		return

	_pick_up(player)

func _pick_up(actor: Player) -> void:
	if !actor.pickup_item(self):
		return

	holder = actor
	is_held = true
	freeze = true
	collision_layer = 0
	collision_mask = 0
	interactable.is_interactable = false
	interactable.collision_layer = 0
	_reparent_to_hand(actor)

func _reparent_to_hand(actor: Player) -> void:
	var saved_scale := scale
	var hold_parent := actor.get_hold_parent()
	if get_parent() != hold_parent:
		get_parent().remove_child(self)
		hold_parent.add_child(self)

	scale = saved_scale
	position = Vector3.ZERO
	rotation_degrees = held_rotation_offset_degrees

func _reparent_to_world() -> void:
	var saved_scale := scale
	var saved_rotation := global_rotation
	var world_parent := get_tree().current_scene
	if get_parent() != world_parent:
		get_parent().remove_child(self)
		world_parent.add_child(self)

	scale = saved_scale
	global_rotation = saved_rotation
