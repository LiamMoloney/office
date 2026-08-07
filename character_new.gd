extends CharacterBody3D
class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const FRICTION = 25
const HORIZONTAL_ACCELERATION = 30
const MAX_SPEED=5

const MAX_HEALTH=100
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var shape_cast: ShapeCast3D = $Camera3D/ShapeCast3D

@onready var camera = $Camera3D
##Core Attributes
var input_locked := false

##Game Attirbutes
var health = 100
var reputation = 75
var money = 0




func _ready():
	add_to_group("player")
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	
func _input(event: InputEvent) -> void:
	if input_locked:
		return

	if event.is_action_pressed("interact"):
		var target := _get_interactable_target()
		if target:
			target.interact(self)

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
	if event is InputEventMouseButton:
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
	_movement_input(delta)
	
	move_and_slide()
	force_update_transform()
	
func _movement_input(delta):
	if input_locked:
		return
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
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction *= SPEED
	velocity.x = move_toward(velocity.x,direction.x, HORIZONTAL_ACCELERATION * delta)
	velocity.z = move_toward(velocity.z,direction.z, HORIZONTAL_ACCELERATION * delta)

	var angle=2
	#rotation_degrees=Vector3(input_dir.normalized().y*angle,rotation_degrees.y,-input_dir.normalized().x*angle)
	var t = delta * 6
	if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED: 
		rotation_degrees=rotation_degrees.lerp(Vector3(input_dir.normalized().y*angle,rotation_degrees.y,-input_dir.normalized().x*angle),t)
	
	
