extends StaticBody3D
class_name PhoneStatic

@onready var interactable: Interactable = $Interactable
@onready var call_ready_light: Node3D = $CallReadyLight
@onready var phone_dialog: CanvasLayer = $PhoneDialog
@onready var dialog_label: Label = $PhoneDialog/Panel/DialogLabel
@onready var info_label: Label = $PhoneDialog/Panel/InfoLabel
@onready var option_buttons: Array[Button] = [
	$PhoneDialog/Panel/Option1Button,
	$PhoneDialog/Panel/Option2Button,
	$PhoneDialog/Panel/Option3Button
]
@onready var pass_button: Button = $PhoneDialog/Panel/PassButton
@onready var close_sale_button: Button = $PhoneDialog/Panel/CloseSaleButton

var player: Player
var is_using := false

func _ready() -> void:
	call_ready_light.visible = false
	pass_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	close_sale_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	pass_button.text = "Hang Up"
	close_sale_button.text = "No App"
	pass_button.pressed.connect(_stop_using_phone)
	close_sale_button.disabled = true
	for button in option_buttons:
		button.disabled = true
		button.text = "-"
	phone_dialog.visible = false

func _input(event: InputEvent) -> void:
	if !is_using:
		return

	if event.is_action_pressed("esc"):
		_stop_using_phone()
		get_viewport().set_input_as_handled()

func _on_interactable_interacted(actor: Node) -> void:
	if !(actor is Player):
		return

	_start_using_phone(actor)

func _start_using_phone(actor: Player) -> void:
	player = actor
	is_using = true
	print("on phone")

	interactable.is_interactable = false
	player.input_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_phone_dialog()

func _stop_using_phone() -> void:
	is_using = false
	phone_dialog.visible = false
	interactable.is_interactable = true

	if player:
		player.input_locked = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _show_phone_dialog() -> void:
	phone_dialog.visible = true
	dialog_label.text = "Phone is interactable. No phone app is wired yet."
	info_label.text = "Press Hang Up or Esc to leave."
	pass_button.disabled = false
	close_sale_button.disabled = true
	for button in option_buttons:
		button.disabled = true
		button.text = "-"
