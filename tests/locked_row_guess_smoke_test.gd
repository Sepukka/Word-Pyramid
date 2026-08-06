extends Node

func _ready() -> void:
	SaveManager.save_path = "res://.godot-test-data/locked_row_guess_save.json"
	SaveManager.reset_to_defaults()
	SaveManager.complete_onboarding()
	SaveManager.progression["total_xp"] = SaveManager.xp_threshold_for_level(SaveManager.DAILY_UNLOCK_LEVEL)
	_assert(PuzzleLoader.set_language("en"), "English puzzles load")

	_verify_mode(GameState.DAILY_MODE)
	GameState.reset_debug_state()
	_verify_mode(GameState.UNLIMITED_MODE)

	print("LOCKED_ROW_GUESS_SMOKE_TEST_PASS")
	get_tree().quit()

func _verify_mode(mode: String) -> void:
	_assert(GameState.start_new_game(mode), "%s puzzle starts" % mode)

	var four_word_group: Array[String] = _group_words(4)
	for word: String in four_word_group:
		GameState.toggle_word(word)
	_assert(GameState.can_check_selection(), "%s four-word row can initially be checked" % mode)
	GameState.check_selection()
	_assert(_row_is_solved(4), "%s four-word row locks after solving" % mode)

	# Four words from the unsolved five-word row used to reopen Check through
	# the generic "missing one word" near-miss path.
	var near_miss_four: Array[String] = _group_words(5).slice(0, 4)
	for word: String in near_miss_four:
		GameState.toggle_word(word)
	_assert(not GameState.can_check_selection(), "%s locked row size also blocks a five-row near miss" % mode)
	var near_miss_attempts_before: int = GameState.attempts_left
	GameState.check_selection()
	_assert(GameState.attempts_left == near_miss_attempts_before, "%s blocked near miss consumes no Stamina" % mode)
	GameState.clear_selection()

	GameState.request_hint()
	var hinted_words: Array[String] = GameState.get_hint_words_for_row(5)
	_assert(hinted_words.size() == 1, "%s first hint is locked into the five-word row" % mode)

	var invalid_four: Array[String] = _group_words(2)
	invalid_four.append_array(_group_words(3).slice(0, 2))
	for word: String in invalid_four:
		GameState.toggle_word(word)
	_assert(GameState.selected_words.size() == 4, "%s can select four available words" % mode)
	_assert(not GameState.can_check_selection(), "%s cannot re-guess the locked four-word row size" % mode)
	var attempts_before: int = GameState.attempts_left
	GameState.check_selection()
	_assert(GameState.attempts_left == attempts_before, "%s blocked four-word guess consumes no Stamina" % mode)

	GameState.clear_selection()
	var hinted_five_completion: Array[String] = _group_words(5)
	hinted_five_completion.erase(hinted_words[0])
	_assert(hinted_five_completion.size() == 4, "%s hinted five-word row has four selectable words" % mode)
	for word: String in hinted_five_completion:
		GameState.toggle_word(word)
	_assert(GameState.can_check_selection(), "%s exact hinted-row completion remains checkable" % mode)
	GameState.check_selection()
	_assert(_row_is_solved(5), "%s hinted five-word row is solved correctly" % mode)

func _group_words(row_length: int) -> Array[String]:
	for group_value: Variant in GameState.puzzle.get("groups", []):
		if group_value is Dictionary and int((group_value as Dictionary).get("size", 0)) == row_length:
			var words: Array[String] = []
			for word_value: Variant in (group_value as Dictionary).get("words", []):
				words.append(str(word_value))
			return words
	return []

func _row_is_solved(row_length: int) -> bool:
	for index: int in GameState.solved_groups:
		if index < 0 or index >= GameState.puzzle.get("groups", []).size():
			continue
		var group_value: Variant = GameState.puzzle["groups"][index]
		if group_value is Dictionary and int((group_value as Dictionary).get("size", 0)) == row_length:
			return true
	return false

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Locked-row guess smoke test failed: %s" % description)
	get_tree().quit(1)
