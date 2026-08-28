extends Control

const EMAIL_FONT = preload("res://Art/Fonts/itc-american-typewriter-medium/ITC American Typewriter Medium/ITC American Typewriter Medium.otf")
const HEADER_BORDER_COLOR := Color.BLACK
const HEADER_NORMAL_COLOR := Color.WHITE
const HEADER_HOVER_COLOR := Color(0.93, 0.93, 0.93, 1.0)
const HEADER_PRESSED_COLOR := Color(0.86, 0.86, 0.86, 1.0)
const HEADER_TEXT_COLOR := Color.BLACK

@onready var email_list: VBoxContainer = $Panel/MarginContainer/ScreenVTopBar/Application/Split/InboxPanel/InboxScroll/DailyEmailList
@onready var empty_label: Label = $Panel/MarginContainer/ScreenVTopBar/Application/Split/EmailBodyPanel/BodyVBox/EmptyLabel
@onready var header_row: HBoxContainer = $Panel/MarginContainer/ScreenVTopBar/Application/Split/EmailBodyPanel/BodyVBox/HeaderRow
@onready var sender_label: Label = $Panel/MarginContainer/ScreenVTopBar/Application/Split/EmailBodyPanel/BodyVBox/HeaderRow/HeaderText/SenderLabel
@onready var company_label: Label = $Panel/MarginContainer/ScreenVTopBar/Application/Split/EmailBodyPanel/BodyVBox/HeaderRow/HeaderText/CompanyLabel
@onready var phone_label: Label = $Panel/MarginContainer/ScreenVTopBar/Application/Split/EmailBodyPanel/BodyVBox/PhoneLabel
@onready var attributes_label: Label = $Panel/MarginContainer/ScreenVTopBar/Application/Split/EmailBodyPanel/BodyVBox/AttributesLabel
@onready var body_label: Label = $Panel/MarginContainer/ScreenVTopBar/Application/Split/EmailBodyPanel/BodyVBox/BodyLabel

var selected_email := {}

func _ready() -> void:
	GameContext.emails_changed.connect(_rebuild_email_list)
	_rebuild_email_list()

func _on_button_pressed() -> void:
	queue_free()

func _rebuild_email_list() -> void:
	for child in email_list.get_children():
		email_list.remove_child(child)
		child.queue_free()

	var emails := GameContext.get_daily_emails()
	if !emails.has(selected_email):
		selected_email = emails[0] if !emails.is_empty() else {}

	for email in emails:
		email_list.add_child(_create_email_header(email))

	_update_email_body()

func _create_email_header(email: Dictionary) -> Control:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0.0, 50.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text = "%s\n%s" % [
		_shorten_header_text(str(email.get("sender", "unknown@unknown")), 24),
		_shorten_header_text(str(email.get("company", "Unknown Company")), 22)
	]
	button.clip_text = true
	button.add_theme_color_override("font_color", HEADER_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", HEADER_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", HEADER_TEXT_COLOR)
	button.add_theme_color_override("font_focus_color", HEADER_TEXT_COLOR)
	button.add_theme_font_override("font", EMAIL_FONT)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_stylebox_override("normal", _create_header_style(HEADER_NORMAL_COLOR))
	button.add_theme_stylebox_override("hover", _create_header_style(HEADER_HOVER_COLOR))
	button.add_theme_stylebox_override("pressed", _create_header_style(HEADER_PRESSED_COLOR))
	button.add_theme_stylebox_override("focus", _create_header_style(HEADER_HOVER_COLOR))
	button.pressed.connect(_select_email.bind(email))
	return button

func _shorten_header_text(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text

	return text.substr(0, max_length - 3) + "..."

func _create_header_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = HEADER_BORDER_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 6.0
	style.content_margin_top = 5.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 5.0
	return style

func _select_email(email: Dictionary) -> void:
	selected_email = email
	_update_email_body()

func _update_email_body() -> void:
	var has_email := !selected_email.is_empty()
	empty_label.visible = !has_email
	header_row.visible = has_email
	phone_label.visible = has_email
	attributes_label.visible = has_email
	body_label.visible = has_email
	if !has_email:
		return

	sender_label.text = "From: %s" % selected_email.get("sender", "unknown@unknown")
	company_label.text = "Subject: Paper inquiry from %s" % selected_email.get("company", "Unknown Company")
	phone_label.text = "Phone: %s" % selected_email.get("phone_number", "00000")
	attributes_label.text = "Notes: %s" % _get_attribute_note(selected_email)
	body_label.text = str(selected_email.get("body", "Hello we are looking to buy paper."))

func _get_attribute_note(email: Dictionary) -> String:
	var attribute_names := PackedStringArray()
	for attribute_name in email.get("attribute_names", []):
		attribute_names.append(str(attribute_name))

	if attribute_names.is_empty():
		return "No useful notes."

	return ", ".join(attribute_names)

func _on_delete_button_pressed() -> void:
	if selected_email.is_empty():
		return

	var email_to_delete := selected_email
	selected_email = {}
	GameContext.delete_daily_email(email_to_delete)

func _on_report_button_pressed() -> void:
	if selected_email.is_empty():
		return

	var email_to_report := selected_email
	selected_email = {}
	GameContext.report_daily_email(email_to_report)
