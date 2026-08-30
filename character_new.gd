extends CharacterBody3D
class_name Player

const SPEED = 2.5
const JUMP_VELOCITY = 4.5
const FRICTION = 25
const HORIZONTAL_ACCELERATION = 30
const MAX_SPEED=5

const MAX_HEALTH=100
@export var debug_damage_amount := 15.0
@export var sprint_speed_multiplier := 2.0
@export_range(0.5, 20.0, 0.1) var sprint_time_seconds := 5.0
@export_range(0.0, 5.0, 0.1) var stamina_refill_delay := 1.0
@export_range(0.5, 20.0, 0.1) var stamina_refill_seconds := 3.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var shape_cast: ShapeCast3D = $Camera3D/ShapeCast3D

@onready var camera = $Camera3D
@onready var hand: Node3D = $Camera3D/Hand
##Core Attributes
var input_locked := false
var held_item: Node3D

##Game Attirbutes
var health = 100
var reputation = 75
var money = 0
var stamina := 0.0
var stamina_refill_wait := 0.0
var sprint_input_active := false
var sprint_exhausted := false




func _ready():
	add_to_group("player")
	stamina = get_max_stamina()
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if InputMap.has_action("debugAction") and event.is_action_pressed("debugAction"):
		if !(event is InputEventKey) or !event.echo:
			take_damage(debug_damage_amount)

	if input_locked:
		return

	if event.is_action_pressed("interact"):
		var target := _get_interactable_target()
		if target:
			target.interact(self)

	if event.is_action_pressed("drop_item"):
		drop_held_item()

func _get_interactable_target() -> Interactable:
	shape_cast.force_shapecast_update()

	if !shape_cast.is_colliding():
		return null

	var collider = shape_cast.get_collision_result()[0]["collider"]
	if collider is Interactable:
		return collider

	return null

func _unhandled_input(event):
	if !input_locked:
		if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * .005)
			camera.rotate_x(-event.relative.y * .005)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	if !input_locked and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT \
		and event.pressed \
		and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_key_input(event):
	if (input_locked):
		return
	if Input.is_action_just_pressed("esc"):
		if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	if input_locked:
		velocity.x = 0
		velocity.z = 0
	var is_sprinting := _movement_input(delta)
	_update_stamina(delta, is_sprinting)

	move_and_slide()
	force_update_transform()

func _movement_input(delta) -> bool:
	if input_locked:
		sprint_input_active = false
		return false
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		velocity.y += JUMP_VELOCITY
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Vector3.ZERO
	var movetoward = Vector3.ZERO
	input_dir.x = Input.get_vector("left", "right", "forward", "backward").x
	input_dir.y = Input.get_vector("left", "right", "forward", "backward").y
	input_dir=input_dir.normalized()
	var has_movement_input := input_dir.length_squared() > 0.0
	var wants_sprint := InputMap.has_action("sprint") and Input.is_action_pressed("sprint")
	sprint_input_active = wants_sprint and has_movement_input and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var is_sprinting := sprint_input_active and stamina > 0.0 and !sprint_exhausted
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var current_speed := SPEED
	if is_sprinting:
		current_speed *= sprint_speed_multiplier
	direction *= current_speed
	velocity.x = move_toward(velocity.x,direction.x, HORIZONTAL_ACCELERATION * delta)
	velocity.z = move_toward(velocity.z,direction.z, HORIZONTAL_ACCELERATION * delta)

	var angle=2
	#rotation_degrees=Vector3(input_dir.normalized().y*angle,rotation_degrees.y,-input_dir.normalized().x*angle)
	var t = delta * 6
	if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		rotation_degrees=rotation_degrees.lerp(Vector3(input_dir.normalized().y*angle,rotation_degrees.y,-input_dir.normalized().x*angle),t)

	return is_sprinting

func _update_stamina(delta: float, is_sprinting: bool) -> void:
	var max_stamina := get_max_stamina()
	stamina = clampf(stamina, 0.0, max_stamina)
	if is_sprinting:
		stamina = maxf(stamina - delta, 0.0)
		stamina_refill_wait = stamina_refill_delay
		if stamina <= 0.0:
			sprint_exhausted = true
		return

	if !sprint_input_active:
		sprint_exhausted = false
	elif stamina <= 0.0:
		sprint_exhausted = true

	if stamina_refill_wait > 0.0:
		stamina_refill_wait = maxf(stamina_refill_wait - delta, 0.0)
		return

	var refill_rate := max_stamina / maxf(stamina_refill_seconds, 0.1)
	stamina = minf(stamina + refill_rate * delta, max_stamina)
	if stamina >= max_stamina:
		sprint_exhausted = false

func take_damage(amount: float) -> void:
	health = clampf(float(health) - amount, 0.0, float(MAX_HEALTH))

func heal(amount: float) -> void:
	health = clampf(float(health) + amount, 0.0, float(MAX_HEALTH))

func get_max_stamina() -> float:
	return maxf(sprint_time_seconds, 0.1)

func get_stamina() -> float:
	return clampf(stamina, 0.0, get_max_stamina())

func pickup_item(item: Node3D) -> bool:
	if get_held_item() != null:
		return false

	held_item = item
	return true

func clear_held_item(item: Node3D) -> void:
	if held_item == item:
		held_item = null

func drop_held_item() -> void:
	var item = get_held_item()
	if item == null:
		return

	if item.has_method("drop_from"):
		item.drop_from(self)
	else:
		clear_held_item(item)

func get_held_item() -> Node3D:
	if held_item != null and !is_instance_valid(held_item):
		held_item = null

	return held_item

func is_holding_pickup_type(pickup_type: String) -> bool:
	var item = get_held_item()
	if item == null or !item.has_method("get_pickup_type"):
		return false

	return item.get_pickup_type() == pickup_type

func get_hold_transform() -> Transform3D:
	return hand.global_transform

func get_hold_parent() -> Node3D:
	return hand

func get_drop_transform() -> Transform3D:
	var drop_transform = get_hold_transform()
	drop_transform.origin.y = maxf(drop_transform.origin.y, global_position.y + 0.35)
	return drop_transform
