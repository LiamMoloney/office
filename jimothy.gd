extends CharacterBody3D

@export var move_speed := 1

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var move_direction := Vector3.ZERO

var player: Node3D
var sabotagable_items: Array[Sabotagable] = []

func _ready() -> void:
	add_to_group("jim")
	randomize()
	player = _get_player()
	$AnimationPlayer.play("Walk")

func _process(_delta: float) -> void:
	_sabotage_available_stapler()

func _physics_process(delta: float) -> void:
	if player == null or !is_instance_valid(player):
		player = _get_player()

	if !is_on_floor():
		velocity.y -= gravity * delta

	if player != null:
		var direction := player.global_position - global_position
		direction.y = 0
		direction = direction.normalized()

		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		_stare_at_player()
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()


func _stare_at_player() -> void:
	if player == null or !is_instance_valid(player):
		return
	var stare_target := player.global_position
	stare_target.y = global_position.y
	look_at(stare_target, Vector3.UP)

func _get_player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D

func register_sabotagable(item: Sabotagable) -> void:
	if item == null or !is_instance_valid(item) or sabotagable_items.has(item):
		return

	sabotagable_items.append(item)

func unregister_sabotagable(item: Sabotagable) -> void:
	sabotagable_items.erase(item)

func _sabotage_available_stapler() -> void:
	for item in sabotagable_items:
		if item == null or !is_instance_valid(item):
			continue

		if item.sabotagable_id == "stapler":
			item.sabotage()
			return
