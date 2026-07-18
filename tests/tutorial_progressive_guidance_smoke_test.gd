extends Node

const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")

func _ready() -> void:
	get_tree().root.size = Vector2i(390, 844)
	_assert(GameState.start_tutorial(), "tutorial starts")
	var board: GameBoard = GAME_BOARD_SCENE.instantiate() as GameBoard
	get_tree().root.add_child.call_deferred(board)
	await get_tree().process_frame
	board.refresh()
	await get_tree().process_frame

	var intro: Control = board.get("_tutorial_intro_layer") as Control
	_assert(intro != null and intro.visible, "tutorial opens with an introduction")
	_assert(bool(board.get("_tutorial_paused")), "board waits for the player on the introduction")
	var start_button: Button = intro.find_child("TutorialStart", true, false) as Button
	_assert(start_button != null, "introduction has an explicit start button")
	start_button.pressed.emit()
	await get_tree().create_timer(0.25).timeout

	_assert(int(board.get("_tutorial_stage")) == 0, "first guided group starts after the introduction")
	_assert(GameState.tutorial_allowed_words.size() == 2, "first step only enables the two-word answer")
	_assert((board.get("_tutorial_focus_words") as Array).size() == 2, "first answer is fully highlighted")
	_solve_allowed_row(board, 2)
	await get_tree().create_timer(1.55).timeout

	_assert(int(board.get("_tutorial_stage")) == 1, "mistakes are explained after the first success")
	_assert((board.get("_lives_row") as HBoxContainer).visible, "attempt markers are shown during the explanation")
	var mistake_feature: Control = board.get("_tutorial_feature_layer") as Control
	var mistake_continue: Button = mistake_feature.find_child("TutorialMistakesContinue", true, false) as Button if mistake_feature != null else null
	_assert(mistake_continue != null and not mistake_continue.disabled, "mistake markers move to an interactive centre card")
	mistake_continue.pressed.emit()
	await get_tree().create_timer(0.85).timeout
	_assert(int(board.get("_tutorial_stage")) == 2, "hint step follows the mistake explanation")
	var hint_feature_layer: Control = board.get("_tutorial_feature_layer") as Control
	var hint_feature: Button = hint_feature_layer.find_child("TutorialHintFeature", true, false) as Button if hint_feature_layer != null else null
	_assert(hint_feature != null and not hint_feature.disabled, "hint moves to the centre as an interactive action")

	hint_feature.pressed.emit()
	await get_tree().create_timer(2.10).timeout
	_assert(int(board.get("_tutorial_stage")) == 3, "hint acknowledgement leads to the hinted row")
	_assert(GameState.tutorial_allowed_words.size() == 4, "only the four remaining sea-animal words are enabled")
	_solve_allowed_row(board, 5)
	await get_tree().create_timer(1.55).timeout

	_assert(int(board.get("_tutorial_stage")) == 4, "top word is taught before the final groups")
	_assert(GameState.tutorial_allowed_words == GameState.tutorial_group_words(1), "top word is the only enabled answer")
	_solve_allowed_row(board, 1)
	await get_tree().create_timer(1.55).timeout

	_assert(int(board.get("_tutorial_stage")) == 5, "independent practice follows the top word")
	var independent_continue: Button = board.get("_tutorial_guide_button") as Button
	_assert(bool(board.get("_tutorial_independent_intro_pending")), "independent task waits for acknowledgement")
	_assert(independent_continue.visible, "independent task has a Continue action")
	_assert(GameState.tutorial_allowed_words.is_empty(), "words stay locked until the player continues")
	independent_continue.pressed.emit()
	await get_tree().process_frame
	_assert(GameState.tutorial_allowed_words.size() == 7, "all remaining words are interactive")
	_assert((board.get("_tutorial_focus_words") as Array).is_empty(), "independent task starts without answer highlights")
	_assert(not (board.get("_tutorial_spotlight") as ColorRect).visible, "independent task has no screen shading")
	for wrong_word: String in ["COW", "EAGLE", "OWL"]:
		GameState.toggle_word(wrong_word)
	_assert(GameState.can_check_selection(), "an independent wrong group can be checked")
	GameState.check_selection()
	await get_tree().create_timer(0.75).timeout
	_assert((board.get("_tutorial_focus_words") as Array).size() == 1, "help appears only after a wrong answer")
	_assert(not (board.get("_tutorial_spotlight") as ColorRect).visible, "wrong-answer help still leaves the full board undimmed")
	GameState.clear_selection()
	_solve_row(board, 3)
	await get_tree().create_timer(1.55).timeout

	_assert(int(board.get("_tutorial_stage")) == 6, "final group begins with an acknowledgement")
	_assert(bool(board.get("_tutorial_independent_intro_pending")), "final task waits for Continue")
	independent_continue.pressed.emit()
	await get_tree().process_frame
	_assert((board.get("_tutorial_focus_words") as Array).is_empty(), "final task starts independently")
	_assert(not (board.get("_tutorial_spotlight") as ColorRect).visible, "final task keeps every word fully visible")
	_solve_row(board, 4)
	await get_tree().process_frame
	_assert(GameState.is_finished, "tutorial completes after every row")
	_assert(bool(board.get("_tutorial_finishing")), "completion waits while the finished pyramid remains visible")

	print("TUTORIAL_PROGRESSIVE_GUIDANCE_SMOKE_TEST_PASS")
	board.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _solve_allowed_row(board: GameBoard, row_length: int) -> void:
	var selectable: Array[String] = []
	for word: String in GameState.tutorial_group_words(row_length):
		if GameState.tutorial_allowed_words.has(word) and not GameState.is_word_solved(word):
			selectable.append(word)
	for index: int in selectable.size():
		GameState.toggle_word(selectable[index])
		if index < selectable.size() - 1:
			_assert((board.get("_message") as Label).text != SaveManager.text("tutorial_press_check"), "row %d does not request Check before its final word" % row_length)
	_assert((board.get("_message") as Label).text == SaveManager.text("tutorial_press_check"), "row %d requests Check only when complete" % row_length)
	_assert(GameState.can_check_selection(), "row %d can be checked" % row_length)
	GameState.check_selection()

func _solve_row(board: GameBoard, row_length: int) -> void:
	var selectable: Array[String] = []
	for word: String in GameState.tutorial_group_words(row_length):
		if not GameState.is_word_solved(word):
			selectable.append(word)
	for index: int in selectable.size():
		GameState.toggle_word(selectable[index])
		if index < selectable.size() - 1:
			_assert((board.get("_message") as Label).text != SaveManager.text("tutorial_press_check"), "row %d waits for every required word" % row_length)
	_assert(GameState.can_check_selection(), "row %d can be checked" % row_length)
	GameState.check_selection()

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Progressive tutorial smoke test failed: %s" % description)
	get_tree().quit(1)
