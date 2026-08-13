extends StaticBody3D
class_name PrinterStatic

@onready var interactable: Interactable = $Interactable

func _on_interactable_interacted(actor: Node) -> void:
	if !(actor is Player):
		return

	print("printer interacted")
