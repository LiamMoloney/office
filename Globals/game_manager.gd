extends Node

signal money_changed(round_money: int, monthly_money: int)
signal round_started(round_duration_s: float)
signal round_time_changed(elapsed_s: float, duration_s: float, progress: float)
signal round_ended

var round_money := 0
var monthly_money := 0

var day = 0
@export var roundtime_s := 600.0
var round_elapsed_s := 0.0
var round_active := false

func _ready() -> void:
	money_changed.emit(round_money, monthly_money)
	start_round()

func _process(delta: float) -> void:
	if !round_active:
		return

	round_elapsed_s = minf(round_elapsed_s + delta, roundtime_s)
	_emit_round_time_changed()

	if round_elapsed_s >= roundtime_s:
		end_round()

func start_round() -> void:
	round_elapsed_s = 0.0
	round_active = true
	round_started.emit(roundtime_s)
	_emit_round_time_changed()

func end_round() -> void:
	if !round_active:
		return

	round_elapsed_s = roundtime_s
	round_active = false
	_emit_round_time_changed()
	round_ended.emit()

func get_round_progress() -> float:
	if roundtime_s <= 0.0:
		return 1.0

	return clampf(round_elapsed_s / roundtime_s, 0.0, 1.0)

func _emit_round_time_changed() -> void:
	round_time_changed.emit(round_elapsed_s, roundtime_s, get_round_progress())

func add_money(amount: int) -> void:
	if amount <= 0:
		return

	round_money += amount
	monthly_money += amount
	money_changed.emit(round_money, monthly_money)

func reset_round_money() -> void:
	round_money = 0
	money_changed.emit(round_money, monthly_money)

func reset_monthly_money() -> void:
	round_money = 0
	monthly_money = 0
	money_changed.emit(round_money, monthly_money)
