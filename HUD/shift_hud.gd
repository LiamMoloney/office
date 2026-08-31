extends CanvasLayer

@onready var round_money_label: Label = $MoneyLabel
@onready var gain_player: AnimationPlayer = $GainPlayer
@onready var hint: Label = $HintScale/Hint
@onready var hint_scale: Control = $HintScale

@onready var hint_player: AnimationPlayer = $HintPlayer


func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	_on_money_changed(GameManager.round_money, GameManager.monthly_money)
	hint_scale.visible = false

func _on_money_changed(round_money: int, monthly_money: int) -> void:
	
	round_money_label.text = "$%d" % round_money
	gain_player.play("Textflash")

func give_hint( txt : String):
	hint.text = txt
	hint_player.play("Hint")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debugAction"):
		give_hint("Go to printer")
