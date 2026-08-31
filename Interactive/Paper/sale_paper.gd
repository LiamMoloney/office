extends RigidBody3D
class_name SalePaper

@export var held_rotation_offset_degrees := Vector3( 30, -70, 0)
@export var launch_local_direction := Vector3.FORWARD
@export_range(0.0, 10.0, 0.05) var launch_impulse := 0.5
@export_range(-10.0, 10.0, 0.05) var launch_upward_impulse := 0.0
@export_range(0.0, 5.0, 0.1) var launch_gravity_scale := 1.0
@export var launch_torque_impulse := Vector3.ZERO

@onready var interactable: Interactable = $Interactable
@onready var company_label: Label3D = $CompanyLabel
@onready var stapled_marker: MeshInstance3D = $StapledMarker

var holder: Player
var is_held := false
var is_stapled := false
var sale := {}
var payout := 0
var body_collision_layer := 0
var body_collision_mask := 0
var interactable_collision_layer := 0

func _ready() -> void:
	body_collision_layer = collision_layer
	body_collision_mask = collision_mask
	interactable_collision_layer = interactable.collision_layer
	stapled_marker.visible = false

func setup(sale_data: Dictionary) -> void:
	sale = sale_data.duplicate(true)
	payout = int(sale.get("payout", 0))
	company_label.text = "%s Sale" % sale.get("company", "Unknown Company")

func get_pickup_type() -> String:
	return "paper"

func staple() -> void:
	if is_stapled:
		return

	is_stapled = true
	stapled_marker.visible = true

func is_ready_for_stanley() -> bool:
	return is_stapled

func get_payout() -> int:
	return payout

func launch() -> void:
	holder = null
	is_held = false
	gravity_scale = launch_gravity_scale
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	collision_layer = body_collision_layer
	collision_mask = body_collision_mask
	interactable.is_interactable = true
	interactable.collision_layer = interactable_collision_layer

	var launch_direction := launch_local_direction
	if launch_direction.length_squared() <= 0.001:
		launch_direction = Vector3.FORWARD

	var start_transform := global_transform
	var world_impulse := (start_transform.basis * launch_direction.normalized()).normalized() * launch_impulse
	world_impulse += Vector3.UP * launch_upward_impulse
	apply_central_impulse(world_impulse)
	if launch_torque_impulse.length_squared() > 0.0:
		apply_torque_impulse(start_transform.basis * launch_torque_impulse)

func turn_in() -> void:
	if holder:
		holder.clear_held_item(self)
	holder = null
	queue_free()

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
	if player.is_holding_pickup_type("stapler"):
		var held_stapler := player.get_held_item() as Stapler
		if held_stapler != null and held_stapler.can_staple():
			staple()
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
