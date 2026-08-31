extends Control

signal option_selected(option_index: int)

@export var letter_delay := 0.05
@export var jim_dialog_color := Color(1.0, 0.05, 0.03, 1.0)

@onready var header_label: Label = $LowerThird/HeaderLabel
@onready var sale_made_label: Label = $LowerThird/ResultLabel
@onready var sale_failed_label: Label = $LowerThird/SaleFailedLabel
@onready var my_dialog_label: Label = $LowerThird/MyDialogLabel
@onready var target_dialog_label: Label = $LowerThird/TargetDialogLabel
@onready var option_buttons: Array[Button] = [
	$LowerThird/OptionsContainer/Option1Button,
	$LowerThird/OptionsContainer/Option2Button,
	$LowerThird/OptionsContainer/Option3Button
]

var _typing_elapsed_by_label := {}
var _default_my_dialog_color := Color.WHITE

func _ready() -> void:
	_default_my_dialog_color = my_dialog_label.get_theme_color("font_color")
	for i in range(option_buttons.size()):
		option_buttons[i].pressed.connect(_on_option_pressed.bind(i))
	clear_options()
	_show_instantly(my_dialog_label)
	_begin_typewriter(target_dialog_label)

func _process(delta: float) -> void:
	for label in _typing_elapsed_by_label.keys():
		_typing_elapsed_by_label[label] += delta
		var visible_count := int(_typing_elapsed_by_label[label] / maxf(letter_delay, 0.001))
		label.visible_characters = mini(visible_count, label.text.length())

		if label.visible_characters >= label.text.length():
			_typing_elapsed_by_label.erase(label)

func show_dialog(my_text: String, target_text: String, header_text := "") -> void:
	if header_text != "":
		set_header_text(header_text)
	show_my_dialog(my_text)
	show_target_dialog(target_text)

func show_jim_dialog(my_text: String, target_text: String, header_text := "") -> void:
	if header_text != "":
		set_header_text(header_text)
	show_my_dialog_as_jim(my_text)
	show_target_dialog(target_text)

func show_my_dialog(text: String) -> void:
	_set_my_dialog_color(_default_my_dialog_color)
	my_dialog_label.text = text
	_show_instantly(my_dialog_label)

func show_my_dialog_as_jim(text: String) -> void:
	_set_my_dialog_color(jim_dialog_color)
	my_dialog_label.text = text
	_show_instantly(my_dialog_label)

func show_target_dialog(text: String) -> void:
	target_dialog_label.text = text
	_begin_typewriter(target_dialog_label)

func set_header_text(text: String) -> void:
	header_label.text = text

func show_sale_result(was_successful: bool) -> void:
	sale_made_label.visible = was_successful
	sale_failed_label.visible = !was_successful

func hide_sale_result() -> void:
	sale_made_label.visible = false
	sale_failed_label.visible = false

func set_options(options: Array) -> void:
	for i in range(option_buttons.size()):
		var button := option_buttons[i]
		if i < options.size():
			button.text = str(options[i])
			button.visible = true
			button.disabled = false
		else:
			button.text = ""
			button.visible = false
			button.disabled = true

func clear_options() -> void:
	for button in option_buttons:
		button.text = ""
		button.visible = false
		button.disabled = true

func _begin_typewriter(label: Label) -> void:
	_typing_elapsed_by_label[label] = 0.0
	label.visible_characters = 0

func _show_instantly(label: Label) -> void:
	_typing_elapsed_by_label.erase(label)
	label.visible_characters = -1

func _set_my_dialog_color(color: Color) -> void:
	my_dialog_label.add_theme_color_override("font_color", color)

func _on_option_pressed(option_index: int) -> void:
	option_selected.emit(option_index)
