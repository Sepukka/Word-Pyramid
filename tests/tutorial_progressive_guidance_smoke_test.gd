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
	var guide_banner: PanelContainer = board.get("_tutorial_guide_banner") as PanelContainer
	var tutorial_spotlight: ColorRect = board.get("_tutorial_spotlight") as ColorRect
	_assert(tutorial_spotlight.visible and guide_banner.z_index > tutorial_spotlight.z_index, "the full instruction banner stays above tutorial dimming")
	_assert(GameState.tutorial_allowed_words.size() == 2, "first step only enables the two-word answer")
	_assert((board.get("_tutorial_focus_words") as Array).size() == 2, "first answer is fully highlighted")
	var first_words: Array[String] = GameState.tutorial_group_words(2)
	GameState.toggle_word(first_words[0])
	_assert((board.get("_check") as Button).disabled, "first step keeps Check locked after only one selected word")
	board.call("_on_check_pressed")
	_assert(GameState.solved_groups.is_empty(), "first step cannot be checked with only one selected word")
	GameState.clear_selection()
	_solve_allowed_row(board, 2)
	await get_tree().create_timer(1.55).timeout

	_assert(int(board.get("_tutorial_stage")) == 1, "mistake explanation waits for the player")
	_assert((board.get("_lives_row") as HBoxContainer).visible, "attempt markers are shown during the explanation")
	var mistakes_feature_layer: Control = board.get("_tutorial_feature_layer") as Control
	var mistakes_continue: Button = mistakes_feature_layer.find_child("TutorialMistakesContinue", true, false) as Button if mistakes_feature_layer != null else null
	_assert(mistakes_continue != null and not mistakes_continue.disabled, "mistake explanation has an explicit Continue action")
	mistakes_continue.pressed.emit()
	await get_tree().create_timer(0.85).timeout
	_assert(int(board.get("_tutorial_stage")) == 2, "hint step follows the mistake explanation")
	var hint_feature_layer: Control = board.get("_tutorial_feature_layer") as Control
	var hint_card: PanelContainer = hint_feature_layer.find_child("TutorialHintCard", true, false) as PanelContainer if hint_feature_layer != null else null
	var hint_feature: Button = hint_feature_layer.find_child("TutorialHintFeature", true, false) as Button if hint_feature_layer != null else null
	var hint_title: Label = hint_feature_layer.find_child("TutorialHintTitle", true, false) as Label if hint_feature_layer != null else null
	_assert(hint_card != null and hint_card.size.is_equal_approx(Vector2(304, 210)), "hint uses the same presentation card size as mistakes")
	_assert(hint_title != null and hint_title.text == SaveManager.text("tutorial_hint_title"), "hint card clearly asks the player to use a hint")
	_assert(hint_card.scale.is_equal_approx(Vector2.ONE), "hint presentation keeps its normal size instead of scaling")
	_assert(hint_feature != null and not hint_feature.disabled, "hint moves to the centre as an interactive action")

	hint_feature.pressed.emit()
	await get_tree().create_timer(2.10).timeout
	_assert(int(board.get("_tutorial_stage")) == 3, "hint acknowledgement leads to the hinted row")
	_assert(GameState.tutorial_allowed_words.size() == 4, "only the four remaining sea-animal words are enabled")
	var hint_row_words: Array = board.get("_tutorial_target_words") as Array
	GameState.toggle_word(str(hint_row_words[0]))
	_assert((board.get("_check") as Button).disabled, "hinted row keeps Check locked until all four remaining words are selected")
	board.call("_on_check_pressed")
	_assert(int(board.get("_tutorial_stage")) == 3, "an incomplete hinted row cannot be checked")
	GameState.clear_selection()
	_solve_allowed_row(board, 5)
	await get_tree().create_timer(1.55).timeout

	_assert(int(board.get("_tutorial_stage")) == 4, "top word is taught before the final groups")
	_assert(GameState.tutorial_allowed_words == GameState.tutorial_group_words(1), "top word is the only enabled answer")
	_solve_allowed_row(board, 1)
	await get_tree().create_timer(1.55).timeout

	_assert(int(board.get("_tutorial_stage")) == 5, "independent practice follows the top word")
	var independent_continue: Button = board.get("_tutorial_guide_button") as Button
	_assert(not bool(board.get("_tutorial_independent_intro_pending")), "open practice begins without an acknowledgement")
	_assert(not independent_continue.visible, "open practice never shows a Continue action")
	_assert(GameState.tutorial_allowed_words.size() == 7, "all remaining words are interactive")
	_assert((board.get("_message") as Label).text == SaveManager.text("tutorial_open_order"), "open practice explains that either remaining row can be solved first")
	_assert((board.get("_tutorial_focus_words") as Array).is_empty(), "independent task starts without answer highlights")
	_assert(not (board.get("_tutorial_spotlight") as ColorRect).visible, "independent task has no screen shading")
	_assert(not (board.get("_hint") as Button).disabled, "the player may use a hint independently in the final rows")
	var open_three: Array[String] = GameState.tutorial_group_words(3)
	var open_four: Array[String] = GameState.tutorial_group_words(4)
	var attempts_before_short_guess: int = GameState.attempts_left
	GameState.toggle_word(open_three[0])
	GameState.toggle_word(open_three[1])
	_assert((board.get("_check") as Button).disabled, "two farm animals cannot be checked after the two-word row is solved")
	board.call("_on_check_pressed")
	_assert(GameState.attempts_left == attempts_before_short_guess, "an incomplete three-word group cannot consume an attempt")
	GameState.clear_selection()
	for wrong_word: String in [open_three[0], open_three[1], open_four[0], open_four[1]]:
		GameState.toggle_word(wrong_word)
	_assert(GameState.can_check_selection(), "an independent wrong group can be checked")
	board.call("_on_check_pressed")
	await get_tree().create_timer(1.55).timeout
	_assert(not bool(board.get("_tutorial_forced_hint_pending")), "one mistake does not reveal the answer or interrupt open practice")
	GameState.clear_selection()
	for wrong_word: String in [open_three[0], open_three[2], open_four[0], open_four[2]]:
		GameState.toggle_word(wrong_word)
	_assert(GameState.can_check_selection(), "a second distinct wrong group can be checked")
	board.call("_on_check_pressed")
	await get_tree().create_timer(2.00).timeout
	_assert(bool(board.get("_tutorial_forced_hint_pending")), "two mistakes force the player into the hint lesson")
	_assert(GameState.tutorial_allowed_words.is_empty(), "word selection stays locked until the forced hint is used")
	var forced_hint_layer: Control = board.get("_tutorial_feature_layer") as Control
	var forced_hint: Button = forced_hint_layer.find_child("TutorialHintFeature", true, false) as Button if forced_hint_layer != null else null
	_assert(forced_hint != null and not forced_hint.disabled, "the forced hint moves into the same highlighted centre action")
	forced_hint.pressed.emit()
	await get_tree().create_timer(2.30).timeout
	_assert(not bool(board.get("_tutorial_forced_hint_pending")), "using the forced hint returns control to open practice")
	_assert(not GameState.tutorial_allowed_words.is_empty(), "remaining words unlock after the forced hint")

	# Solve the four-word row first to prove that the former 3-then-4 order is gone.
	_solve_row(board, 4)
	await get_tree().create_timer(1.55).timeout

	_assert(int(board.get("_tutorial_stage")) == 6, "final group begins immediately after the independent group")
	_assert(not bool(board.get("_tutorial_independent_intro_pending")), "final task does not require another Continue acknowledgement")
	_assert(not independent_continue.visible, "Continue stays hidden for the final group")
	_assert(GameState.tutorial_allowed_words.size() == 3, "every remaining three-word group tile is immediately selectable")
	_assert(not (board.get("_hint") as Button).disabled, "the optional hint remains available for the last row")
	_assert((board.get("_tutorial_focus_words") as Array).size() == 3, "all remaining final-group tiles are highlighted")
	_assert((board.get("_message") as Label).text == SaveManager.text("tutorial_one_group_left") % 3, "text updates only after a correct row and identifies the remaining group")
	_assert(not (board.get("_tutorial_spotlight") as ColorRect).visible, "final task keeps every word fully visible")
	_solve_row(board, 3)
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
