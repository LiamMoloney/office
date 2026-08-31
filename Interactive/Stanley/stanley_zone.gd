extends CharacterBody3D
class_name StanleyZone

@export var report_accepted_line := "Good job."
@export var needs_stapled_line := "It needs stapled."

@onready var interactable: Interactable = $Interactable
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var one_shot_dialog: OneShotDialog = $OneShotDialog

func _ready() -> void:
	animation_player.play("IdleSit")

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
				print("report turned in")
			_show_stanley_line(report_accepted_line)
			return
		_show_stanley_line(needs_stapled_line)
		animation_player.play("NoStaplers")

		return


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "NoStaplers":
		animation_player.play("IdleSit")
	else:
		print("did it end?")

func _show_stanley_line(text: String) -> void:
	one_shot_dialog.show_one_shot(text)
