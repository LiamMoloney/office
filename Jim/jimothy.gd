extends CharacterBody3D

@export var move_speed := 1

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var move_direction := Vector3.ZERO

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var facing_player = true
var following_player = true

var player: Node3D
var sabotagable_items: Array[Sabotagable] = []

func _ready() -> void:
	add_to_group("jim")
	randomize()
	player = _get_player()
	$AnimationPlayer.play("Walk")
	
	
func _process(_delta: float) -> void:
	_sabotage_by_id("stapler", 0)
	_sabotage_by_id("phone", 0)
	nav_agent.set_target_position(player.position)

func _physics_process(delta: float) -> void:
	if player == null or !is_instance_valid(player):
		player = _get_player()

	if !is_on_floor():
		velocity.y -= gravity * delta
	var dest = nav_agent.get_next_path_position()
	var local_dest = dest - global_position
	var direction = local_dest.normalized()
	
	velocity = direction * move_speed
	
	if player != null and facing_player:
		_stare_at_player()
		
	

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

func _sabotage_by_id(item_id : String, level : int) -> void:
	for item in sabotagable_items:
		if item == null or !is_instance_valid(item):
			continue

		if item.sabotagable_id == item_id:
			item.sabotage()
			return
