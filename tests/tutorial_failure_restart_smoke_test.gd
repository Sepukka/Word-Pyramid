extends Node

const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")

func _ready() -> void:
	get_tree().root.size = Vector2i(390, 844)
	var statistics_before: Dictionary = SaveManager.statistics.duplicate(true)
	_assert(GameState.start_tutorial(), "tutorial starts")
	var board: GameBoard = GAME_BOARD_SCENE.instantiate() as GameBoard
	get_tree().root.add_child.call_deferred(board)
	await get_tree().process_frame
	board.refresh()
	await get_tree().process_frame
	var intro: Control = board.get("_tutorial_intro_layer") as Control
	var start_button: Button = intro.find_child("TutorialStart", true, false) as Button if intro != null else null
	_assert(start_button != null, "tutorial introduction is available")
	start_button.pressed.emit()
	await get_tree().create_timer(0.25).timeout

	# Move to the independent practice stage, where all words are intentionally
	# interactive and the player can make genuine wrong guesses.
	board.set("_tutorial_stage", 5)
	board.call("_apply_tutorial_stage")
	await get_tree().process_frame
	var lives: HBoxContainer = board.get("_lives_row") as HBoxContainer
	_assert(lives.visible and lives.get_child_count() == 4, "four attempt markers stay visible at the bottom")

	var wrong_pairs: Array[Array] = [
		["CAT", "COW"],
		["DOG", "PIG"],
		["CAT", "HEN"],
		["DOG", "EAGLE"],
	]
	for index: int in wrong_pairs.size():
		for word_value: Variant in wrong_pairs[index]:
			GameState.toggle_word(str(word_value))
		_assert(GameState.can_check_selection(), "wrong tutorial pair %d can be checked" % index)
		GameState.check_selection()
		_assert(GameState.attempts_left == 3 - index, "attempt marker count updates after failure %d" % (index + 1))
		if index < wrong_pairs.size() - 1:
			GameState.clear_selection()

	await get_tree().create_timer(0.95).timeout
	var restart_cover: ColorRect = board.get("_tutorial_restart_layer") as ColorRect
	_assert(restart_cover != null, "a smooth restart cover appears after the final mistake")
	await get_tree().create_timer(0.75).timeout
	_assert(not GameState.is_finished, "tutorial starts over instead of staying failed")
	_assert(GameState.attempts_left == int(SaveManager.settings.get("attempts", 4)), "all tutorial attempts are restored")
	var restarted_intro: Control = board.get("_tutorial_intro_layer") as Control
	_assert(restarted_intro != null, "restart returns to the tutorial introduction")
	_assert(SaveManager.statistics == statistics_before, "failed practice does not affect real statistics")

	print("TUTORIAL_FAILURE_RESTART_SMOKE_TEST_PASS")
	board.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Tutorial failure restart smoke test failed: %s" % description)
	get_tree().quit(1)
