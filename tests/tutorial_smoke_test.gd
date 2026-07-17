extends Node

func _ready() -> void:
	SaveManager.reset_all_data()
	_assert(SaveManager.needs_language_onboarding(), "fresh installs require a language choice")
	SaveManager.mark_onboarding_language_selected()
	_assert(not SaveManager.needs_language_onboarding(), "language choice is remembered")
	_assert(SaveManager.needs_tutorial_onboarding(), "tutorial still follows the language choice")
	SaveManager.complete_onboarding()
	_assert(not SaveManager.needs_tutorial_onboarding(), "completed onboarding is not shown again")
	var statistics_before: Dictionary = SaveManager.statistics.duplicate(true)
	var active_game_before: Dictionary = SaveManager.active_game.duplicate(true)
	var completed: Array[bool] = [false]
	GameState.tutorial_completed.connect(func() -> void: completed[0] = true)
	_assert(GameState.start_tutorial(), "tutorial starts")
	_solve_row(2)
	GameState.set_tutorial_allowed_words([])
	GameState.request_hint()
	_assert(GameState.get_hint_words_for_row(5).size() == 1, "hint is placed in the five-word row")
	_solve_row(5)
	_solve_row(3)
	_solve_row(4)
	_solve_row(1)
	_assert(completed[0], "tutorial completes")
	_assert(SaveManager.statistics == statistics_before, "tutorial leaves statistics unchanged")
	_assert(SaveManager.active_game == active_game_before, "tutorial leaves the real active game unchanged")
	print("TUTORIAL_SMOKE_TEST_PASS")
	get_tree().quit()

func _solve_row(row_length: int) -> void:
	var words: Array[String] = GameState.tutorial_group_words(row_length)
	GameState.set_tutorial_allowed_words(words)
	for word: String in words:
		GameState.toggle_word(word)
	_assert(GameState.can_check_selection(), "row %d can be checked" % row_length)
	GameState.check_selection()

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Tutorial smoke test failed: %s" % description)
	get_tree().quit(1)
