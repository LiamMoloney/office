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
			SaleStatus.mark_report_turned_in()
			if held_paper.has_method("turn_in"):
				held_paper.turn_in()
			_say("Paid.")
			print("report turned in")
			return

		_say("I need it stapled.")
		print("stanley needs stapled report")
		return

	if SaleStatus.currSaleState == SaleStatus.SaleState.PRINT_REPORT or SaleStatus.currSaleState == SaleStatus.SaleState.STAPLE_REPORT:
		_say("I need it stapled.")
		print("stanley needs stapled report")
		return

	if SaleStatus.currSaleState == SaleStatus.SaleState.TURN_IN_REPORT:
		_say("Bring me the report.")
		print("stanley needs report")
		return

	_say("STANLEY")
	print("stanley waiting")

func _say(message: String) -> void:
	label.text = message
