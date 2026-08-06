extends Node

const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")

func _ready() -> void:
	get_tree().root.size = Vector2i(390, 844)
	SaveManager.save_path = "res://.godot-test-data/rewarded_last_chance_save.json"
	SaveManager.reset_to_defaults()
	SaveManager.complete_onboarding()
	SaveManager.progression["total_xp"] = SaveManager.xp_threshold_for_level(SaveManager.DAILY_UNLOCK_LEVEL)
	_assert(PuzzleLoader.set_language("en"), "English puzzles load")
	_assert(GameState.start_new_game(GameState.UNLIMITED_MODE), "Infinity puzzle starts")
	var hearts_before: int = SaveManager.get_endless_hearts()
	var board: GameBoard = GAME_BOARD_SCENE.instantiate() as GameBoard
	get_tree().root.add_child.call_deferred(board)
	await get_tree().process_frame
	board.refresh()
	await get_tree().process_frame

	GameState.attempts_left = 1
	_submit_wrong_pair(0)
	_assert(GameState.last_chance_pending, "empty Stamina pauses at the last-chance decision")
	_assert(not GameState.is_finished and not GameState.is_auto_solving, "solution is not revealed before the decision")
	_assert(SaveManager.get_endless_hearts() == hearts_before, "Infinity heart is not consumed by the offer")
	await get_tree().create_timer(0.8).timeout
	var offer: Control = board.get("_last_chance_layer") as Control
	_assert(offer != null and offer.is_visible_in_tree(), "last-chance offer is visible")
	var action: Button = board.get("_last_chance_action") as Button
	_assert(action != null and not action.disabled, "desktop continue is immediately available")
	action.pressed.emit()
	await get_tree().process_frame
	_assert(not GameState.last_chance_pending and GameState.attempts_left == 1, "one mistake is restored")
	_assert(GameState.last_chance_used, "the puzzle remembers that its rewarded continue was used")
	_assert(not GameState.is_finished, "puzzle continues after the reward")
	_assert(SaveManager.get_endless_hearts() == hearts_before, "continuing does not consume an Infinity heart")

	_submit_wrong_pair(1)
	_assert(not GameState.last_chance_pending, "the rewarded continue is not offered twice")
	_assert(GameState.is_auto_solving and not GameState.is_finished, "a later empty Stamina starts the normal reveal")
	_assert(SaveManager.get_endless_hearts() == hearts_before, "heart waits until the reveal has finished")
	await get_tree().create_timer(5.7).timeout
	_assert(GameState.is_finished and not GameState.completed_won, "declining records the normal loss")
	_assert(SaveManager.get_endless_hearts() == hearts_before - 1, "Infinity heart is consumed exactly once")

	print("REWARDED_LAST_CHANCE_SMOKE_TEST_PASS")
	board.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _submit_wrong_pair(variant: int) -> void:
	var pair: Array[String] = []
	var two: Array[String] = _group_words(2)
	var three: Array[String] = _group_words(3)
	pair.append(two[variant % two.size()])
	pair.append(three[variant % three.size()])
	for word: String in pair:
		GameState.toggle_word(word)
	_assert(GameState.can_check_selection(), "mixed-group pair can be checked")
	GameState.check_selection()

func _group_words(row_length: int) -> Array[String]:
	for value: Variant in GameState.puzzle.get("groups", []):
		if value is Dictionary and int((value as Dictionary).get("size", 0)) == row_length:
			var result: Array[String] = []
			for word: Variant in (value as Dictionary).get("words", []):
				result.append(str(word))
			return result
	return []

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Rewarded last-chance smoke test failed: %s" % description)
	get_tree().quit(1)
