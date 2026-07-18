extends Node

const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")

func _ready() -> void:
	SaveManager.save_path = "res://.godot-test-data/aftermath_save.json"
	get_tree().root.size = Vector2i(390, 844)
	var original_language: String = str(SaveManager.settings.get("language", "en"))
	assert(PuzzleLoader.set_language("en"), "Aftermath smoke test could not load English puzzles")
	var puzzles: Array[Dictionary] = PuzzleLoader.get_puzzles(GameState.DAILY_MODE)
	assert(not puzzles.is_empty(), "Aftermath smoke test needs a daily puzzle")
	GameState.puzzle = puzzles[0].duplicate(true)
	GameState.daily_date = ""
	GameState.game_mode = GameState.DAILY_MODE
	GameState.selected_words.clear()
	GameState.solved_groups = [0, 1, 2, 3]
	# Exact regression case: the two-word row and the bottom five-word row were
	# solved, so the score and compact result picture must both show two groups.
	GameState.result_solved_groups = [0, 3]
	GameState.result_top_solved = false
	GameState.is_top_solved = true
	GameState.is_finished = true
	GameState.completed_won = false
	GameState.is_auto_solving = false
	GameState.attempts_left = 0
	GameState.hints_used = 1
	GameState.result_correct_count = 7
	GameState.result_progression = {
		"xp_gained": 42,
		"total_xp_before": 90,
		"total_xp_after": 132,
		"level_before": 1,
		"level_after": 2,
	}
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
	var animated_xp: Label = board.find_child("XpRewardLabel", true, false) as Label
	var animated_progress: ProgressBar = board.find_child("XpProgress", true, false) as ProgressBar
	var initial_progress: float = animated_progress.value
	await get_tree().create_timer(0.78).timeout
	assert(animated_progress.value != initial_progress, "XP progress must move live after the aftermath opens")
	assert(animated_xp.text.contains(" / +42 XP"), "XP label must count toward the full reward during the animation")
	await get_tree().create_timer(1.05).timeout
	assert(animated_xp.text.contains("+42 XP"), "XP animation must finish at the full earned reward")
	var final_level_progress: Dictionary = SaveManager.get_level_progress(132)
	assert(is_equal_approx(animated_progress.value, float(final_level_progress.get("current", -1))), "XP animation must finish at the saved level progress")
	var daily_primary: Button = board.find_child("PrimaryAction", true, false) as Button
	assert(daily_primary != null and daily_primary.text == SaveManager.text("continue_to_unlimited"), "Daily aftermath has the wrong continuation label")
	var daily_flame: TextureRect = board.find_child("StreakFlame", true, false) as TextureRect
	assert(daily_flame != null and daily_flame.visible, "Daily aftermath must show the streak flame")

	await board.call("_dismiss_aftermath")
	await get_tree().process_frame
	GameState.game_mode = GameState.UNLIMITED_MODE
	GameState.completed_won = true
	GameState.result_solved_groups = [0, 1, 2, 3]
	GameState.result_top_solved = true
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
	var all_unlimited_ids: Array[String] = []
	for unlimited_puzzle: Dictionary in PuzzleLoader.get_puzzles(GameState.UNLIMITED_MODE):
		all_unlimited_ids.append(str(unlimited_puzzle.get("id", "")))
	SaveManager.replace_played_puzzle_ids("%s:%s" % [PuzzleLoader.get_language(), GameState.UNLIMITED_MODE], all_unlimited_ids)
	board.call("_show_aftermath", true)
	await get_tree().process_frame
	await get_tree().process_frame
	var completion_panel: PanelContainer = board.find_child("UnlimitedPoolCompletePanel", true, false) as PanelContainer
	assert(completion_panel != null, "The last Infinity puzzle must show a clear pool-completed panel")
	var completion_primary: Button = board.find_child("PrimaryAction", true, false) as Button
	assert(completion_primary != null and completion_primary.text == SaveManager.text("back_to_home"), "The completed Infinity pool must return the player home")
	var completion_page: VBoxContainer = board.find_child("AftermathPage", true, false) as VBoxContainer
	assert(completion_page.get_combined_minimum_size().y <= 810.0, "Infinity completion must still fit the phone viewport")

	await board.call("_dismiss_aftermath")
	await get_tree().process_frame
	SaveManager.replace_played_puzzle_ids("%s:%s" % [PuzzleLoader.get_language(), GameState.UNLIMITED_MODE], [])
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
	var score: Label = board.find_child("SolvedGroupScore", true, false) as Label
	var expected_rows: int = GameState.result_solved_groups.size() + (1 if GameState.result_top_solved else 0)
	assert(score != null and score.text.begins_with("%d / 5" % expected_rows), "Aftermath row score must include the top-word result")
	var xp_reward: Label = board.find_child("XpRewardLabel", true, false) as Label
	var xp_progress: ProgressBar = board.find_child("XpProgress", true, false) as ProgressBar
	assert(xp_reward != null and xp_reward.text.contains("XP"), "Aftermath must show the live XP reward")
	assert(xp_progress != null and xp_progress.max_value > 0.0, "Aftermath must show progress toward the next level")
	var found_mark: Label = board.find_child("LegendFoundIconMark", true, false) as Label
	var missed_mark: Label = board.find_child("LegendMissedIconMark", true, false) as Label
	assert(found_mark != null and found_mark.text == "✓", "Found legend must use a check mark inside its green square")
	assert(missed_mark != null and missed_mark.text == "×", "Missed legend must use an x mark inside its red square")
	var layers: Array[Node] = pyramid.find_children("Layer*", "HBoxContainer", true, false)
	assert(layers.size() == 5, "Result pyramid must mirror all five game-board layers")
	var total_blocks: int = 0
	for layer_index: int in layers.size():
		var result_row: HBoxContainer = layers[layer_index] as HBoxContainer
		var row_length: int = int(result_row.get_meta("row_length", 0))
		assert(row_length == layer_index + 1, "Result pyramid layer %d must represent the matching game row" % (layer_index + 1))
		assert(result_row.get_child_count() == row_length, "Result pyramid row %d must retain its %d word blocks" % [row_length, row_length])
		total_blocks += result_row.get_child_count()
		var expected_found: bool = GameState.result_top_solved if row_length == 1 else board.call("_aftermath_group_found_for_size", row_length)
		for tile_index: int in result_row.get_child_count():
			var tile: PanelContainer = result_row.get_child(tile_index) as PanelContainer
			var mark: Label = tile.get_child(0) as Label
			assert(mark.text == ("✓" if expected_found else "×"), "Result pyramid must match the rows solved in the game")
	assert(total_blocks == 15, "Result pyramid must contain the same 15 blocks as the game board")
	if GameState.game_mode == GameState.UNLIMITED_MODE:
		var hearts: HBoxContainer = board.find_child("AftermathHearts", true, false) as HBoxContainer
		assert(hearts != null, "Infinity aftermath is missing its heart row")
		assert(hearts.get_child_count() == SaveManager.ENDLESS_DAILY_HEARTS, "Infinity aftermath must show every daily heart")
		for index: int in hearts.get_child_count():
			var heart: TextureRect = hearts.get_child(index) as TextureRect
			assert(heart != null and heart.texture != null, "Aftermath hearts must use the outlined heart artwork, not font glyphs")
			assert(heart.custom_minimum_size == Vector2(26, 24), "Aftermath heart sizing must match the home menu heart sizing")
	var share: Button = board.find_child("ShareButton", true, false) as Button
	var menu: Button = board.find_child("MenuButton", true, false) as Button
	assert(share != null and share.text == SaveManager.text("share_result") and share.icon != null, "Share action is missing its label or icon")
	assert(menu != null and menu.text == SaveManager.text("menu") and menu.icon != null, "Menu action is missing its label or house icon")
