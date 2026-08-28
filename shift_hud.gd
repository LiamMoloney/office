extends CanvasLayer

@onready var round_money_label: Label = $MoneyLabel
@onready var monthly_money_label: Label = $MonthlyMoneyLabel
@onready var animation_player: AnimationPlayer = $GainPlayer


func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	_on_money_changed(GameManager.round_money, GameManager.monthly_money)

func _on_money_changed(round_money: int, monthly_money: int) -> void:
	
	round_money_label.text = "$%d" % round_money
	monthly_money_label.text = "$%d" % monthly_money
	animation_player.play("Textflash")
