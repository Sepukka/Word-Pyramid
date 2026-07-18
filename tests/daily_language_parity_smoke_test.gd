extends Node

func _ready() -> void:
	var english_root := _read_root("res://data/daily_puzzles.json")
	var finnish_root := _read_root("res://data/daily_puzzles_fi.json")
	var english_puzzles: Array = english_root.get("puzzles", []) as Array
	var finnish_puzzles: Array = finnish_root.get("puzzles", []) as Array
	var english_schedule: Dictionary = english_root.get("schedule", {}) as Dictionary
	var finnish_schedule: Dictionary = finnish_root.get("schedule", {}) as Dictionary
	assert(english_puzzles.size() >= 45 and finnish_puzzles.size() >= 45, "Both languages must contain the new Daily puzzle set")

	for number: int in range(1, 46):
		var suffix := "%03d" % number
		var english_id := "daily_%s" % suffix
		var finnish_id := "fi_daily_%s" % suffix
		var english_puzzle := _find_puzzle(english_puzzles, english_id)
		var finnish_puzzle := _find_puzzle(finnish_puzzles, finnish_id)
		assert(not english_puzzle.is_empty(), "Missing English Daily pair: %s" % english_id)
		assert(not finnish_puzzle.is_empty(), "Missing Finnish Daily pair: %s" % finnish_id)
		assert(str(english_schedule.get(english_id, "")) == str(finnish_schedule.get(finnish_id, "")), "Daily pair has different schedule dates: %s" % suffix)
		var english_groups: Array = english_puzzle.get("groups", []) as Array
		var finnish_groups: Array = finnish_puzzle.get("groups", []) as Array
		assert(english_groups.size() == 4 and finnish_groups.size() == 4, "Daily pair must contain four groups: %s" % suffix)
		for group_index: int in range(4):
			var english_group: Dictionary = english_groups[group_index] as Dictionary
			var finnish_group: Dictionary = finnish_groups[group_index] as Dictionary
			assert(int(english_group.get("size", 0)) == int(finnish_group.get("size", 0)), "Translated group sizes differ: %s" % suffix)
			assert((english_group.get("words", []) as Array).size() == (finnish_group.get("words", []) as Array).size(), "Translated word counts differ: %s" % suffix)

	assert(PuzzleLoader.set_language("en"), "English Daily data must load")
	_validate_loaded_daily("English")
	assert(PuzzleLoader.set_language("fi"), "Finnish Daily data must load")
	_validate_loaded_daily("Finnish")
	print("DAILY_LANGUAGE_PARITY_SMOKE_TEST_PASS")
	get_tree().quit()

func _read_root(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "Could not open %s" % path)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert(parsed is Dictionary, "Invalid JSON in %s" % path)
	return parsed as Dictionary

func _find_puzzle(puzzles: Array, puzzle_id: String) -> Dictionary:
	for puzzle_value: Variant in puzzles:
		if puzzle_value is Dictionary and str((puzzle_value as Dictionary).get("id", "")) == puzzle_id:
			return puzzle_value as Dictionary
	return {}

func _validate_loaded_daily(language_name: String) -> void:
	for puzzle: Dictionary in PuzzleLoader.get_puzzles("daily"):
		var errors := PuzzleLoader.validate_puzzle(puzzle)
		assert(errors.is_empty(), "%s puzzle %s is invalid: %s" % [language_name, str(puzzle.get("id", "")), ", ".join(errors)])
