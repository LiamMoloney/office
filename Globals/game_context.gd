extends Node

signal emails_changed

const DAILY_EMAIL_COUNT := 6

var daily_emails := []
var daily_emails_generated := false
var successful_phone_numbers := {}
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

	daily_emails.erase(email)
	emails_changed.emit()

func take_lead_by_phone_number(phone_number: String) -> Dictionary:
	var clean_number := clean_phone_number(phone_number)
	if clean_number == "" or successful_phone_numbers.has(clean_number) or reported_phone_numbers.has(clean_number):
		return {}

	for email in get_daily_emails():
		if clean_phone_number(str(email.get("phone_number", ""))) != clean_number:
			continue

		if !email.get("is_real", false):
			return {}

		return email.duplicate(true)

	return {}

func mark_phone_number_successful(phone_number: String) -> void:
	var clean_number := clean_phone_number(phone_number)
	if clean_number != "":
		successful_phone_numbers[clean_number] = true

func clean_phone_number(phone_number: String) -> String:
	var clean_number := ""
	for i in range(phone_number.length()):
		var character := phone_number.substr(i, 1)
		if character >= "0" and character <= "9":
			clean_number += character

	return clean_number

func _generate_daily_emails() -> void:
	daily_emails = []
	daily_emails_generated = true
	for i in range(DAILY_EMAIL_COUNT):
		daily_emails.append(EmailDatabase.generate_real_email())

	daily_emails.append(EmailDatabase.generate_fake_email())
	daily_emails.shuffle()
