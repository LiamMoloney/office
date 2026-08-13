extends CanvasLayer

@onready var money_label: Label = $MoneyLabel

func _ready() -> void:
	if money_label:
		money_label.text = ""
