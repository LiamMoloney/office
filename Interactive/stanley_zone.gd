extends Node3D
class_name StanleyZone

@onready var interactable: Interactable = $Interactable
@onready var label: Label3D = $Label3D

func _on_interactable_interacted(actor: Node) -> void:
	if !(actor is Player):
		return

	var player := actor as Player
	if player.is_holding_pickup_type("paper"):
		var held_paper = player.get_held_item()
		if held_paper != null and held_paper.has_method("is_ready_for_stanley") and held_paper.is_ready_for_stanley():
			if held_paper.has_method("get_payout"):
				GameManager.add_money(held_paper.get_payout())
			if held_paper.has_method("turn_in"):
				held_paper.turn_in()
			_say("Paid.")
			print("report turned in")
			return

		_say("I need it stapled.")
		print("stanley needs stapled report")
		return

	_say("STANLEY")
	print("stanley waiting")

func _say(message: String) -> void:
	label.text = message
