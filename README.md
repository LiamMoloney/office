# OfficeShade Gameplay Code Map

This project now has a small sales pipeline:

1. Open the email app on the computer.
2. Dial the lead's phone number on the phone.
3. Use the phone and complete the first-impression timing minigame.
4. Choose a dialogue option based on the email attributes.
5. Close the sale.
6. If the sale succeeds, the phone queues the sale on the printer.
7. Print the report, staple the paper, and turn it in to Stanley.
8. Stanley pays from the paper's own payout data.

## Global State

### `Globals/game_context.gd`

`GameContext` owns the generated email leads and phone-number lookup. It does not own the live sale workflow.

Important values:

```gdscript
daily_emails
successful_phone_numbers
reported_phone_numbers
```

Important methods:

- `get_daily_emails()`: lazily generates the day's inbox
- `delete_daily_email(email)`: removes a lead
- `report_daily_email(email)`: removes and blocks a lead
- `take_lead_by_phone_number(phone_number)`: returns a real callable lead without removing it from the inbox
- `mark_phone_number_successful(phone_number)`: blocks a number after it has produced a sale

### `Globals/game_manager.gd`

Money is stored globally in `GameManager`.

Current money variables:

- `round_money`
- `monthly_money`

Legacy mirrors are also kept for older scripts:

- `ShiftMoney`
- `MonthlyMoney`

Use `GameManager.add_money(amount)` to pay the player. It updates both round and monthly money and emits `money_changed`.

## Email Leads

### `Globals/email_database.gd`

This file owns lead content:

- company names
- email domains
- phone greeting pool
- prompt opener pool
- customer attributes
- dialogue lines and their scores
- generated sale payout

To add new phone greetings, edit:

```gdscript
var phone_greetings = [
	"Hello?",
	...
]
```

To add client lines for the prompt phase, edit:

```gdscript
var prompt_openers = [
	"Okay. I'm listening.",
	...
]
```

To add a new customer attribute, add a new entry to `attributes` with:

- `display_name`
- exactly three `dialogue` lines

The three dialogue lines map to `DIALOGUE_SCORES = [-1, 0, 2]`.

### `Interactive/Computer/email.gd`

The email app shows the current generated lead.

The email app listens to `GameContext.emails_changed` and rebuilds its inbox when a lead is manually deleted or reported.

## Phone Flow

### `Interactive/Phone/phone.gd`

The phone owns the live call.

When a valid number is dialed:

- `GameContext.take_lead_by_phone_number()` returns the lead without removing its email
- the client's greeting appears at the top
- the first-impression bar appears
- all other phone labels/buttons are hidden until the timing minigame completes

The first-impression button is fixed. A small white indicator moves across the bar. Hitting the button near the middle sets a stronger base chance; far misses start much lower.

After that, the prompt minigame shows a random client opener and shuffled player dialogue options generated from the email attributes. The selected line modifies `success_chance`, then the player can close the sale.

On sale success, `phone.gd` marks the lead's phone number successful and emits `sale_queued(sale)`. Hanging up clears the phone's current call/result without touching printer queue, printed paper, stapled paper, or Stanley state.

## Report Turn-In Flow

### `Interactive/Printer/printer.gd`

The printer listens for `sale_queued(sale)` from the phone and stores queued sales locally. Interacting with the printer prints the next queued sale as a `SalePaper` from `Interactive/Paper/sale_paper.tscn`.

### `Interactive/Stapler/stapler.gd`

The stapler is pickupable with `E`. The player can hold one item at a time.

Stapling works either direction:

- hold the paper, then interact with the stapler
- hold the stapler, then interact with the paper

The paper shows its hidden `StapledMarker` mesh after stapling. Stapling is based only on the held paper/stapler objects, not a global sale step.

The stapler scene is `Interactive/Stapler/stapler.tscn` and is instanced in `Level.tscn`.

### `Interactive/Paper/sale_paper.gd`

The printer creates this pickupable paper after a successful sale.

The paper owns:

- `CompanyLabel`: front label with the company sale name
- `StapledMarker`: tiny mesh that is hidden until stapled
- payout data copied from the successful sale
- pickup behavior
- Stanley turn-in cleanup

### `Interactive/stanley_zone.gd`

Stanley accepts any held, stapled paper.

If the player tries to turn in an unstapled paper, he changes his label to:

```text
I need it stapled.
```

Stanley pays the paper's stored payout through:

```gdscript
GameManager.add_money(held_paper.get_payout())
```

The paper disappears when Stanley accepts it.

## Pickup Items

### `character_new.gd`

The player stores the currently held object in:

```gdscript
var held_item: Node3D
```

Useful methods:

- `pickup_item(item)`: holds an item if hands are empty
- `clear_held_item(item)`: clears the held item when it is turned in or put down
- `drop_held_item()`: drops the held item with `Q`
- `is_holding_pickup_type(type)`: checks for `"paper"` or `"stapler"`
- `get_hold_parent()`: returns the `Camera3D/Hand` node that held items are childed under
- `get_hold_transform()`: returns the hand's global transform
- `get_drop_transform()`: returns a camera-relative drop position clamped above the player's feet

Pickup items become children of `Camera3D/Hand` when picked up, so they do not chase the hand every frame. They implement `drop_from(player)` to detach back to the world, restore body collisions, and hand control back to physics. The paper and stapler both have body collision shapes so they collide with the floor after being dropped.

Held item local rotation is set with `held_rotation_offset_degrees` in each pickup script. Paper uses `Interactive/Paper/sale_paper.gd`; stapler uses `Interactive/Stapler/stapler.gd`.

## HUD

### `shift_hud.gd` and `shift_hud.tscn`

The HUD listens to `GameManager.money_changed`.

It shows:

- `Round: $...`
- `Month: $...`

If you change where money is stored, update `shift_hud.gd` to listen to the new signal or variables.

## Common Modifications

Change first-impression difficulty:

- edit `impression_speed` in `Interactive/Phone/phone.gd`
- edit `_get_impression_quality()` for the perfect-hit range and miss falloff

Change close-sale odds:

- edit `_set_first_impression_quality()` in `Interactive/Phone/phone.gd`
- edit `_choose_prompt_option()` for dialogue score impact

Change payouts:

- edit the `payout` value generated in `Globals/email_database.gd`

Add more physical steps:

1. Put the state on the physical object that owns the step.
2. Pass only the data that object needs.
3. Add or update an interactable script to act on that object directly.
