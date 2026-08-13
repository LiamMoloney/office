extends Control

signal desktop_icon_pressed

@onready var mouse_cursor: Sprite2D = $MouseCursor
@onready var desktop_icon: Button = $Icon

@onready var email_scene = preload("res://Interactive/Computer/email.tscn")
var email_window: Control

var pc_mouse_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	size = get_viewport_rect().size
	desktop_icon.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	desktop_icon.pressed.connect(_on_desktop_icon_pressed)
	update_cursor_pos()

func update_cursor_pos() -> void:
	mouse_cursor.position = pc_mouse_pos

func _on_desktop_icon_pressed() -> void:
	
	desktop_icon_pressed.emit()
	if (!email_window):
		email_window = email_scene.instantiate()
		add_child(email_window)
	email_window.move_to_front()
	mouse_cursor.move_to_front()	
	print("desktop icon pressed")
