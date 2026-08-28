extends StaticBody3D
class_name PhoneStatic

const MAX_PHONE_DIGITS := 5

@onready var interactable: Interactable = $Interactable
@onready var call_ready_light: Node3D = $CallReadyLight
@onready var phone_dialog: CanvasLayer = $PhoneDialog
@onready var dialog_box = $PhoneDialog/Dialog
@onready var call_button: Button = $PhoneDialog/KeypadArea/KeypadActions/CallButton
@onready var hang_up_button: Button = $PhoneDialog/KeypadArea/KeypadActions/HangUpButton
@onready var impression_button: Button = $PhoneDialog/FirstImpressionBar/ImpressionButton
@onready var impression_bar: Control = $PhoneDialog/FirstImpressionBar
@onready var impression_track: Control = $PhoneDialog/FirstImpressionBar/Track
@onready var dial_display: Label = $PhoneDialog/KeypadArea/DialDisplay/NumberLabel
@onready var dial_pad: GridContainer = $PhoneDialog/KeypadArea/DialPad
@onready var dial_buttons: Array[Button] = [
	$PhoneDialog/KeypadArea/DialPad/Dial1Button,
	$PhoneDialog/KeypadArea/DialPad/Dial2Button,
	$PhoneDialog/KeypadArea/DialPad/Dial3Button,
	$PhoneDialog/KeypadArea/DialPad/Dial4Button,
	$PhoneDialog/KeypadArea/DialPad/Dial5Button,
	$PhoneDialog/KeypadArea/DialPad/Dial6Button,
	$PhoneDialog/KeypadArea/DialPad/Dial7Button,
	$PhoneDialog/KeypadArea/DialPad/Dial8Button,
	$PhoneDialog/KeypadArea/DialPad/Dial9Button
]
@onready var dial_zero_button: Button = $PhoneDialog/KeypadArea/DialPad/Dial0Button

var impression_indicator: ColorRect
var player: Player
var is_using := false
var dialed_number := ""
var last_player_line := ""
var impression_progress := 0.0
var impression_direction := 1.0
var impression_speed := 1.5
var sale_finishers := [
	"You've got yourself a deal.",
	"Sounds good. Have a nice day.",
	"Alright, that works for me.",
	"Perfect. Let's do it.",
	"That all sounds good on my end.",
	"Okay, you've convinced me.",
	"Great, I'm happy to move forward.",
	"Yeah, I can agree to that.",
	"Consider it done.",
	"Excellent. I'll be expecting the paperwork."
]
var lost_client_responses := [
	"I don't think this is a fit for us.",
	"We're going to pass, but thanks for your time...",
	"Sorry, I'm not interested.",
	"Oh please oh please stop calling this number",
	"I'll have to say no, I'm sorry but I just don't really care for you",
	"Thanks, but we're going in a different direction.",
	"I don't think we can move forward today.",
	"No thanks. Have a good one."
]

func _ready() -> void:
	call_ready_light.visible = false
	call_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	hang_up_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	impression_button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_create_impression_indicator()
	call_button.pressed.connect(_on_call_button_pressed)
	hang_up_button.pressed.connect(_on_hang_up_pressed)
	impression_button.pressed.connect(_on_impression_button_pressed)
	dialog_box.option_selected.connect(_on_dialog_option_selected)
	impression_button.disabled = true
	for i in range(dial_buttons.size()):
		dial_buttons[i].pressed.connect(_on_dial_button_pressed.bind(i + 1))
	dial_zero_button.pressed.connect(_on_dial_button_pressed.bind(0))
	impression_bar.visible = false
	dial_pad.visible = true
	_update_dial_display()
	phone_dialog.visible = false
	SaleStatus.sale_changed.connect(_refresh_call_ready_light)
	_refresh_call_ready_light()

func _process(delta: float) -> void:
	if !is_using or SaleStatus.currSaleState != SaleStatus.SaleState.FIRST_IMPRESSION:
		return

	impression_progress += impression_direction * impression_speed * delta
	if impression_progress >= 1.0:
		impression_progress = 1.0
		impression_direction = -1.0
	elif impression_progress <= 0.0:
		impression_progress = 0.0
		impression_direction = 1.0

	_update_impression_indicator_position()

func _input(event: InputEvent) -> void:
	if !is_using:
		return

	if event.is_action_pressed("esc"):
		_close_phone(_should_reset_after_close())
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

func _on_hang_up_pressed() -> void:
	_reset_phone_entry()
	if _can_clear_sale_on_hang_up():
		SaleStatus.clear_sale()
	_close_phone(true)

func _close_phone(should_reset_state: bool = false) -> void:
	if should_reset_state:
		_reset_phone_entry()

	is_using = false
	phone_dialog.visible = false
	interactable.is_interactable = true

	if player:
		player.input_locked = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _should_reset_after_close() -> bool:
	return SaleStatus.closed_successfully and SaleStatus.currSaleState in [
		SaleStatus.SaleState.PRINT_REPORT,
		SaleStatus.SaleState.STAPLE_REPORT,
		SaleStatus.SaleState.TURN_IN_REPORT,
		SaleStatus.SaleState.PAID
	]

func _can_clear_sale_on_hang_up() -> bool:
	return SaleStatus.currSaleState in [
		SaleStatus.SaleState.PHONE_LOADED,
		SaleStatus.SaleState.FIRST_IMPRESSION,
		SaleStatus.SaleState.PROMPT,
		SaleStatus.SaleState.READY_TO_CLOSE,
		SaleStatus.SaleState.CLOSED,
		SaleStatus.SaleState.PAID
	]

func _reset_phone_entry() -> void:
	dialed_number = ""
	last_player_line = ""
	_update_dial_display()

func _show_phone_dialog() -> void:
	phone_dialog.visible = true
	hang_up_button.disabled = false
	if SaleStatus.currSaleState == SaleStatus.SaleState.NONE or SaleStatus.currSaleState == SaleStatus.SaleState.PHONE_LOADED:
		_show_no_sale_loaded()
		return

	_show_current_sale_phase()

func _show_no_sale_loaded() -> void:
	impression_bar.visible = false
	dialog_box.clear_options()
	dialog_box.hide_sale_result()
	last_player_line = ""
	_update_dial_display()
	dialog_box.show_dialog("", "Dial a number.", "Phone")
	impression_button.disabled = true

func _show_current_sale_phase() -> void:
	match SaleStatus.currSaleState:
		SaleStatus.SaleState.FIRST_IMPRESSION:
			_show_first_impression()
		SaleStatus.SaleState.PROMPT:
			_show_prompt_minigame()
		SaleStatus.SaleState.READY_TO_CLOSE:
			_show_ready_to_close()
		SaleStatus.SaleState.CLOSED:
			_show_closed_sale()
		SaleStatus.SaleState.PRINT_REPORT:
			_show_report_ready()
		SaleStatus.SaleState.STAPLE_REPORT:
			_show_report_ready()
		SaleStatus.SaleState.TURN_IN_REPORT:
			_show_report_ready()
		SaleStatus.SaleState.PAID:
			_show_report_ready()
		_:
			_show_no_sale_loaded()

func _show_first_impression() -> void:
	dialog_box.clear_options()
	dialog_box.hide_sale_result()
	last_player_line = ""
	dialog_box.show_dialog("", SaleStatus.current_sale.get("client_greeting", "Hello?"), "Phone")
	impression_bar.visible = true
	impression_button.disabled = false
	impression_button.text = "Make First Impression"
	impression_progress = randf()
	impression_direction = [-1.0, 1.0].pick_random()
	_update_impression_indicator_position()

func _show_prompt_minigame() -> void:
	impression_bar.visible = false
	dialog_box.hide_sale_result()
	var target_text := ""
	if SaleStatus.prompt_step_index == 0:
		target_text = SaleStatus.prompt_opener if SaleStatus.prompt_opener != "" else "Okay. I'm listening."
	else:
		target_text = _get_client_followup()
	dialog_box.show_dialog(last_player_line, target_text, "Phone")
	impression_button.disabled = true
	impression_button.text = "First Impression Made"
	var options := []
	for option in SaleStatus.prompt_options:
		options.append(option["text"])
	dialog_box.set_options(options)

func _show_ready_to_close() -> void:
	impression_bar.visible = false
	dialog_box.hide_sale_result()
	dialog_box.show_dialog(last_player_line, _get_client_followup(), "Phone")
	dialog_box.set_options(["Close Sale"])
	impression_button.disabled = true

func _show_closed_sale() -> void:
	impression_bar.visible = false
	if SaleStatus.closed_successfully:
		dialog_box.show_dialog(last_player_line, _get_sale_finisher(), "Phone")
	else:
		dialog_box.show_dialog(last_player_line, _get_lost_client_response(), "Phone")
	dialog_box.show_sale_result(SaleStatus.closed_successfully)
	dialog_box.clear_options()
	impression_button.disabled = true

func _show_report_ready() -> void:
	impression_bar.visible = false
	dialog_box.show_sale_result(true)
	match SaleStatus.currSaleState:
		SaleStatus.SaleState.PRINT_REPORT:
			dialog_box.show_dialog(last_player_line, _get_sale_finisher(), "Phone")
		SaleStatus.SaleState.STAPLE_REPORT:
			dialog_box.show_dialog(last_player_line, "Report printed.", "Phone")
		SaleStatus.SaleState.TURN_IN_REPORT:
			dialog_box.show_dialog(last_player_line, "Report stapled.", "Phone")
		SaleStatus.SaleState.PAID:
			dialog_box.show_dialog(last_player_line, "Thanks.", "Phone")
	dialog_box.clear_options()
	impression_button.disabled = true

func _on_impression_button_pressed() -> void:
	var quality := _get_impression_quality()
	SaleStatus.set_first_impression_quality(quality)
	_show_current_sale_phase()

func _on_dialog_option_selected(option_index: int) -> void:
	if SaleStatus.currSaleState == SaleStatus.SaleState.READY_TO_CLOSE:
		last_player_line = "Close Sale"
		dialog_box.show_my_dialog(last_player_line)
		SaleStatus.close_sale()
		_show_current_sale_phase()
		return

	if SaleStatus.currSaleState != SaleStatus.SaleState.PROMPT:
		return

	if option_index < 0 or option_index >= SaleStatus.prompt_options.size():
		return

	last_player_line = SaleStatus.prompt_options[option_index]["text"]
	dialog_box.show_my_dialog(last_player_line)
	SaleStatus.choose_prompt_option(option_index)
	_show_current_sale_phase()

func _on_dial_button_pressed(number: int) -> void:
	if dialed_number.length() >= MAX_PHONE_DIGITS:
		return

	dialed_number += str(number)
	_update_dial_display()

func _on_call_button_pressed() -> void:
	if !_can_start_new_call():
		return

	last_player_line = dialed_number
	if SaleStatus.currSaleState != SaleStatus.SaleState.NONE:
		SaleStatus.clear_sale()

	if SaleStatus.load_sale_by_phone_number(dialed_number):
		_reset_phone_entry()
		SaleStatus.start_call()
		_show_current_sale_phase()
		return

	_show_no_one_picked_up()

func _can_start_new_call() -> bool:
	return SaleStatus.currSaleState in [
		SaleStatus.SaleState.NONE,
		SaleStatus.SaleState.PHONE_LOADED,
		SaleStatus.SaleState.CLOSED,
		SaleStatus.SaleState.PAID
	]

func _show_no_one_picked_up() -> void:
	impression_bar.visible = false
	dialog_box.clear_options()
	dialog_box.hide_sale_result()
	dialog_box.show_dialog("", "No one picked up.", "Phone")
	dialed_number = ""
	_update_dial_display()

func _update_dial_display() -> void:
	if dial_display == null:
		return

	dial_display.text = dialed_number

func _get_client_followup() -> String:
	if SaleStatus.prompt_score > 0:
		return [
			"No way! That sounds freaking awesome!",
			"Yippeee!",
			"alriiiight im listening",
			"super duper"
		].pick_random()

	if SaleStatus.prompt_score == 0:
		return [
			"Maybe. What are you asking me to sign?",
			"meh ok",
			"Go ahead and wrap this up."
		].pick_random()

	return [
		"Why don't you get lost",
		"I'm not sure you read the room.",
		"I do not like you very much... whats your name again?",
		"Oh really... give me your name and badge number",
		"That sounds... stupid",
		"Bro really said I need paper...",
		"Yeah actually my dogs uncle in law just croaked so if you could stop yapping",
		"Hello? Hello...?"
	].pick_random()

func _get_sale_finisher() -> String:
	return sale_finishers.pick_random()

func _get_lost_client_response() -> String:
	return lost_client_responses.pick_random()

func _get_impression_quality() -> float:
	if impression_indicator == null or impression_track == null:
		return 0.0

	var track_width := maxf(impression_track.size.x, 1.0)
	var indicator_center := impression_indicator.position.x + (impression_indicator.size.x * 0.5)
	var gradient_center := impression_track.position.x + (track_width * 0.5)
	var distance_from_center := absf(indicator_center - gradient_center) / track_width
	if distance_from_center <= 0.08:
		return 1.0

	return clampf(1.0 - ((distance_from_center - 0.08) / 0.42), 0.0, 1.0)

func _create_impression_indicator() -> void:
	impression_indicator = ColorRect.new()
	impression_indicator.color = Color.WHITE
	impression_indicator.size = Vector2(8.0, 28.0)
	impression_indicator.position.y = -5.0
	impression_bar.add_child(impression_indicator)
	impression_indicator.move_to_front()

func _update_impression_indicator_position() -> void:
	if impression_indicator == null or impression_track == null:
		return

	var track_width := maxf(impression_track.size.x, 0.0)
	var indicator_center_x := impression_track.position.x + (track_width * impression_progress)
	impression_indicator.position.x = indicator_center_x - (impression_indicator.size.x * 0.5)
	impression_indicator.position.y = impression_track.position.y + (impression_track.size.y * 0.5) - (impression_indicator.size.y * 0.5)

func _refresh_call_ready_light() -> void:
	call_ready_light.visible = SaleStatus.currSaleState == SaleStatus.SaleState.PHONE_LOADED
