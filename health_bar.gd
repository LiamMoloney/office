extends TextureProgressBar

const TEXTURE_SIZE := Vector2i(256, 26)
const BORDER_SIZE := 3
const HEALTH_GREEN := Color(0.1, 0.9, 0.2, 1.0)
const HEALTH_YELLOW := Color(1.0, 0.85, 0.08, 1.0)
const HEALTH_RED := Color(0.95, 0.08, 0.04, 1.0)

@export_enum("health", "stamina") var tracked_value: String = "health"
@export var player_node: Player
@export var high_color: Color = HEALTH_GREEN
@export var middle_color: Color = HEALTH_YELLOW
@export var low_color: Color = HEALTH_RED
@export var fill_change_speed := 0.7

var displayed_value := 0.0
var has_synced := false

func _ready() -> void:
	custom_minimum_size = Vector2(220.0, 26.0)
	min_value = 0.0
	step = 0.1
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_under = _create_under_texture()
	texture_progress = _create_progress_texture()
	texture_over = _create_outline_texture()
	stretch_margin_left = BORDER_SIZE
	stretch_margin_top = BORDER_SIZE
	stretch_margin_right = BORDER_SIZE
	stretch_margin_bottom = BORDER_SIZE
	nine_patch_stretch = true
	_sync_to_player(0.0, true)

func _process(_delta: float) -> void:
	_sync_to_player(_delta, false)

func _sync_to_player(delta: float, snap_value: bool) -> void:
	if player_node == null or !is_instance_valid(player_node):
		player_node = get_tree().get_first_node_in_group("player") as Player

	if player_node == null:
		return

	max_value = maxf(_get_target_max_value(), 0.1)
	var target_value := clampf(_get_target_value(), min_value, max_value)
	if !has_synced or snap_value:
		displayed_value = target_value
		has_synced = true
	else:
		displayed_value = move_toward(displayed_value, target_value, max_value * fill_change_speed * delta)

	value = clampf(displayed_value, min_value, max_value)
	tint_progress = _get_bar_color(float(value / max_value))

func _get_target_max_value() -> float:
	if tracked_value == "stamina" and player_node.has_method("get_max_stamina"):
		return player_node.get_max_stamina()

	return float(Player.MAX_HEALTH)

func _get_target_value() -> float:
	if tracked_value == "stamina":
		if player_node.has_method("get_stamina"):
			return player_node.get_stamina()
		return 0.0

	return float(player_node.health)

func _get_bar_color(bar_ratio: float) -> Color:
	bar_ratio = clampf(bar_ratio, 0.0, 1.0)
	if bar_ratio < 0.5:
		return low_color.lerp(middle_color, bar_ratio * 2.0)

	return middle_color.lerp(high_color, (bar_ratio - 0.5) * 2.0)

func _create_under_texture() -> Texture2D:
	var image := Image.create_empty(TEXTURE_SIZE.x, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	for y in range(TEXTURE_SIZE.y):
		for x in range(TEXTURE_SIZE.x):
			var is_border := _is_border_pixel(x, y)
			var color := Color.BLACK if is_border else Color(0.05, 0.05, 0.05, 1.0)
			if !is_border and y % 4 == 0:
				color = Color(0.09, 0.09, 0.09, 1.0)
			image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)

func _create_progress_texture() -> Texture2D:
	var image := Image.create_empty(TEXTURE_SIZE.x, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	for y in range(TEXTURE_SIZE.y):
		for x in range(TEXTURE_SIZE.x):
			if _is_border_pixel(x, y):
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue

			var stripe := int((x + y * 2) / 10) % 2
			var color := Color(1.0, 1.0, 1.0, 1.0) if stripe == 0 else Color(0.72, 0.72, 0.72, 1.0)
			if y == BORDER_SIZE:
				color = Color(1.0, 1.0, 1.0, 1.0)
			elif y == TEXTURE_SIZE.y - BORDER_SIZE - 1:
				color = Color(0.45, 0.45, 0.45, 1.0)

			image.set_pixel(x, y, color)

	return ImageTexture.create_from_image(image)

func _create_outline_texture() -> Texture2D:
	var image := Image.create_empty(TEXTURE_SIZE.x, TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	for y in range(TEXTURE_SIZE.y):
		for x in range(TEXTURE_SIZE.x):
			image.set_pixel(x, y, Color.BLACK if _is_border_pixel(x, y) else Color.TRANSPARENT)

	return ImageTexture.create_from_image(image)

func _is_border_pixel(x: int, y: int) -> bool:
	return x < BORDER_SIZE or x >= TEXTURE_SIZE.x - BORDER_SIZE or y < BORDER_SIZE or y >= TEXTURE_SIZE.y - BORDER_SIZE
