extends StaticBody3D
class_name PCStatic

@onready var interactable: Interactable = $Interactable
@onready var pc_cam: Camera3D = $PCCam
@onready var pc_control: Control = $SubViewport/PCControl
@onready var sub_viewport: SubViewport = $SubViewport

var player: Player
var is_using := false

func _input(event: InputEvent) -> void:
	if !is_using:
		return

	if event.is_action_pressed("esc"):
		_stop_using_computer()
		get_viewport().set_input_as_handled()
	
	elif event is InputEventMouseMotion:
		pc_control.pc_mouse_pos += event.relative
		pc_control.pc_mouse_pos.x = clamp(pc_control.pc_mouse_pos.x, 0.0, sub_viewport.size.x - 10.0)
		pc_control.pc_mouse_pos.y = clamp(pc_control.pc_mouse_pos.y, 0.0, sub_viewport.size.y - 10.0)
		pc_control.update_cursor_pos()
	
	elif event is InputEventMouseButton: 
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MASK_RIGHT or event.button_index == MOUSE_BUTTON_MASK_MIDDLE:
			var mouse_event_copy = InputEventMouseButton.new()
			mouse_event_copy.button_index = event.button_index
			mouse_event_copy.pressed = event.pressed
			mouse_event_copy.position = pc_control.pc_mouse_pos
			mouse_event_copy.global_position = pc_control.pc_mouse_pos ##not technically a copy because we change the pos
			sub_viewport.push_input(mouse_event_copy)
func _on_interactable_interacted(actor: Node) -> void:
	if !(actor is Player):
		return

	_start_using_computer(actor)

func _start_using_computer(actor: Player) -> void:
	player = actor
	is_using = true
	print("on computer")

	interactable.is_interactable = false
	player.input_locked = true
	pc_cam.current = true

func _stop_using_computer() -> void:
	is_using = false
	pc_cam.current = false
	interactable.is_interactable = true

	if player:
		player.input_locked = false
		player.camera.current = true
