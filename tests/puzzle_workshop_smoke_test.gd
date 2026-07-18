extends Node

func _ready() -> void:
	var scene: PackedScene = load("res://scenes/tools/puzzle_workshop.tscn")
	assert(scene != null, "Puzzle Workshop scene must load")
	var workshop: Control = scene.instantiate()
	add_child(workshop)
	await get_tree().process_frame
	assert(workshop.get("_preview_pyramid") != null, "Workshop must build the phone preview")
	assert(workshop.get("_tabs").get_tab_count() == 3, "Workshop must expose library, editor, and preview tabs")
	assert(workshop.get("_puzzle_list").item_count > 0, "Workshop must load the selected puzzle pool")
	assert(workshop.get("_group_inputs").size() == 4, "Workshop must have all four group editors")
	var puzzle: Dictionary = workshop.call("_form_to_puzzle")
	assert((puzzle.get("groups", []) as Array).size() == 4, "Workshop form must produce four groups")
	assert((workshop.call("_validate_with_extras", puzzle) as PackedStringArray).is_empty(), "Loaded project puzzle must validate")
	workshop.call("_new_puzzle")
	await get_tree().process_frame
	await get_tree().process_frame
	var viewport_right: float = workshop.get_global_rect().end.x
	_assert_no_horizontal_overflow(workshop, viewport_right)
	workshop.set("_language", "fi")
	workshop.set("_mode", "unlimited")
	assert(str(workshop.call("_next_id")).begins_with("fi_unlimited_"), "Finnish IDs must match the existing pool convention")
	remove_child(workshop)
	workshop.free()
	print("PUZZLE_WORKSHOP_SMOKE_OK")
	get_tree().quit()

func _assert_no_horizontal_overflow(node: Node, viewport_right: float) -> void:
	for child: Node in node.get_children():
		if child is Control:
			var control := child as Control
			if control.is_visible_in_tree():
				assert(control.get_global_rect().end.x <= viewport_right + 0.5, "%s overflowed the Workshop viewport" % control.name)
		_assert_no_horizontal_overflow(child, viewport_right)
