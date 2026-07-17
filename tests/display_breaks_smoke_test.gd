extends Node

const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")

func _ready() -> void:
	SaveManager.reset_all_data()
	_assert(PuzzleLoader.set_language("fi"), "Finnish puzzles load")
	var finnish_puzzle: Dictionary = _find_puzzle("daily", "fi_daily_003")
	_assert(not finnish_puzzle.is_empty(), "Finnish display-break puzzle exists")
	_assert(PuzzleLoader.validate_puzzle(finnish_puzzle).is_empty(), "Finnish display breaks validate")
	GameState.puzzle = finnish_puzzle
	var board: GameBoard = GAME_BOARD_SCENE.instantiate()
	_assert(board._display_word("KAUNOKIRJALLISUUS") == "KAUNO\nKIRJALLISUUS", "curated break is used only for display")
	_assert(board._display_word("HISTORIA") == "HISTORIA", "words without overrides remain unchanged")
	board.free()
	_assert(PuzzleLoader.set_language("en"), "English puzzles load")
	var english_puzzle: Dictionary = _find_puzzle("daily", "daily_004")
	_assert(not english_puzzle.is_empty(), "English display-break puzzle exists")
	_assert(PuzzleLoader.validate_puzzle(english_puzzle).is_empty(), "English display breaks validate")
	print("DISPLAY_BREAKS_SMOKE_TEST_PASS")
	get_tree().quit()

func _find_puzzle(mode: String, puzzle_id: String) -> Dictionary:
	for puzzle: Dictionary in PuzzleLoader.get_puzzles(mode):
		if str(puzzle.get("id", "")) == puzzle_id:
			return puzzle
	return {}

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Display-break smoke test failed: %s" % description)
	get_tree().quit(1)
