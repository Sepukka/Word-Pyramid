extends Node

const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")

func _ready() -> void:
	get_tree().root.size = Vector2i(390, 844)
	var original_language: String = str(SaveManager.settings.get("language", "en"))
	SaveManager.settings["language"] = "en"
	var puzzles: Array[Dictionary] = PuzzleLoader.get_puzzles(GameState.DAILY_MODE)
	assert(not puzzles.is_empty(), "Aftermath smoke test needs a daily puzzle")
	GameState.puzzle = puzzles[0].duplicate(true)
	GameState.daily_date = ""
	GameState.game_mode = GameState.DAILY_MODE
	GameState.selected_words.clear()
	GameState.solved_groups = [0, 1, 2, 3]
	GameState.result_solved_groups = [0, 1, 2]
	GameState.is_top_solved = true
	GameState.is_finished = true
	GameState.completed_won = false
	GameState.is_auto_solving = false
	GameState.attempts_left = 0
	GameState.hints_used = 1
	GameState.result_correct_count = 9
	SaveManager.endless_state = {
		"date": Time.get_date_string_from_system(),
		"hearts": SaveManager.ENDLESS_DAILY_HEARTS,
		"rewarded_heart_claimed": false,
	}

	var board: GameBoard = GAME_BOARD_SCENE.instantiate() as GameBoard
	get_tree().root.add_child.call_deferred(board)
	await get_tree().process_frame
	await get_tree().process_frame
	board.call("_show_aftermath", false)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert_common_b1_layout(board)
	var daily_primary: Button = board.find_child("PrimaryAction", true, false) as Button
	assert(daily_primary != null and daily_primary.text == SaveManager.text("continue_to_unlimited"), "Daily aftermath has the wrong continuation label")
	var daily_flame: TextureRect = board.find_child("StreakFlame", true, false) as TextureRect
	assert(daily_flame != null and daily_flame.visible, "Daily aftermath must show the streak flame")

	await board.call("_dismiss_aftermath")
	await get_tree().process_frame
	GameState.game_mode = GameState.UNLIMITED_MODE
	GameState.completed_won = true
	GameState.result_solved_groups = [0, 1, 2, 3]
	board.call("_show_aftermath", true)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert_common_b1_layout(board)
	var endless_primary: Button = board.find_child("PrimaryAction", true, false) as Button
	assert(endless_primary != null and endless_primary.text == SaveManager.text("continue_to_next"), "Infinity aftermath has the wrong continuation label")
	var endless_flame: TextureRect = board.find_child("StreakFlame", true, false) as TextureRect
	assert(endless_flame != null and not endless_flame.visible, "Infinity aftermath should use hearts instead of the daily streak flame")

	await board.call("_dismiss_aftermath")
	await get_tree().process_frame
	SaveManager.settings["language"] = "fi"
	board.call("_show_aftermath", true)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert_common_b1_layout(board)
	var finnish_primary: Button = board.find_child("PrimaryAction", true, false) as Button
	assert(finnish_primary != null and finnish_primary.text == SaveManager.text("continue_to_next"), "Finnish Infinity aftermath has the wrong continuation label")
	SaveManager.settings["language"] = original_language

	print("B1 aftermath smoke test passed: English and Finnish phone layouts")
	board.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _assert_common_b1_layout(board: GameBoard) -> void:
	var layer: Control = board.find_child("AftermathLayer", true, false) as Control
	assert(layer != null, "B1 aftermath did not create its full-screen layer")
	var page: VBoxContainer = board.find_child("AftermathPage", true, false) as VBoxContainer
	assert(page != null, "B1 aftermath did not create its page container")
	assert(page.get_combined_minimum_size().x <= 358.0, "B1 aftermath is wider than the 390px phone viewport")
	assert(page.get_combined_minimum_size().y <= 810.0, "B1 aftermath is taller than the 844px phone viewport")
	var pyramid: VBoxContainer = board.find_child("ResultPyramid", true, false) as VBoxContainer
	assert(pyramid != null, "B1 aftermath did not create its result pyramid")
	assert(pyramid.find_children("Layer*", "HBoxContainer", true, false).size() == 4, "Result pyramid must have exactly four layers")
	var share: Button = board.find_child("ShareButton", true, false) as Button
	var menu: Button = board.find_child("MenuButton", true, false) as Button
	assert(share != null and share.text == SaveManager.text("share_result") and share.icon != null, "Share action is missing its label or icon")
	assert(menu != null and menu.text == SaveManager.text("menu") and menu.icon != null, "Menu action is missing its label or house icon")
