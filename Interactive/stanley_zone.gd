extends Node3D
class_name StanleyZone

@onready var interactable: Interactable = $Interactable

func _on_interactable_interacted(actor: Node) -> void:
	if !(actor is Player):
		return

	print("stanley zone interacted")
