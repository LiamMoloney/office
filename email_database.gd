extends Node

const DIALOGUE_SCORES = [-1, 0, 2]
const PROMPT_OPTION_TYPES = ["questions", "dialogue"]

var company_names = [
	"Johns Bakery and Gun Store",	"Oragami League of America", "Blurple Studios",
	"Paper Champs Incorporated", "Alpha Ro Frat", "Gebidi Battery",
	"Genius Book of Records", "WoofWoof Dog Lovers", "baseballguy", "Paper Lovers"
]
var fake_company_names = [
	"Johns Bakrey",	"JV Oragami Club", "Blurpled Studios",
	"Papers Champz Incorporated", "Jambda Indigo Mecho Frat", "Gebidi Violence and Mafia funding",
	"Cero Trust Insurance", "Meowy Grooming", "The NY Political"
]

var email_domains = [ "welovepaper.com", "giveuspaper.gov", "company.co.com", "pleasereply.im.lonely.com", "dontatme.com", "public-files.gov",
"stinkyfellas-wedooddjobs.org", "gimmeaname.com", "123paper.com", "professionals.com", "ArshArshArsh.com"
]
var fake_email_domains = ["poo.stink", "jimbots3000.c0m", "321papyrus.<om", "snailmail.com", "dont-reply-just-do-it.government",
"smartfellas..gov", "fartsmellas.himothy.com"]

var phone_greetings = [
	"Hello?",
	"Yeah, who's this?",
	"Hi. You've got about thirty seconds.",
	"This is reception. Make it good.",
	"Hello!"
]

var prompt_openers = [
	"SHUTUP MOM... sorry how can I help you",
	"Hello who is this?",
	"Yea yea get on with it.",
	"what?",
	"I can hear you. Make it quick.",
	"Whatup",
	"Speak to me"
]

var email_body_templates = [
	"Hello we are looking to buy paper. Please call us at {phone_number} when you have a moment.",
	"Hello, we are looking to buy paper for {company}. The number to reach us is {phone_number}.",
	"Good afternoon. {company} needs a reliable paper supplier. Please call {phone_number}.",
	"Hi there, we are shopping for office paper and would like to hear your offer. Reach us at {phone_number}.",
	"Hello. We need paper soon and would like pricing information. Call {company} at {phone_number}.",
	"To whom it may concern, {company} is looking for paper. Our callback number is {phone_number}."
]


var attributes = {
	"loves_dogs": {
		"display_name": "Loves Dogs",
		"questions": [
			[
				"Do you want to hear a horse sound?",
				"Would your dog prefer paper if I made barnyard noises first?"
			],
			[
				"*Sneeze into phone*",
				"Do you keep any paper around?"
			],
			[
				"Who's a good buyer who needs premium paper today?",
				"WOOF WOOF my man! Hows it hanging my D A W G?",
				"Would your dog want you to get stinky bad paper, or top shelf stuff?"
			]
		],
		"dialogue": [
			[
				"So how about you bu some paper and we go hunting this weekend?",
				"NEEEEEEEIGH",
				"I, too, am familiar with animals. Please buy paper."
			],
			[
				"I heard rover loves to bark, thats a clever dog",
				"I heard you run a dog-friendly shop, and our paper is easy to keep around."
			],
			[
				"Well you let me know, I've got to go give my golden retriever a snack.",
				"Your customers love dogs, and dogs love a clean receipt. Let's get you stocked."
			]
		]
	},

	"cheap": {
		"display_name": "cheap",
		"questions": [
			[
				"Would you buy paper if I said it was basically free, even though it isn't?",
				"Are you cheap enough to hear me out? We have paper to move."
			],
			[
				"Would a lower price make this worth looking at?",
				"Are you mainly shopping by price today?"
			],
			[
				"What if I could keep your paper costs low without making it feel low quality?",
				"Would you be interested in the best value bundle we can offer?"
			]
		],
		"dialogue": [
			[
				"Whats up you cheap bastard you! Ive got some dirt cheap prices for you.",
				"I know you love a bargain, so I brought the bargain directly to your phone."
			],
			[
				"Our paper game is elite! You gotta try some of this.",
				"We can keep this practical: solid paper, reasonable price, no drama."
			],
			[
				"WAAAIT WE MESSED UP. Our prices are TOO LOW. If you order now we could go out of business!",
				"I can get you a bulk price that keeps the budget happy and the printer fed."
			]
		]
	},

	"fancy": {
		"display_name": "fancy",
		"questions": [
			[
				"Would you consider paper if I described it with at least five expensive adjectives?",
				"Do you require your paper to sound richer than me?"
			],
			[
				"Are you looking for something a little more polished than standard office paper?",
				"Would a premium paper option make sense for your office?"
			],
			[
				"Would your subjects notice if every page felt more professional?",
				"Can I interest you in paper that actually matches the image your company presents?"
			]
		],
		"dialogue": [
			[
				"This paper is nonstick, kosher, animal friendly, and environmentally concious.",
				"Our paper has the elegance of a fancy mackies"
			],
			[
				"I'm calling you from the top of my penthouse and this paper just came across my desk.",
				"We have a premium stock that would fit the better-than-you image you're maintaining."
			],
			[
				"Mmm yes paper, the gold of trees and men alike, what complex joy it brings.",
				"This is the paper you buy when every memo needs to look like it has a trust fund."
			]
		]
	},
	"violence": {
		"display_name": "Violent History",
		"questions": [
			[
				"Do you want paper tough enough to survive whatever keeps happening over there?",
				"Are you afraid of the dark?"
			],
			[
				"Would a sturdier paper supply help keep things organized?",
				"Are you looking for paper that can handle a rough workday?"
			],
			[
				"It's so funny when some little guy thinks he could fight you right?",
				"Would it help to have paper strong enough for your busiest days?"
			]
		],
		"dialogue": [
			[
				"I heard you solve every problem with your hands, well this is paper for people with hands",
				"Our paper was actually used for wanted posters back in the day"
			],
			[
				"Yeah this paper is ok if you want some.",
				"This stock is durable, practical, and less likely to start an incident."
			],
			[
				"Body builders are always practicing tearing phone books by using our reams of paper.",
				"Our paper was once used by outlaws for counterfeit money for guns and cool stuff."
			]
		]
	}
}

func get_random_attributes():
	var attribute_keys = attributes.keys()
	attribute_keys.shuffle()

	return [attribute_keys[0], attribute_keys[1]]

func get_dialogue_options(attribute_key: String, option_type := "") -> Array:
	if !attributes.has(attribute_key):
		return []

	var attribute = attributes[attribute_key]
	var selected_type := option_type
	if selected_type == "" or !attribute.has(selected_type):
		selected_type = PROMPT_OPTION_TYPES.pick_random()

	if !attribute.has(selected_type):
		selected_type = "dialogue"

	return _build_scored_options(attribute[selected_type], selected_type)

func _build_scored_options(option_groups: Array, option_type: String) -> Array:
	var options := []
	for i in range(mini(option_groups.size(), DIALOGUE_SCORES.size())):
		var option_group = option_groups[i]
		var option_text := ""
		if option_group is Array:
			option_text = str(option_group.pick_random())
		else:
			option_text = str(option_group)

		options.append({
			"text": option_text,
			"score": DIALOGUE_SCORES[i],
			"type": option_type
		})
	return options

func get_prompt_opener() -> String:
	return prompt_openers.pick_random()

func generate_real_email():
	var selected_attributes = get_random_attributes()
	var company = company_names.pick_random()
	var domain = email_domains.pick_random()
	var phone_number := _generate_phone_number()
	var attribute_names := PackedStringArray()
	for attribute_key in selected_attributes:
		attribute_names.append(attributes[attribute_key]["display_name"])

	var body := _get_email_body(company, phone_number)
	return {
		"is_real": true,
		"company": company,
		"sender": "leads@" + domain,
		"phone_number": phone_number,
		"client_greeting": phone_greetings.pick_random(),
		"attributes": selected_attributes,
		"attribute_names": attribute_names,
		"payout": randi_range(85, 180),
		"summary": "from leads@%s\nClient: %s wants to hear about paper today.\nPhone: %s\n\nClient info:\n%s" % [domain, company, phone_number, ", ".join(attribute_names)],
		"body": body
	}

func generate_fake_email():
	var selected_attributes = get_random_attributes()
	var company = fake_company_names.pick_random()
	var domain = fake_email_domains.pick_random()
	var phone_number := _generate_phone_number()
	var attribute_names := PackedStringArray()
	for attribute_key in selected_attributes:
		attribute_names.append(attributes[attribute_key]["display_name"])
	var body := _get_email_body(company, phone_number)
	return {
		"is_real": false,
		"company": company,
		"sender": "leads@" + domain,
		"phone_number": phone_number,
		"client_greeting": phone_greetings.pick_random(),
		"attributes": selected_attributes,
		"attribute_names": attribute_names,
		"summary": "from leads@%s\nClient: %s wants to hear about paper today.\nPhone: %s\n\nClient info:\n%s" % [domain, company, phone_number, ", ".join(attribute_names)],
		"body": body
	}

func _get_email_body(company: String, phone_number: String) -> String:
	var body := str(email_body_templates.pick_random())
	body = body.replace("{company}", company)
	body = body.replace("{phone_number}", phone_number)
	return body

func _generate_phone_number() -> String:
	var phone_number := ""
	for i in range(5):
		var min_digit := 1 if i == 0 else 0
		phone_number += str(randi_range(min_digit, 9))

	return phone_number
