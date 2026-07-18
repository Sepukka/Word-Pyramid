extends Node

const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")

func _ready() -> void:
	SaveManager.save_path = "res://.godot-test-data/debug_auto_solve_save.json"
	SaveManager.reset_to_defaults()
	var puzzles: Array[Dictionary] = PuzzleLoader.get_puzzles(GameState.DAILY_MODE)
	assert(not puzzles.is_empty(), "Debug auto-solve test needs a puzzle")
	GameState.puzzle = puzzles[0].duplicate(true)
	GameState.daily_date = Time.get_date_string_from_system()
	GameState.game_mode = GameState.DAILY_MODE
	GameState.selected_words.clear()
	GameState.solved_groups.clear()
	GameState.result_solved_groups.clear()
	GameState.result_top_solved = false
	GameState.result_progression.clear()
	GameState.is_top_solved = false
	GameState.is_finished = false
	GameState.completed_won = false
	GameState.is_auto_solving = false
	GameState.is_debug_completion = false
	GameState.attempts_left = int(SaveManager.settings.get("attempts", 4))
	GameState.hints_used = 0

	var statistics_before: Dictionary = SaveManager.statistics.duplicate(true)
	var daily_results_before: Dictionary = SaveManager.daily_results.duplicate(true)
	var played_before: Dictionary = SaveManager.played_puzzle_ids.duplicate(true)
	var endless_before: Dictionary = SaveManager.endless_state.duplicate(true)
	var progression_before: Dictionary = SaveManager.progression.duplicate(true)
	var active_game_before: Dictionary = SaveManager.active_game.duplicate(true)

	var board: GameBoard = GAME_BOARD_SCENE.instantiate() as GameBoard
	get_tree().root.add_child.call_deferred(board)
	await get_tree().process_frame
	await get_tree().process_frame
	board.refresh()
	var debug_button: Button = board.get("_debug_auto_solve") as Button
	assert(is_instance_valid(debug_button) and debug_button.visible, "Gameplay screen must show the debug solve button")
	debug_button.pressed.emit()
	assert(debug_button.disabled or not debug_button.visible, "Debug solve button must lock while solving")
	var timeout: float = 8.0
	while not GameState.is_finished and timeout > 0.0:
		await get_tree().create_timer(0.1).timeout
		timeout -= 0.1

	assert(GameState.is_finished and GameState.completed_won, "Debug solve must finish the visible puzzle")
	assert(GameState.is_debug_completion, "Debug solve must identify its result as non-persistent")
	assert(GameState.result_correct_count == GameState.result_total_count(), "Debug result must show the complete pyramid")
	assert(GameState.result_solved_groups.size() == 4 and GameState.result_top_solved, "Debug result rows must match the solved board")
	assert(GameState.result_progression.is_empty(), "Debug solve must not create an XP reward")
	assert(SaveManager.statistics == statistics_before, "Debug solve changed statistics")
	assert(SaveManager.daily_results == daily_results_before, "Debug solve changed the daily result")
	assert(SaveManager.played_puzzle_ids == played_before, "Debug solve marked the puzzle as played")
	assert(SaveManager.endless_state == endless_before, "Debug solve changed endless hearts")
	assert(SaveManager.progression == progression_before, "Debug solve changed XP or player level")
	assert(SaveManager.active_game == active_game_before, "Debug solve overwrote the resumable game")
	await get_tree().create_timer(2.2).timeout
	assert(SaveManager.daily_results == daily_results_before, "Debug aftermath consumed or changed a daily result")
	print("DEBUG_AUTO_SOLVE_SMOKE_TEST_PASS")
	board.queue_free()
	await get_tree().process_frame
	get_tree().quit()
