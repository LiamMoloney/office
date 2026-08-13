extends Area3D

class_name Interactable

@export var interact_name = ""
@export var is_interactable: bool = true

signal interacted(actor)

func interact(actor: Node) -> void:
	if !is_interactable:
		return

	interacted.emit(actor)
