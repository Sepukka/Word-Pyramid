extends Node

const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")

var _board: GameBoard
var _expected_tile_size: Vector2
var _expected_font_size: int
var _layout_checks: int = 0

func _ready() -> void:
	SaveManager.save_path = "res://.godot-test-data/auto_solve_save.json"
	SaveManager.progression = SaveManager.DEFAULT_PROGRESSION.duplicate(true)
	get_tree().root.size = Vector2i(390, 844)
	var puzzles: Array[Dictionary] = PuzzleLoader.get_puzzles(GameState.DAILY_MODE)
	assert(not puzzles.is_empty(), "Auto-solve layout test needs a puzzle")
	GameState.puzzle = puzzles[0].duplicate(true)
	GameState.daily_date = ""
	GameState.game_mode = GameState.DAILY_MODE
	GameState.selected_words.clear()
	GameState.solved_groups.clear()
	GameState.result_solved_groups.clear()
	GameState.result_top_solved = false
	GameState.is_top_solved = false
	GameState.is_finished = false
	GameState.completed_won = false
	GameState.is_auto_solving = false
	GameState.last_chance_used = true
	GameState.attempts_left = 1
	GameState.hints_used = 0

	_board = GAME_BOARD_SCENE.instantiate() as GameBoard
	get_tree().root.add_child.call_deferred(_board)
	await get_tree().process_frame
	await get_tree().process_frame
	_board.refresh()
	await get_tree().process_frame
	await get_tree().process_frame
	var buttons: Dictionary = _board.get("_word_buttons")
	assert(not buttons.is_empty(), "Board did not create word blocks")
	var sample: Button = buttons.values()[0] as Button
	_expected_tile_size = sample.size
	_expected_font_size = sample.get_theme_font_size("font_size")
	GameState.group_solved.connect(_on_auto_group_solved)

	var groups: Array = GameState.puzzle.get("groups", [])
	var first_group: Dictionary = groups[0]
	var second_group: Dictionary = groups[1]
	GameState.selected_words.assign([
		str((first_group.get("words", []) as Array)[0]),
		str((second_group.get("words", []) as Array)[0]),
	])
	GameState.check_selection()

	var timeout: float = 8.0
	while not GameState.is_finished and timeout > 0.0:
		await get_tree().create_timer(0.1).timeout
		timeout -= 0.1
	assert(GameState.is_finished, "Automatic board completion timed out")
	assert(_layout_checks >= 4, "Every automatically solved group must retain fixed block metrics")
	print("AUTO_SOLVE_LAYOUT_SMOKE_TEST_PASS")
	_board.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _on_auto_group_solved(_group: Dictionary) -> void:
	call_deferred("_verify_fixed_block_metrics")

func _verify_fixed_block_metrics() -> void:
	if not is_instance_valid(_board):
		return
	_layout_checks += 1
	var buttons: Dictionary = _board.get("_word_buttons")
	for tile_value: Variant in buttons.values():
		var tile: Button = tile_value as Button
		assert(tile.size.is_equal_approx(_expected_tile_size), "An unsolved word block changed size during automatic completion")
		assert(tile.get_theme_font_size("font_size") == _expected_font_size, "An unsolved word block changed font size during automatic completion")
	var placed_rows: Dictionary = _board.get("_placed_tiles")
	for row_value: Variant in placed_rows.values():
		for placed_value: Variant in row_value:
			var placed_tile: Button = placed_value as Button
			assert(placed_tile != null, "Every placed word must retain the same Button control type")
			assert(placed_tile.size.is_equal_approx(_expected_tile_size), "A placed word block changed size during automatic completion")
			assert(placed_tile.get_theme_font_size("font_size") == _expected_font_size, "A placed word block changed font size during automatic completion")
	var ghosts: Array[Control] = _board.get("_row_animation_ghosts")
	for ghost: Control in ghosts:
		assert(ghost is Button, "A moving word must retain the same Button control type")
		assert(ghost.size.is_equal_approx(_expected_tile_size), "A moving word block changed size during automatic completion")
		assert(ghost.get_theme_font_size("font_size") == _expected_font_size, "A moving word block changed font size during automatic completion")
