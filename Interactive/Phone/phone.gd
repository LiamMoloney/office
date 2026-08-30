extends StaticBody3D
class_name PhoneStatic

signal sale_queued(sale: Dictionary)

const MAX_PHONE_DIGITS := 5
const CORRECT_PROMPT_BONUS := 0.20
const NEUTRAL_PROMPT_VARIANCE := 0.10
const BAD_PROMPT_END_CHANCE := 0.50
const MAX_PROMPT_STEPS := 4

enum CallState {
	IDLE,
	FIRST_IMPRESSION,
	PROMPT,
	READY_TO_CLOSE,
	RESULT
}

@onready var interactable: Interactable = $Interactable
@onready var sabotagable: Sabotagable = $Sabotagable
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
var call_state := CallState.IDLE
var current_sale := {}
var success_chance := 0.0
var first_impression_quality := 0.0
var prompt_attribute := ""
var prompt_option_type := ""
var prompt_opener := ""
var prompt_options := []
var prompt_steps := []
var prompt_step_index := 0
var prompt_score := 0
var closed_successfully := false
var sale_queued_for_print := false
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
	_connect_to_printers()
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
	_update_call_ready_light()
	phone_dialog.visible = false

func _process(delta: float) -> void:
	if !is_using or call_state != CallState.FIRST_IMPRESSION:
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
		_close_phone()
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
	_clear_call()
	_close_phone()

func _close_phone() -> void:
	is_using = false
	phone_dialog.visible = false
	interactable.is_interactable = true

	if player:
		player.input_locked = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _clear_call() -> void:
	current_sale = {}
	success_chance = 0.0
	first_impression_quality = 0.0
	prompt_attribute = ""
	prompt_option_type = ""
	prompt_opener = ""
	prompt_options = []
	prompt_steps = []
	prompt_step_index = 0
	prompt_score = 0
	closed_successfully = false
	sale_queued_for_print = false
	call_state = CallState.IDLE
	_reset_phone_entry()
	_update_call_ready_light()

func _reset_phone_entry() -> void:
	dialed_number = ""
	last_player_line = ""
	_update_dial_display()

func _show_phone_dialog() -> void:
	phone_dialog.visible = true
	hang_up_button.disabled = false
	if call_state == CallState.IDLE:
		_show_no_call()
		return

	_show_current_call_phase()

func _show_no_call() -> void:
	impression_bar.visible = false
	dialog_box.clear_options()
	dialog_box.hide_sale_result()
	last_player_line = ""
	_update_dial_display()
	dialog_box.show_dialog("", "Dial a number.", "Phone")
	impression_button.disabled = true

func _show_current_call_phase() -> void:
	match call_state:
		CallState.FIRST_IMPRESSION:
			_show_first_impression()
		CallState.PROMPT:
			_show_prompt_minigame()
		CallState.READY_TO_CLOSE:
			_show_ready_to_close()
		CallState.RESULT:
			_show_closed_sale()
		_:
			_show_no_call()

func _show_first_impression() -> void:
	dialog_box.clear_options()
	dialog_box.hide_sale_result()
	last_player_line = ""
	dialog_box.show_dialog("", current_sale.get("client_greeting", "Hello?"), "Phone")
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
	if prompt_step_index == 0:
		target_text = prompt_opener if prompt_opener != "" else "Okay. I'm listening."
	else:
		target_text = _get_client_followup()
	dialog_box.show_dialog(last_player_line, target_text, "Phone")
	impression_button.disabled = true
	impression_button.text = "First Impression Made"
	var options := []
	for option in prompt_options:
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
	if closed_successfully:
		dialog_box.show_dialog(last_player_line, _get_sale_finisher(), "Phone")
	else:
		dialog_box.show_dialog(last_player_line, _get_lost_client_response(), "Phone")
	dialog_box.show_sale_result(closed_successfully)
	dialog_box.clear_options()
	impression_button.disabled = true

func _on_impression_button_pressed() -> void:
	_set_first_impression_quality(_get_impression_quality())
	_show_current_call_phase()

func _on_dialog_option_selected(option_index: int) -> void:
	if call_state == CallState.READY_TO_CLOSE:
		last_player_line = "Close Sale"
		dialog_box.show_my_dialog(last_player_line)
		_close_sale()
		_show_current_call_phase()
		return

	if call_state != CallState.PROMPT:
		return

	if option_index < 0 or option_index >= prompt_options.size():
		return

	last_player_line = prompt_options[option_index]["text"]
	dialog_box.show_my_dialog(last_player_line)
	_choose_prompt_option(option_index)
	_show_current_call_phase()

func _on_dial_button_pressed(number: int) -> void:
	if dialed_number.length() >= MAX_PHONE_DIGITS:
		return

	dialed_number += str(number)
	_update_dial_display()

func _on_call_button_pressed() -> void:
	if call_state != CallState.IDLE:
		return

	last_player_line = dialed_number
	var sale := GameContext.take_lead_by_phone_number(dialed_number)
	_reset_phone_entry()
	if sale.is_empty():
		_show_no_one_picked_up()
		return

	_start_call(sale)
	_show_current_call_phase()

func _start_call(sale: Dictionary) -> void:
	current_sale = sale.duplicate(true)
	success_chance = 0.0
	first_impression_quality = 0.0
	prompt_attribute = ""
	prompt_option_type = ""
	prompt_opener = ""
	prompt_options = []
	prompt_steps = []
	prompt_step_index = 0
	prompt_score = 0
	closed_successfully = false
	sale_queued_for_print = false
	call_state = CallState.FIRST_IMPRESSION
	_update_call_ready_light()

func _set_first_impression_quality(quality: float) -> void:
	first_impression_quality = clampf(quality, 0.0, 1.0)
	success_chance = lerpf(0.0, 0.30, first_impression_quality)
	_prepare_prompts()
	if prompt_steps.is_empty():
		call_state = CallState.READY_TO_CLOSE
	else:
		call_state = CallState.PROMPT
		_load_current_prompt()
	_update_call_ready_light()

func _choose_prompt_option(option_index: int) -> void:
	if option_index < 0 or option_index >= prompt_options.size():
		return

	prompt_score = prompt_options[option_index]["score"]
	_apply_prompt_score(prompt_score)
	if call_state == CallState.RESULT:
		_update_call_ready_light()
		return

	prompt_step_index += 1
	if prompt_step_index >= prompt_steps.size():
		call_state = CallState.READY_TO_CLOSE
	else:
		call_state = CallState.PROMPT
		_load_current_prompt()
	_update_call_ready_light()

func _close_sale() -> bool:
	closed_successfully = randf() <= success_chance
	call_state = CallState.RESULT
	if closed_successfully:
		GameContext.mark_phone_number_successful(str(current_sale.get("phone_number", "")))
		_queue_sale_for_print()
	_update_call_ready_light()
	return closed_successfully

func _queue_sale_for_print() -> void:
	if sale_queued_for_print:
		return

	sale_queued_for_print = true
	sale_queued.emit(current_sale.duplicate(true))

func _prepare_prompts() -> void:
	prompt_options = []
	prompt_opener = ""
	prompt_option_type = ""
	prompt_attribute = ""
	prompt_steps = []
	prompt_step_index = 0
	var sale_attributes: Array = current_sale.get("attributes", [])
	if sale_attributes.is_empty():
		return

	for attribute_key in sale_attributes:
		prompt_steps.append({
			"attribute": attribute_key,
			"type": "questions"
		})
		if prompt_steps.size() >= MAX_PROMPT_STEPS:
			break

		prompt_steps.append({
			"attribute": attribute_key,
			"type": "dialogue"
		})
		if prompt_steps.size() >= MAX_PROMPT_STEPS:
			break

func _load_current_prompt() -> void:
	if prompt_step_index < 0 or prompt_step_index >= prompt_steps.size():
		prompt_options = []
		prompt_opener = ""
		prompt_option_type = ""
		prompt_attribute = ""
		return

	var prompt_step := prompt_steps[prompt_step_index] as Dictionary
	prompt_attribute = str(prompt_step.get("attribute", ""))
	prompt_option_type = str(prompt_step.get("type", "dialogue"))
	if prompt_step_index == 0:
		prompt_opener = EmailDatabase.get_prompt_opener()
	else:
		prompt_opener = ""
	prompt_options = EmailDatabase.get_dialogue_options(prompt_attribute, prompt_option_type)
	prompt_options.shuffle()

func _apply_prompt_score(score: int) -> void:
	if score > 0:
		success_chance += CORRECT_PROMPT_BONUS
	elif score == 0:
		success_chance += randf_range(-NEUTRAL_PROMPT_VARIANCE, NEUTRAL_PROMPT_VARIANCE)
	else:
		success_chance *= 0.5
		if randf() <= BAD_PROMPT_END_CHANCE:
			closed_successfully = false
			call_state = CallState.RESULT

	success_chance = maxf(0.0, success_chance)

func _show_no_one_picked_up() -> void:
	impression_bar.visible = false
	dialog_box.clear_options()
	dialog_box.hide_sale_result()
	dialog_box.show_dialog("", "No one picked up.", "Phone")
	dialed_number = ""
	_update_dial_display()
	_update_call_ready_light()

func _update_dial_display() -> void:
	if dial_display == null:
		return

	dial_display.text = dialed_number

func _get_client_followup() -> String:
	if prompt_score > 0:
		return [
			"No way! That sounds freaking awesome!",
			"Yippeee!",
			"alriiiight im listening",
			"super duper"
		].pick_random()

	if prompt_score == 0:
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

func _connect_to_printers() -> void:
	for printer in get_tree().get_nodes_in_group("office_printer"):
		var queue_sale_callable := Callable(printer, "queue_sale")
		if printer.has_method("queue_sale") and !sale_queued.is_connected(queue_sale_callable):
			sale_queued.connect(queue_sale_callable)

func _update_call_ready_light() -> void:
	call_ready_light.visible = call_state != CallState.IDLE
