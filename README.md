# OfficeShade Clean Slate

This project is currently stripped back to the basic office/computer/phone foundation.

The computer still exists. The fake monitor mouse still works. The desktop icon emits a signal when clicked. The phone is interactable. The old global state, round manager, email app, database, and content systems have been removed so you can rebuild the gameplay yourself from a cleaner base.

## Current PC Setup

### `Interactive/monitor.gd`

This is the physical computer/monitor object in the 3D office.

It handles:

- entering computer view
- locking player input while using the computer
- moving the fake cursor with real mouse motion
- forwarding mouse movement and clicks into the monitor `SubViewport`
- exiting computer view with `esc`

The important node references are:

```gdscript
@onready var pc_control: Control = $SubViewport/PCControl
@onready var sub_viewport: SubViewport = $SubViewport
```

### `Interactive/pc_control.gd`

This is the 2D desktop UI shown on the monitor.

Right now it only has:

- `MouseCursor`
- `Icon`
- `desktop_icon_pressed` signal

The signal is emitted here:

```gdscript
func _on_desktop_icon_pressed() -> void:
	desktop_icon_pressed.emit()
	print("desktop icon pressed")
```

Use this signal as the starting point for whatever app or system you want to build next.

### `Interactive/pc_control.tscn`

This scene now contains only:

- background
- icon
- fake cursor

There is no email window or application UI in it anymore.

### `icon.tscn`

This is the reusable desktop icon scene.

It is a `Button` with a texture and label. The current label is `ICON`.

## Still Existing Systems

### `Interactive/phone.gd`

The phone is currently just an interactable placeholder.

It handles:

- entering phone view
- locking player input while using the phone
- showing a simple dialog
- leaving with `Hang Up` or `esc`

It does not connect to sales, emails, globals, or a database.

### `character_new.gd`

Player movement, mouse look, and interact key handling.

The important variable is:

```gdscript
var input_locked := false
```

The computer sets this to `true` while you are using the monitor, then back to `false` when you leave.

### `Interactive/interactable.gd`

Generic interaction component.

The PC, phone, printer, and other interactable objects use this pattern:

```gdscript
signal interacted(actor)
```

### `Level.tscn`

Main office scene. Use the Godot editor to move or add objects.

### `project.godot`

Project settings and autoloads.

At this point, there are no project autoloads.

## Removed For Now

The old content/database/app/state layer has been removed:

- no email app in `pc_control.gd`
- no email window in `pc_control.tscn`
- no `EmailDatabase`
- no `EmailContent` files
- no `Global` autoload
- no `RoundManager` autoload
- no global sale pipeline
- no shift/month system

## Good Next Step

Build one tiny thing from the desktop icon signal.

For example:

1. Connect to `desktop_icon_pressed`.
2. Print a message.
3. Show one simple panel.
4. Add one button to that panel.

That will give you a small system you understand before adding emails, sales, or more game state.
