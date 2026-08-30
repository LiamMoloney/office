extends StaticBody3D


func _on_interactable_interacted(actor: Node) -> void:
	if !(actor is Player):
		return

	var player := actor as Player
	var held_stapler := player.get_held_item() as Stapler
	if held_stapler == null or !held_stapler.is_sabotaged():
		return

	held_stapler.fix_sabotage()
