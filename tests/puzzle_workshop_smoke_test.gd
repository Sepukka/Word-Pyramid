extends Node

func _ready() -> void:
	var scene: PackedScene = load("res://scenes/tools/puzzle_workshop.tscn")
	assert(scene != null, "Puzzle Workshop scene must load")
	var workshop: Control = scene.instantiate()
	add_child(workshop)
	await get_tree().process_frame
	assert(workshop.get("_preview_pyramid") != null, "Workshop must build the phone preview")
	assert(workshop.get("_puzzle_list").item_count > 0, "Workshop must load the selected puzzle pool")
	assert(workshop.get("_group_inputs").size() == 4, "Workshop must have all four group editors")
	var puzzle: Dictionary = workshop.call("_form_to_puzzle")
	assert((puzzle.get("groups", []) as Array).size() == 4, "Workshop form must produce four groups")
	assert((workshop.call("_validate_with_extras", puzzle) as PackedStringArray).is_empty(), "Loaded project puzzle must validate")
	workshop.set("_language", "fi")
	workshop.set("_mode", "unlimited")
	assert(str(workshop.call("_next_id")).begins_with("fi_unlimited_"), "Finnish IDs must match the existing pool convention")
	workshop.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("PUZZLE_WORKSHOP_SMOKE_OK")
	get_tree().quit()
