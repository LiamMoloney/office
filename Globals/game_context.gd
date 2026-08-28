extends Node

signal emails_changed

const DAILY_EMAIL_COUNT := 6

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
	emails_changed.emit()

func report_daily_email(email: Dictionary) -> void:
	var phone_number := clean_phone_number(str(email.get("phone_number", "")))
	if phone_number != "":
		reported_phone_numbers[phone_number] = true
		called_phone_numbers[phone_number] = true

	daily_emails.erase(email)
	emails_changed.emit()

func take_lead_by_phone_number(phone_number: String) -> Dictionary:
	var clean_number := clean_phone_number(phone_number)
	if clean_number == "" or called_phone_numbers.has(clean_number):
		return {}

	for email in get_daily_emails():
		if clean_phone_number(str(email.get("phone_number", ""))) != clean_number:
			continue

		called_phone_numbers[clean_number] = true
		daily_emails.erase(email)
		emails_changed.emit()
		if !email.get("is_real", false):
			return {}

		return email.duplicate(true)

	return {}

func clean_phone_number(phone_number: String) -> String:
	var clean_number := ""
	for i in range(phone_number.length()):
		var character := phone_number.substr(i, 1)
		if character >= "0" and character <= "9":
			clean_number += character

	return clean_number

func _generate_daily_emails() -> void:
	var database = preload("res://email_database.gd").new()
	daily_emails = []
	daily_emails_generated = true
	for i in range(DAILY_EMAIL_COUNT):
		daily_emails.append(database.generate_real_email())

	daily_emails.append(database.generate_fake_email())
	daily_emails.shuffle()
