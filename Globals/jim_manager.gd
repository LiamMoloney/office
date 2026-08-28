extends Node

signal prank_setup_started(prank: JimPrankData)
signal prank_rigged(prank: JimPrankData)
signal prank_triggered(prank: JimPrankData)
signal prank_corrected(prank: JimPrankData)
signal prank_reported(prank: JimPrankData)
signal jim_location_changed(area_id: String)

const PRANK_DATA_SCRIPT = preload("res://Globals/prank_data.gd")

enum State {
	IDLE,
	SETTING_UP,
	RIGGED,
	ACTIVE,
	CAUGHT,
	COOLDOWN
}

enum Step {
	CHECK_EMAIL,
	ENTER_PHONE_NUMBER,
	CONVINCE_CUSTOMER,
	PRINT_REPORT,
	STAPLE_REPORT,
	DELIVER_TO_STANLEY
}

const AREA_DESK := "desk"
const AREA_PHONE := "phone"
const AREA_PRINTER := "printer"
const AREA_STAPLER := "stapler"
const AREA_STANLEY := "stanley"
const AREA_JIM_DESK := "jim_desk"

const TARGET_EMAIL := "email"
const TARGET_PHONE := "phone"
const TARGET_CALL := "call"
const TARGET_PRINTER := "printer"
const TARGET_STAPLER := "stapler"
const TARGET_STANLEY := "stanley"

# Hook your future AreaNode into set_player_area(area_id). Interactable scripts can then
# ask this global about their own target id, for example JimManager.is_prank_active("phone").
var prank_library: Array[JimPrankData] = []
var current_prank: JimPrankData
var state := State.IDLE
var jim_area_id := AREA_JIM_DESK
var player_area_id := ""
var state_elapsed_s := 0.0
var cooldown_s := 8.0
var setup_check_interval_s := 5.0
var setup_chance := 0.35
var enabled := true

func _ready() -> void:
	_build_prank_library()
	if SaleStatus.has_signal("sale_changed"):
		SaleStatus.sale_changed.connect(_on_sale_changed)


func _process(delta: float) -> void:
	if !enabled:
		return

	state_elapsed_s += delta
	match state:
		State.IDLE:
			_try_start_prank_setup()
		State.SETTING_UP:
			if current_prank == null:
				_set_state(State.IDLE)
				return

			if current_prank.setup_requires_player_away and player_area_id == current_prank.setup_area_id:
				report_current_prank()
			elif state_elapsed_s >= current_prank.rig_time_s:
				_finish_rigging_current_prank()
		State.RIGGED:
			if current_prank == null:
				_set_state(State.IDLE)
				return

			if current_prank.can_trigger(SaleStatus.currSaleState, player_area_id):
				_trigger_current_prank()
		State.ACTIVE:
			if current_prank == null:
				_set_state(State.IDLE)
				return

			if state_elapsed_s >= current_prank.active_time_s:
				_fail_or_expire_current_prank()
		State.CAUGHT, State.COOLDOWN:
			if state_elapsed_s >= cooldown_s:
				_clear_current_prank()

func set_player_area(area_id: String) -> void:
	player_area_id = area_id

func get_current_prank() -> JimPrankData:
	return current_prank

func get_jim_area() -> String:
	return jim_area_id

func get_current_prank_id() -> String:
	return current_prank.id if current_prank != null else ""

func get_current_corrective_hint() -> String:
	return current_prank.corrective_hint if current_prank != null else ""

func is_jim_setting_up(target_id: String = "") -> bool:
	if state != State.SETTING_UP or current_prank == null:
		return false

	return target_id == "" or current_prank.target_id == target_id

func is_prank_rigged(target_id: String) -> bool:
	return current_prank != null and state in [State.RIGGED, State.ACTIVE] and current_prank.target_id == target_id

func is_prank_active(target_id: String) -> bool:
	return current_prank != null and state == State.ACTIVE and current_prank.target_id == target_id

func get_prank_for_target(target_id: String) -> JimPrankData:
	if current_prank == null or current_prank.target_id != target_id:
		return null

	return current_prank

func correct_prank(target_id: String) -> bool:
	if current_prank == null or current_prank.target_id != target_id:
		return false

	prank_corrected.emit(current_prank)
	_set_state(State.COOLDOWN)
	return true

func report_current_prank() -> bool:
	if current_prank == null or state != State.SETTING_UP:
		return false

	prank_reported.emit(current_prank)
	_set_state(State.CAUGHT)
	return true

func force_prank(prank_id: String) -> bool:
	for prank in prank_library:
		if prank.id == prank_id:
			_start_prank_setup(prank)
			return true

	return false

func register_prank(prank: JimPrankData) -> void:
	if prank == null or prank.id == "":
		return

	for i in range(prank_library.size()):
		if prank_library[i].id == prank.id:
			prank_library[i] = prank
			return

	prank_library.append(prank)

func _try_start_prank_setup() -> void:
	if SaleStatus.currSaleState == SaleStatus.SaleState.NONE:
		return

	if state_elapsed_s < setup_check_interval_s:
		return

	state_elapsed_s = 0.0
	if randf() > setup_chance:
		return

	var available_pranks := _get_available_setup_pranks()
	if available_pranks.is_empty():
		return

	_start_prank_setup(available_pranks.pick_random())

func _get_available_setup_pranks() -> Array[JimPrankData]:
	var available_pranks: Array[JimPrankData] = []
	for prank in prank_library:
		if prank.can_setup(SaleStatus.currSaleState, player_area_id):
			available_pranks.append(prank)

	return available_pranks

func _start_prank_setup(prank: JimPrankData) -> void:
	current_prank = prank
	jim_area_id = prank.setup_area_id
	jim_location_changed.emit(jim_area_id)
	prank_setup_started.emit(prank)
	_set_state(State.SETTING_UP)

func _finish_rigging_current_prank() -> void:
	prank_rigged.emit(current_prank)
	_set_state(State.RIGGED)

func _trigger_current_prank() -> void:
	prank_triggered.emit(current_prank)
	if current_prank.money_penalty > 0:
		_apply_money_penalty(current_prank.money_penalty)

	_set_state(State.ACTIVE)

func _fail_or_expire_current_prank() -> void:
	_set_state(State.COOLDOWN)

func _clear_current_prank() -> void:
	current_prank = null
	jim_area_id = AREA_JIM_DESK
	jim_location_changed.emit(jim_area_id)
	_set_state(State.IDLE)

func _set_state(next_state: int) -> void:
	state = next_state
	state_elapsed_s = 0.0

func _on_sale_changed() -> void:
	if state != State.RIGGED or current_prank == null:
		return

	if current_prank.can_trigger(SaleStatus.currSaleState, player_area_id):
		_trigger_current_prank()

func _apply_money_penalty(amount: int) -> void:
	GameManager.round_money = maxi(0, GameManager.round_money - amount)
	GameManager.monthly_money = maxi(0, GameManager.monthly_money - amount)
	GameManager.money_changed.emit(GameManager.round_money, GameManager.monthly_money)

func _build_prank_library() -> void:
	prank_library = [
		PRANK_DATA_SCRIPT.new(
			"email_flood",
			"Email flood",
			"check_email",
			TARGET_EMAIL,
			AREA_DESK,
			AREA_DESK,
			[SaleStatus.SaleState.NONE, SaleStatus.SaleState.PHONE_LOADED],
			[SaleStatus.SaleState.NONE, SaleStatus.SaleState.PHONE_LOADED],
			true,
			5.0,
			60.0,
			0,
			JimPrankData.CorrectiveAction.FIX_OBJECT,
			"Delete the useless emails or report the fake lead."
		),
		PRANK_DATA_SCRIPT.new(
			"altered_phone_number",
			"Altered phone number",
			"check_email",
			TARGET_EMAIL,
			AREA_DESK,
			AREA_PHONE,
			[SaleStatus.SaleState.NONE, SaleStatus.SaleState.PHONE_LOADED],
			[SaleStatus.SaleState.NONE, SaleStatus.SaleState.PHONE_LOADED],
			true,
			4.0,
			45.0,
			0,
			JimPrankData.CorrectiveAction.REPORT_JIM,
			"Catch Jim at the computer before the bad lead gets used."
		),
		PRANK_DATA_SCRIPT.new(
			"shutdown_link",
			"Shutdown link",
			"check_email",
			TARGET_EMAIL,
			AREA_DESK,
			AREA_DESK,
			[SaleStatus.SaleState.NONE],
			[SaleStatus.SaleState.NONE],
			true,
			6.0,
			3600.0,
			0,
			JimPrankData.CorrectiveAction.SURVIVE,
			"Do not click the suspicious link, or wait out the computer shutdown."
		),
		PRANK_DATA_SCRIPT.new(
			"swapped_keypad_buttons",
			"Swapped keypad buttons",
			"enter_phone_number",
			TARGET_PHONE,
			AREA_PHONE,
			AREA_PHONE,
			[SaleStatus.SaleState.NONE, SaleStatus.SaleState.PHONE_LOADED],
			[SaleStatus.SaleState.NONE, SaleStatus.SaleState.PHONE_LOADED],
			true,
			5.0,
			60.0,
			0,
			JimPrankData.CorrectiveAction.FIX_OBJECT,
			"Notice the swapped buttons and put them back."
		),
		PRANK_DATA_SCRIPT.new(
			"phone_bomb",
			"Phone bomb",
			"enter_phone_number",
			TARGET_PHONE,
			AREA_PHONE,
			AREA_PHONE,
			[SaleStatus.SaleState.NONE, SaleStatus.SaleState.PHONE_LOADED],
			[SaleStatus.SaleState.FIRST_IMPRESSION, SaleStatus.SaleState.PROMPT],
			true,
			4.0,
			8.0,
			0,
			JimPrankData.CorrectiveAction.SURVIVE,
			"Run if you hear ticking."
		),
		PRANK_DATA_SCRIPT.new(
			"background_distraction",
			"Background distraction",
			"convince_customer",
			TARGET_CALL,
			AREA_PHONE,
			AREA_PHONE,
			[SaleStatus.SaleState.FIRST_IMPRESSION, SaleStatus.SaleState.PROMPT],
			[SaleStatus.SaleState.PROMPT],
			false,
			2.0,
			15.0,
			0,
			JimPrankData.CorrectiveAction.REPORT_JIM,
			"Shove Jim away before his line overwrites your dialog choice."
		),
		PRANK_DATA_SCRIPT.new(
			"call_interference",
			"Call interference",
			"convince_customer",
			TARGET_CALL,
			AREA_PHONE,
			AREA_PHONE,
			[SaleStatus.SaleState.PROMPT],
			[SaleStatus.SaleState.PROMPT, SaleStatus.SaleState.READY_TO_CLOSE],
			false,
			2.0,
			20.0,
			25,
			JimPrankData.CorrectiveAction.REPORT_JIM,
			"Report Jim before he costs the sale money."
		),
		PRANK_DATA_SCRIPT.new(
			"printer_unplugged",
			"Printer unplugged",
			"print_report",
			TARGET_PRINTER,
			AREA_PRINTER,
			AREA_PRINTER,
			[SaleStatus.SaleState.PRINT_REPORT],
			[SaleStatus.SaleState.PRINT_REPORT],
			true,
			4.0,
			90.0,
			0,
			JimPrankData.CorrectiveAction.FIX_OBJECT,
			"Follow the cable and plug the printer back in."
		),
		PRANK_DATA_SCRIPT.new(
			"wrong_paper_loaded",
			"Wrong paper loaded",
			"print_report",
			TARGET_PRINTER,
			AREA_PRINTER,
			AREA_PRINTER,
			[SaleStatus.SaleState.PRINT_REPORT],
			[SaleStatus.SaleState.PRINT_REPORT],
			true,
			4.0,
			90.0,
			0,
			JimPrankData.CorrectiveAction.FIX_OBJECT,
			"Replace Jim's paper with normal report paper."
		),
		PRANK_DATA_SCRIPT.new(
			"print_job_hijack",
			"Print-job hijack",
			"print_report",
			TARGET_PRINTER,
			AREA_PRINTER,
			AREA_PRINTER,
			[SaleStatus.SaleState.PRINT_REPORT],
			[SaleStatus.SaleState.PRINT_REPORT],
			true,
			4.0,
			90.0,
			0,
			JimPrankData.CorrectiveAction.CANCEL_JOBS,
			"Cancel Jim's queued print jobs."
		),
		PRANK_DATA_SCRIPT.new(
			"stapler_in_jello",
			"Stapler in Jell-O",
			"staple_report",
			TARGET_STAPLER,
			AREA_STAPLER,
			AREA_STAPLER,
			[SaleStatus.SaleState.STAPLE_REPORT],
			[SaleStatus.SaleState.STAPLE_REPORT],
			true,
			5.0,
			90.0,
			0,
			JimPrankData.CorrectiveAction.FIND_OBJECT,
			"Find the hidden stapler and get it out of the Jell-O."
		),
		PRANK_DATA_SCRIPT.new(
			"lighter_stapler",
			"Lighter stapler",
			"staple_report",
			TARGET_STAPLER,
			AREA_STAPLER,
			AREA_STAPLER,
			[SaleStatus.SaleState.STAPLE_REPORT],
			[SaleStatus.SaleState.STAPLE_REPORT],
			true,
			5.0,
			12.0,
			0,
			JimPrankData.CorrectiveAction.SURVIVE,
			"Drop or extinguish the burning report."
		),
		PRANK_DATA_SCRIPT.new(
			"pipe_bomb_stapler",
			"Pipe bomb stapler",
			"staple_report",
			TARGET_STAPLER,
			AREA_STAPLER,
			AREA_STAPLER,
			[SaleStatus.SaleState.STAPLE_REPORT],
			[SaleStatus.SaleState.STAPLE_REPORT],
			true,
			5.0,
			8.0,
			0,
			JimPrankData.CorrectiveAction.SURVIVE,
			"Run away before the stapler explodes."
		),
		PRANK_DATA_SCRIPT.new(
			"stanley_moved",
			"Stanley moved",
			"deliver_to_stanley",
			TARGET_STANLEY,
			AREA_STANLEY,
			AREA_STANLEY,
			[SaleStatus.SaleState.TURN_IN_REPORT],
			[SaleStatus.SaleState.TURN_IN_REPORT],
			true,
			5.0,
			120.0,
			0,
			JimPrankData.CorrectiveAction.FIND_STANLEY,
			"Find where Jim sent Stanley."
		),
		PRANK_DATA_SCRIPT.new(
			"drugged_stanley_coffee",
			"Drugged Stanley coffee",
			"deliver_to_stanley",
			TARGET_STANLEY,
			AREA_STANLEY,
			AREA_STANLEY,
			[SaleStatus.SaleState.TURN_IN_REPORT],
			[SaleStatus.SaleState.TURN_IN_REPORT],
			true,
			5.0,
			3600.0,
			0,
			JimPrankData.CorrectiveAction.SURVIVE,
			"Wait for Stanley to recover or route around this in your objective logic."
		)
	]
