extends Resource
class_name JimPrankData

enum CorrectiveAction {
	NONE,
	REPORT_JIM,
	FIX_OBJECT,
	CANCEL_JOBS,
	FIND_OBJECT,
	FIND_STANLEY,
	SURVIVE
}

var id := ""
var display_name := ""
var step_id := ""
var target_id := ""
var setup_area_id := ""
var trigger_area_id := ""
var setup_sale_states: Array[int] = []
var trigger_sale_states: Array[int] = []
var setup_requires_player_away := false
var rig_time_s := 4.0
var active_time_s := 30.0
var money_penalty := 0
var corrective_action := CorrectiveAction.NONE
var corrective_hint := ""

func _init(
	_id: String = "",
	_display_name: String = "",
	_step_id: String = "",
	_target_id: String = "",
	_setup_area_id: String = "",
	_trigger_area_id: String = "",
	_setup_sale_states: Array[int] = [],
	_trigger_sale_states: Array[int] = [],
	_setup_requires_player_away: bool = false,
	_rig_time_s: float = 4.0,
	_active_time_s: float = 30.0,
	_money_penalty: int = 0,
	_corrective_action: int = CorrectiveAction.NONE,
	_corrective_hint: String = ""
) -> void:
	id = _id
	display_name = _display_name
	step_id = _step_id
	target_id = _target_id
	setup_area_id = _setup_area_id
	trigger_area_id = _trigger_area_id
	setup_sale_states = _setup_sale_states
	trigger_sale_states = _trigger_sale_states
	setup_requires_player_away = _setup_requires_player_away
	rig_time_s = _rig_time_s
	active_time_s = _active_time_s
	money_penalty = _money_penalty
	corrective_action = _corrective_action
	corrective_hint = _corrective_hint

func can_setup(current_sale_state: int, player_area_id: String) -> bool:
	if !setup_sale_states.is_empty() and !setup_sale_states.has(current_sale_state):
		return false

	if setup_requires_player_away and player_area_id == setup_area_id:
		return false

	return true

func can_trigger(current_sale_state: int, player_area_id: String) -> bool:
	if !trigger_sale_states.is_empty() and !trigger_sale_states.has(current_sale_state):
		return false

	if trigger_area_id != "" and player_area_id != trigger_area_id:
		return false

	return true
