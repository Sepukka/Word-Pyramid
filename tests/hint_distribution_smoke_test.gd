extends Node

const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")

func _ready() -> void:
	SaveManager.reset_all_data()
	_assert(GameState.start_tutorial(), "tutorial puzzle starts")

	GameState.request_hint()
	_assert(GameState.get_hint_words_for_row(5).size() == 1, "first hint goes to the bottom row")
	_assert(GameState.get_hint_words_for_row(4).is_empty(), "first hint does not spill into the second-bottom row")

	GameState.request_hint()
	_assert(GameState.get_hint_words_for_row(5).size() == 1, "second hint does not repeat the bottom row")
	_assert(GameState.get_hint_words_for_row(4).size() == 1, "second hint goes to the second-bottom row")

	_assert_locked_hint_style(5)
	_assert_locked_hint_style(4)
	_assert_non_completing_repeat_is_preferred()

	print("HINT_DISTRIBUTION_SMOKE_TEST_PASS")
	get_tree().quit()

func _assert_locked_hint_style(row_length: int) -> void:
	var board: GameBoard = GAME_BOARD_SCENE.instantiate() as GameBoard
	board.call("_setup_font_variations")
	var word: String = GameState.get_hint_words_for_row(row_length)[0]
	var tile: Button = board.call("_create_hinted_tile", word, row_length) as Button
	var style: StyleBoxFlat = tile.get_theme_stylebox("disabled") as StyleBoxFlat
	_assert(style != null, "hinted row %d has a disabled style" % row_length)
	_assert(style.bg_color != Color.WHITE, "hinted row %d keeps its row color after rebuilding" % row_length)
	tile.free()
	board.free()

func _assert_non_completing_repeat_is_preferred() -> void:
	# Every row already has a hint. The bottom row is one hint away from being
	# completed, so the allocator must choose the next safe row instead.
	GameState.hinted_words_by_row.clear()
	GameState.hinted_words_by_row[5] = GameState.tutorial_group_words(5).slice(0, 4)
	GameState.hinted_words_by_row[4] = GameState.tutorial_group_words(4).slice(0, 1)
	GameState.hinted_words_by_row[3] = GameState.tutorial_group_words(3).slice(0, 1)
	GameState.hinted_words_by_row[2] = GameState.tutorial_group_words(2).slice(0, 1)
	var target: Dictionary = GameState.call("_find_next_hint_target")
	_assert(int(target.get("row_length", 0)) == 4, "repeated hints avoid completing a row when a safe row remains")

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Hint distribution smoke test failed: %s" % description)
	get_tree().quit(1)
