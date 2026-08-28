extends Node

signal sale_changed

const CORRECT_PROMPT_BONUS := 0.20
const NEUTRAL_PROMPT_VARIANCE := 0.10
const BAD_PROMPT_END_CHANCE := 0.50
const MAX_PROMPT_STEPS := 4
const DAILY_EMAIL_COUNT := 6

enum SaleState {
	NONE,
	PHONE_LOADED,
	FIRST_IMPRESSION,
	PROMPT,
	READY_TO_CLOSE,
	CLOSED,
	PRINT_REPORT,
	STAPLE_REPORT,
	TURN_IN_REPORT,
	PAID
}

var currSaleState := SaleState.NONE
var current_sale := {}
var success_chance := 0.0
var first_impression_quality := 0.0
var prompt_attribute := ""
var prompt_option_type := ""
var prompt_opener := ""
var prompt_options := []
var prompt_steps := []
var prompt_step_index := 0
var prompt_score := 0
var closed_successfully := false
var sale_payout := 0
var daily_emails := []
var daily_emails_generated := false
var called_phone_numbers := {}
var reported_phone_numbers := {}

func get_daily_emails() -> Array:
	if !daily_emails_generated:
		_generate_daily_emails()

	return daily_emails

func delete_daily_email(email: Dictionary) -> void:
	daily_emails.erase(email)
	if current_sale == email:
		clear_sale()

	sale_changed.emit()

func report_daily_email(email: Dictionary) -> void:
	var phone_number := _clean_phone_number(str(email.get("phone_number", "")))
	if phone_number != "":
		reported_phone_numbers[phone_number] = true
		called_phone_numbers[phone_number] = true

	daily_emails.erase(email)
	if current_sale == email:
		clear_sale()

	sale_changed.emit()

func load_sale_by_phone_number(phone_number: String) -> bool:
	var clean_number := _clean_phone_number(phone_number)
	if called_phone_numbers.has(clean_number):
		return false

	for email in get_daily_emails():
		if str(email.get("phone_number", "")) != clean_number:
			continue

		called_phone_numbers[clean_number] = true
		daily_emails.erase(email)
		if !email.get("is_real", false):
			sale_changed.emit()
			return false

		load_sale(email)
		return true

	return false

func load_sale(sale: Dictionary) -> void:
	current_sale = sale
	success_chance = 0.0
	first_impression_quality = 0.0
	prompt_attribute = ""
	prompt_option_type = ""
	prompt_opener = ""
	prompt_options = []
	prompt_steps = []
	prompt_step_index = 0
	prompt_score = 0
	closed_successfully = false
	sale_payout = int(current_sale.get("payout", 100))
	currSaleState = SaleState.PHONE_LOADED
	sale_changed.emit()

func clear_sale() -> void:
	current_sale = {}
	success_chance = 0.0
	first_impression_quality = 0.0
	prompt_attribute = ""
	prompt_option_type = ""
	prompt_opener = ""
	prompt_options = []
	prompt_steps = []
	prompt_step_index = 0
	prompt_score = 0
	closed_successfully = false
	sale_payout = 0
	currSaleState = SaleState.NONE
	sale_changed.emit()

func has_loaded_sale() -> bool:
	return currSaleState != SaleState.NONE and !current_sale.is_empty()

func is_email_locked() -> bool:
	return currSaleState in [
		SaleState.PHONE_LOADED,
		SaleState.FIRST_IMPRESSION,
		SaleState.PROMPT,
		SaleState.READY_TO_CLOSE,
		SaleState.PRINT_REPORT,
		SaleState.STAPLE_REPORT,
		SaleState.TURN_IN_REPORT
	]

func start_call() -> void:
	if !has_loaded_sale():
		return

	currSaleState = SaleState.FIRST_IMPRESSION
	sale_changed.emit()

func set_first_impression_quality(quality: float) -> void:
	first_impression_quality = clampf(quality, 0.0, 1.0)
	success_chance = lerpf(0.0, 0.30, first_impression_quality)
	_prepare_prompts()
	if prompt_steps.is_empty():
		currSaleState = SaleState.READY_TO_CLOSE
	else:
		currSaleState = SaleState.PROMPT
		_load_current_prompt()
	sale_changed.emit()

func choose_prompt_option(option_index: int) -> void:
	if option_index < 0 or option_index >= prompt_options.size():
		return

	prompt_score = prompt_options[option_index]["score"]
	_apply_prompt_score(prompt_score)
	if currSaleState == SaleState.CLOSED:
		sale_changed.emit()
		return

	prompt_step_index += 1
	if prompt_step_index >= prompt_steps.size():
		currSaleState = SaleState.READY_TO_CLOSE
	else:
		currSaleState = SaleState.PROMPT
		_load_current_prompt()
	sale_changed.emit()

func close_sale() -> bool:
	closed_successfully = randf() <= success_chance
	currSaleState = SaleState.PRINT_REPORT if closed_successfully else SaleState.CLOSED
	sale_changed.emit()
	return closed_successfully

func mark_report_printed() -> void:
	if currSaleState != SaleState.PRINT_REPORT:
		return

	currSaleState = SaleState.STAPLE_REPORT
	sale_changed.emit()

func mark_report_stapled() -> void:
	if currSaleState != SaleState.STAPLE_REPORT:
		return

	currSaleState = SaleState.TURN_IN_REPORT
	sale_changed.emit()

func mark_report_turned_in() -> void:
	if currSaleState != SaleState.TURN_IN_REPORT:
		return

	GameManager.add_money(sale_payout)
	currSaleState = SaleState.PAID
	sale_changed.emit()

func _prepare_prompts() -> void:
	prompt_options = []
	prompt_opener = ""
	prompt_option_type = ""
	prompt_attribute = ""
	prompt_steps = []
	prompt_step_index = 0
	var sale_attributes: Array = current_sale.get("attributes", [])
	if sale_attributes.is_empty():
		return

	for attribute_key in sale_attributes:
		prompt_steps.append({
			"attribute": attribute_key,
			"type": "questions"
		})
		if prompt_steps.size() >= MAX_PROMPT_STEPS:
			break

		prompt_steps.append({
			"attribute": attribute_key,
			"type": "dialogue"
		})
		if prompt_steps.size() >= MAX_PROMPT_STEPS:
			break

func _load_current_prompt() -> void:
	if prompt_step_index < 0 or prompt_step_index >= prompt_steps.size():
		prompt_options = []
		prompt_opener = ""
		prompt_option_type = ""
		prompt_attribute = ""
		return

	var prompt_step := prompt_steps[prompt_step_index] as Dictionary
	prompt_attribute = str(prompt_step.get("attribute", ""))
	prompt_option_type = str(prompt_step.get("type", "dialogue"))
	var database = preload("res://email_database.gd").new()
	if prompt_step_index == 0:
		prompt_opener = database.get_prompt_opener()
	else:
		prompt_opener = ""
	prompt_options = database.get_dialogue_options(prompt_attribute, prompt_option_type)
	prompt_options.shuffle()

func _apply_prompt_score(score: int) -> void:
	if score > 0:
		success_chance += CORRECT_PROMPT_BONUS
	elif score == 0:
		success_chance += randf_range(-NEUTRAL_PROMPT_VARIANCE, NEUTRAL_PROMPT_VARIANCE)
	else:
		success_chance *= 0.5
		if randf() <= BAD_PROMPT_END_CHANCE:
			closed_successfully = false
			currSaleState = SaleState.CLOSED

	success_chance = maxf(0.0, success_chance)

func _generate_daily_emails() -> void:
	var database = preload("res://email_database.gd").new()
	daily_emails = []
	daily_emails_generated = true
	for i in range(DAILY_EMAIL_COUNT):
		daily_emails.append(database.generate_real_email())

	daily_emails.append(database.generate_fake_email())
	daily_emails.shuffle()

func _clean_phone_number(phone_number: String) -> String:
	var clean_number := ""
	for i in range(phone_number.length()):
		var character := phone_number.substr(i, 1)
		if character >= "0" and character <= "9":
			clean_number += character

	return clean_number
