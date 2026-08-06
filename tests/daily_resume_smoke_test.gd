extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	get_tree().root.size = Vector2i(390, 844)
	SaveManager.save_path = "res://.godot-test-data/daily_resume_save.json"
	SaveManager.reset_to_defaults()
	SaveManager.complete_onboarding()
	SaveManager.progression["total_xp"] = SaveManager.xp_threshold_for_level(SaveManager.DAILY_UNLOCK_LEVEL)
	_assert(PuzzleLoader.set_language("en"), "English puzzles load")
	_assert(GameState.start_new_game(GameState.DAILY_MODE), "Daily starts")

	var two_word_group: Array[String] = _group_words(2)
	for word: String in two_word_group:
		GameState.toggle_word(word)
	GameState.check_selection()
	_assert(GameState.solved_groups.size() == 1, "one Daily row is solved before closing")

	GameState.request_hint()
	_assert(GameState.hints_used == 1, "used hint is recorded")
	var three_word_group: Array[String] = _group_words(3)
	var four_word_group: Array[String] = _group_words(4)
	for word: String in [three_word_group[0], three_word_group[1], four_word_group[0]]:
		GameState.toggle_word(word)
	GameState.check_selection()
	_assert(GameState.attempts_left == SaveManager.MAX_ATTEMPTS - 1, "used attempt is recorded")
	GameState.clear_selection()
	GameState.toggle_word(three_word_group[2])

	var expected_puzzle_id: String = str(GameState.puzzle.get("id", ""))
	var expected_selection: Array[String] = GameState.selected_words.duplicate()
	var expected_solved_groups: Array[int] = GameState.solved_groups.duplicate()
	var expected_attempts: int = GameState.attempts_left
	var expected_hints: int = GameState.hints_used
	var expected_hint_rows: Dictionary = GameState.hinted_words_by_row.duplicate(true)
	_assert(GameState.has_resumable_game(GameState.DAILY_MODE), "same-day Daily is resumable")

	# Simulate a fresh application process while leaving the on-disk active game.
	GameState.reset_debug_state()
	var main: Control = MAIN_SCENE.instantiate() as Control
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	main.call("_on_play_pressed")
	await get_tree().create_timer(0.85).timeout

	_assert(str(GameState.puzzle.get("id", "")) == expected_puzzle_id, "Daily reopens the same puzzle")
	_assert(GameState.selected_words == expected_selection, "current word selection is restored")
	_assert(GameState.solved_groups == expected_solved_groups, "solved rows are restored")
	_assert(GameState.attempts_left == expected_attempts, "remaining attempts are restored")
	_assert(GameState.hints_used == expected_hints, "hint count is restored")
	_assert(GameState.hinted_words_by_row == expected_hint_rows, "locked hint words are restored")
	_assert(main.get("_active_view") is GameBoard, "Daily resumes into the gameplay screen")

	print("DAILY_RESUME_SMOKE_TEST_PASS")
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _group_words(row_length: int) -> Array[String]:
	for group_value: Variant in GameState.puzzle.get("groups", []):
		if group_value is Dictionary:
			var group: Dictionary = group_value
			if int(group.get("size", 0)) == row_length:
				var words: Array[String] = []
				for word_value: Variant in group.get("words", []):
					words.append(str(word_value))
				return words
	return []

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Daily resume smoke test failed: %s" % description)
	get_tree().quit(1)
