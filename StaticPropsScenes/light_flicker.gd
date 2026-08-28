extends Node

@export var flicker_count := 2
@export var flicker_step_s := 0.2

var is_flickering := false

func flicker() -> void:
	if is_flickering:
		return

	is_flickering = true
	var light_states := _get_light_states()
	var bulb_states := _get_bulb_states()

	for i in range(flicker_count):
		_set_light_states(light_states, false)
		_set_bulb_states(bulb_states, false)
		await get_tree().create_timer(flicker_step_s).timeout
		_set_light_states(light_states, true)
		_set_bulb_states(bulb_states, true)
		await get_tree().create_timer(flicker_step_s).timeout

	_restore_light_states(light_states)
	_restore_bulb_states(bulb_states)
	is_flickering = false

func _get_light_states() -> Array:
	var states := []
	for child in find_children("*", "Light3D", true, false):
		states.append({
			"node": child,
			"visible": child.visible,
			"energy": child.light_energy
		})
	return states

func _get_bulb_states() -> Array:
	var states := []
	for child in find_children("Bulb*", "MeshInstance3D", true, false):
		states.append({
			"node": child,
			"visible": child.visible
		})
	return states

func _set_light_states(states: Array, is_on: bool) -> void:
	for state in states:
		var light := state["node"] as Light3D
		if light == null:
			continue

		light.visible = is_on
		light.light_energy = float(state["energy"]) if is_on else 0.0

func _set_bulb_states(states: Array, is_on: bool) -> void:
	for state in states:
		var bulb := state["node"] as MeshInstance3D
		if bulb == null:
			continue

		bulb.visible = is_on

func _restore_light_states(states: Array) -> void:
	for state in states:
		var light := state["node"] as Light3D
		if light == null:
			continue

		light.visible = bool(state["visible"])
		light.light_energy = float(state["energy"])

func _restore_bulb_states(states: Array) -> void:
	for state in states:
		var bulb := state["node"] as MeshInstance3D
		if bulb == null:
			continue

		bulb.visible = bool(state["visible"])
