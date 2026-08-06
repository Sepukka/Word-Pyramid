extends Node

const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")

var _board: GameBoard
var _tile_size: Vector2
var _font_size: int

func _ready() -> void:
	SaveManager.save_path = "res://.godot-test-data/row_placement_stability_save.json"
	get_tree().root.size = Vector2i(390, 844)
	var puzzles: Array[Dictionary] = PuzzleLoader.get_puzzles(GameState.DAILY_MODE)
	assert(not puzzles.is_empty(), "Row placement stability test needs a puzzle")
	GameState.puzzle = puzzles[0].duplicate(true)
	GameState.daily_date = ""
	GameState.game_mode = GameState.DAILY_MODE
	GameState.selected_words.clear()
	GameState.solved_groups.clear()
	GameState.is_top_solved = false
	GameState.is_finished = false
	GameState.completed_won = false
	GameState.is_auto_solving = false
	GameState.attempts_left = 4
	GameState.hints_used = 0

	_board = GAME_BOARD_SCENE.instantiate() as GameBoard
	get_tree().root.add_child.call_deferred(_board)
	await get_tree().process_frame
	await get_tree().process_frame
	_board.refresh()
	await get_tree().process_frame
	await get_tree().process_frame

	var initial_buttons: Dictionary = _board.get("_word_buttons")
	var sample: Button = initial_buttons.values()[0] as Button
	_tile_size = sample.size
	_font_size = sample.get_theme_font_size("font_size")
	var board_message: Label = _board.get("_message") as Label
	assert(board_message.text.is_empty() and not board_message.visible, "Normal gameplay starts without a redundant permanent message")
	var gameplay_status_slot: Control = _board.get("_gameplay_status_slot") as Control
	assert(gameplay_status_slot != null and is_equal_approx(gameplay_status_slot.custom_minimum_size.y, GameBoard.GAMEPLAY_STATUS_HEIGHT), "Normal gameplay reserves a fixed feedback slot")
	var pyramid: VBoxContainer = _board.get("_pyramid") as VBoxContainer
	var pyramid_origin: Vector2 = pyramid.global_position
	_board.call("_show_board_message", "A deliberately long hint message that wraps onto another line must not move the pyramid.")
	await get_tree().process_frame
	await get_tree().process_frame
	assert(pyramid.global_position.is_equal_approx(pyramid_origin), "Wrapped hint feedback must not move the gameplay pyramid")
	_board.call("_clear_board_message")
	await get_tree().process_frame
	assert(pyramid.global_position.is_equal_approx(pyramid_origin), "Clearing feedback must not move the gameplay pyramid")

	var three_group: Dictionary = _group_of_size(3)
	var three_words: Array[String] = GameState._to_string_array(three_group.get("words", []))
	var three_row_centers: Array[Vector2] = _row_resting_centers(3)
	var fonts_before: Dictionary = _fonts_for_words(three_words)
	_select_words(three_words)
	await get_tree().create_timer(0.24).timeout
	GameState.check_selection()
	_verify_moving_tiles(three_words, fonts_before)
	assert(board_message.text.is_empty() and not board_message.visible, "A correct row relies on its category reveal instead of redundant text")
	await get_tree().create_timer(0.64).timeout
	_verify_placed_row(3, three_words, fonts_before, three_row_centers)
	await get_tree().create_timer(0.28).timeout
	assert((_board.get("_category_cards") as Dictionary).has(3), "A category card covers a completed multi-word row")

	var top_word: String = str(GameState.puzzle.get("top_word", ""))
	var top_center: Vector2 = _row_resting_centers(1)[0]
	var current_buttons: Dictionary = _board.get("_word_buttons")
	var top_tile: Button = current_buttons.get(top_word) as Button
	assert(top_tile != null, "Top word remains selectable after another row is solved")
	var top_font: Font = top_tile.get_theme_font("font")
	_select_words([top_word])
	await get_tree().create_timer(0.24).timeout
	GameState.check_selection()
	_verify_moving_tiles([top_word], {top_word: top_font})
	await get_tree().create_timer(0.64).timeout
	_verify_placed_row(1, [top_word], {top_word: top_font}, [top_center])
	await get_tree().create_timer(0.30).timeout
	assert(not (_board.get("_category_cards") as Dictionary).has(1), "The top word is never replaced by a category card")

	# Rebuilding the board for another solved row must preserve the completed top
	# as exactly the same word block, size, font, and position.
	var two_group: Dictionary = _group_of_size(2)
	_select_words(GameState._to_string_array(two_group.get("words", [])))
	await get_tree().create_timer(0.24).timeout
	GameState.check_selection()
	await get_tree().process_frame
	_verify_placed_row(1, [top_word], {top_word: top_font}, [top_center])

	print("ROW_PLACEMENT_STABILITY_SMOKE_TEST_PASS")
	_board.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _group_of_size(row_length: int) -> Dictionary:
	for group_value: Variant in GameState.puzzle.get("groups", []):
		var group: Dictionary = group_value
		if int(group.get("size", 0)) == row_length:
			return group
	return {}

func _select_words(words: Array[String]) -> void:
	for word: String in words:
		GameState.toggle_word(word)
	assert(GameState.can_check_selection(), "Selected correct row can be checked")

func _fonts_for_words(words: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	var buttons: Dictionary = _board.get("_word_buttons")
	for word: String in words:
		var tile: Button = buttons.get(word) as Button
		assert(tile != null, "Expected source word exists on the board")
		result[word] = tile.get_theme_font("font")
	return result

func _row_resting_centers(row_length: int) -> Array[Vector2]:
	var centers: Array[Vector2] = []
	var buttons: Dictionary = _board.get("_word_buttons")
	for tile_value: Variant in buttons.values():
		var tile: Button = tile_value as Button
		if int(tile.get_meta("row_length", 0)) == row_length:
			var center: Vector2 = tile.get_global_rect().get_center()
			if bool(tile.get_meta("selection_lifted", false)):
				center.y += GameBoard.SELECTION_LIFT
			centers.append(center)
	centers.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	return centers

func _verify_moving_tiles(words: Array[String], expected_fonts: Dictionary) -> void:
	var ghosts: Array[Control] = _board.get("_row_animation_ghosts")
	var checked: int = 0
	for ghost: Control in ghosts:
		var word: String = str(ghost.get_meta("word", ""))
		if not words.has(word):
			continue
		assert(ghost is Button, "Moving word retains the Button control type")
		assert(ghost.size.is_equal_approx(_tile_size), "Moving word retains its exact block size")
		assert(ghost.get_theme_font_size("font_size") == _font_size, "Moving word retains its exact font size")
		assert(ghost.get_theme_font("font") == expected_fonts.get(word), "Moving word retains its exact font variation")
		checked += 1
	assert(checked == words.size(), "Every selected word has one stable moving block")

func _verify_placed_row(row_length: int, words: Array[String], expected_fonts: Dictionary, expected_centers: Array[Vector2]) -> void:
	var placed_rows: Dictionary = _board.get("_placed_tiles")
	assert(placed_rows.has(row_length), "Completed row remains visible before its category cover")
	var placed: Array = placed_rows[row_length]
	assert(placed.size() == words.size(), "Completed row contains every solved word")
	var actual_centers: Array[Vector2] = []
	for tile_value: Variant in placed:
		var tile: Button = tile_value as Button
		assert(tile != null, "Placed word retains the Button control type")
		var word: String = str(tile.get_meta("word", ""))
		assert(words.has(word), "Placed row contains only its solved words")
		assert(tile.size.is_equal_approx(_tile_size), "Placed word retains its exact block size")
		assert(tile.get_theme_font_size("font_size") == _font_size, "Placed word retains its exact font size")
		assert(tile.get_theme_font("font") == expected_fonts.get(word), "Placed word retains its exact font variation")
		actual_centers.append(tile.get_global_rect().get_center())
	actual_centers.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	assert(actual_centers.size() == expected_centers.size(), "Completed row keeps its slot count")
	for index: int in actual_centers.size():
		assert(actual_centers[index].is_equal_approx(expected_centers[index]), "Placed word lands on the fixed row baseline")
