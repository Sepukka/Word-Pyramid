class_name GameBoard
extends Control

signal request_menu
signal request_new_game

const ROW_LENGTHS: Array[int] = [1, 2, 3, 4, 5]
const TILE_GAP: float = 10.0
const SELECTED_FILL: Color = Color("ffd081")
const SELECTED_BORDER: Color = Color("d77620")

var _card: PanelContainer
var _message: Label
var _selection: Label
var _mistakes: Label
var _pyramid: VBoxContainer
var _check: Button
var _clear: Button
var _hint: Button
var _word_buttons: Dictionary = {}
var _word_order: Array[String] = []
var _hinted_tiles: Dictionary = {}
var _placed_tiles: Dictionary = {}
var _category_cards: Dictionary = {}
var _pyramid_rows: Dictionary = {}
var _action_buttons: Array[Button] = []
var _animating_row: int = -1
var _is_placing: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	resized.connect(_layout_for_width)
	GameState.game_started.connect(_on_game_started)
	GameState.selection_changed.connect(_on_selection_changed)
	GameState.group_solved.connect(_on_group_solved)
	GameState.top_solved.connect(_on_top_solved)
	GameState.repeated_guess_attempted.connect(_on_repeated_guess_attempted)
	GameState.guess_feedback.connect(_on_guess_feedback)
	GameState.guess_failed.connect(_on_guess_failed)
	GameState.game_finished.connect(_on_game_finished)
	GameState.hint_placed.connect(_on_hint_placed)
	GameState.hint_provided.connect(_on_hint_provided)
	GameState.hint_count_changed.connect(_on_hint_count_changed)
	GameState.rewarded_hint_required.connect(_on_rewarded_hint_required)
	AdManager.rewarded_hint_earned.connect(GameState.grant_rewarded_hint)
	AdManager.rewarded_ad_unavailable.connect(_on_rewarded_ad_unavailable)
	GameState.puzzle_pool_completed.connect(_on_puzzle_pool_completed)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		GameState.check_selection()
		get_viewport().set_input_as_handled()

func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color("f2f3f2")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	add_child(center)
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", _card_style())
	center.add_child(_card)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 26)
	_card.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	var top: HBoxContainer = HBoxContainer.new()
	content.add_child(top)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var instructions: Button = Button.new()
	instructions.text = "ⓘ  Ohjeet"
	instructions.flat = true
	instructions.add_theme_font_size_override("font_size", 13)
	instructions.add_theme_color_override("font_color", Color("606765"))
	instructions.pressed.connect(_show_instructions)
	top.add_child(instructions)
	var title: Label = Label.new()
	title.text = "Valitse yhteen kuuluvat sanat"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("25282a"))
	content.add_child(title)
	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_color_override("font_color", Color("73787a"))
	content.add_child(_message)
	_selection = Label.new()
	_selection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection.add_theme_color_override("font_color", Color("48504d"))
	_selection.add_theme_font_size_override("font_size", 14)
	content.add_child(_selection)
	_pyramid = VBoxContainer.new()
	_pyramid.alignment = BoxContainer.ALIGNMENT_CENTER
	_pyramid.add_theme_constant_override("separation", TILE_GAP)
	content.add_child(_pyramid)
	_mistakes = Label.new()
	_mistakes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mistakes.add_theme_font_size_override("font_size", 15)
	_mistakes.add_theme_color_override("font_color", Color("555a5c"))
	content.add_child(_mistakes)
	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 10)
	content.add_child(action_row)
	_hint = _action_button("Vihje 2")
	_hint.pressed.connect(_on_hint_pressed)
	action_row.add_child(_hint)
	_clear = _action_button("Tyhjennä")
	_clear.pressed.connect(GameState.clear_selection)
	action_row.add_child(_clear)
	_check = _action_button("Tarkista", true)
	_check.pressed.connect(GameState.check_selection)
	action_row.add_child(_check)
	_action_buttons = [_hint, _clear, _check]
	var game_actions: HBoxContainer = HBoxContainer.new()
	game_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	game_actions.add_theme_constant_override("separation", 10)
	content.add_child(game_actions)
	var new_game: Button = Button.new()
	new_game.text = "Uusi peli"
	new_game.flat = true
	new_game.add_theme_color_override("font_color", Color("606765"))
	new_game.pressed.connect(func() -> void: request_new_game.emit())
	game_actions.add_child(new_game)
	var second_divider: Label = Label.new()
	second_divider.text = "·"
	game_actions.add_child(second_divider)
	var menu: Button = Button.new()
	menu.text = "Valikko"
	menu.flat = true
	menu.add_theme_color_override("font_color", Color("606765"))
	menu.pressed.connect(func() -> void: request_menu.emit())
	game_actions.add_child(menu)

func refresh() -> void:
	if not is_node_ready():
		return
	_message.text = "Päivän haaste · etsi samaan ryhmään kuuluvat sanat."
	_build_pyramid()
	_update_mistakes()
	_update_selection(GameState.selected_words)

func _build_pyramid() -> void:
	for child: Node in _pyramid.get_children():
		child.queue_free()
	_word_buttons.clear()
	_hinted_tiles.clear()
	_placed_tiles.clear()
	_category_cards.clear()
	_pyramid_rows.clear()
	var remaining_words: Array[String] = _get_stable_word_order()
	# Rows are built from the top down, whereas the first hint belongs in the
	# bottom row. Reserve every hinted word so an earlier row cannot consume it
	# before its correct row is created.
	var reserved_hint_words: Array[String] = []
	for hinted_row_length: int in ROW_LENGTHS:
		var reserved_word: String = GameState.get_hint_word_for_row(hinted_row_length)
		if not reserved_word.is_empty() and remaining_words.has(reserved_word):
			reserved_hint_words.append(reserved_word)
	for row_length: int in ROW_LENGTHS:
		var row: HBoxContainer = HBoxContainer.new()
		row.set_meta("row_length", row_length)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", TILE_GAP)
		_pyramid.add_child(row)
		_pyramid_rows[row_length] = row
		var solved_group: Dictionary = _solved_group_for_row(row_length)
		if not solved_group.is_empty():
			if row_length == _animating_row:
				var placed_row: Array[Label] = []
				var locked_hint_word: String = GameState.get_hint_word_for_row(row_length)
				for solved_word: String in GameState._to_string_array(solved_group.get("words", [])):
					var placed_tile: Label = _create_placed_tile(solved_word, row_length)
					# The hint was already locked in this row, so keep it visible
					# while the remaining blocks finish their placement animation.
					placed_tile.modulate.a = 1.0 if solved_word == locked_hint_word else 0.0
					row.add_child(placed_tile)
					placed_row.append(placed_tile)
				_placed_tiles[row_length] = placed_row
			else:
				var category_card: PanelContainer = _create_category_card(solved_group)
				row.add_child(category_card)
				_category_cards[row_length] = category_card
			continue
		var hinted_word: String = GameState.get_hint_word_for_row(row_length)
		if not hinted_word.is_empty() and remaining_words.has(hinted_word):
			var hinted_tile: Button = _create_hinted_tile(hinted_word, row_length)
			row.add_child(hinted_tile)
			_hinted_tiles[hinted_word] = hinted_tile
			remaining_words.erase(hinted_word)
			reserved_hint_words.erase(hinted_word)
		var slots_left: int = row_length - row.get_child_count()
		for _tile_index: int in slots_left:
			var next_word_index: int = -1
			for candidate_index: int in remaining_words.size():
				if not reserved_hint_words.has(remaining_words[candidate_index]):
					next_word_index = candidate_index
					break
			if next_word_index < 0:
				break
			var word: String = remaining_words.pop_at(next_word_index)
			var tile: Button = _create_word_tile(word)
			row.add_child(tile)
			_word_buttons[word] = tile
	_layout_for_width()
	_on_selection_changed(GameState.selected_words)

func _create_word_tile(word: String) -> Button:
	var tile: Button = Button.new()
	tile.text = word
	tile.toggle_mode = true
	tile.autowrap_mode = TextServer.AUTOWRAP_OFF
	tile.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tile.alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.tooltip_text = "Valitse %s" % word
	tile.add_theme_stylebox_override("normal", _tile_style(Color("e6e8e7"), Color("d8dcda")))
	tile.add_theme_stylebox_override("hover", _tile_style(Color("d8dcda"), Color("9ba6a0")))
	tile.add_theme_stylebox_override("pressed", _tile_style(Color("bccdc5"), Color("62756b")))
	tile.add_theme_color_override("font_color", Color("292d2e"))
	tile.add_theme_font_size_override("font_size", 13)
	tile.pressed.connect(func() -> void: GameState.toggle_word(word))
	return tile

func _create_hinted_tile(word: String, row_length: int) -> Button:
	var tile: Button = Button.new()
	tile.text = word
	tile.disabled = true
	tile.autowrap_mode = TextServer.AUTOWRAP_OFF
	tile.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tile.alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_theme_font_size_override("font_size", 13)
	tile.add_theme_color_override("font_disabled_color", _row_text(row_length))
	tile.add_theme_stylebox_override("disabled", _tile_style(_row_fill(row_length), _row_border(row_length)))
	tile.tooltip_text = "Vihje: lukittu oikealle riville"
	return tile

func _create_placed_tile(word: String, row_length: int) -> Label:
	var tile: Label = Label.new()
	tile.text = word
	tile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tile.autowrap_mode = TextServer.AUTOWRAP_OFF
	tile.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tile.add_theme_font_size_override("font_size", 13)
	tile.add_theme_color_override("font_color", _row_text(row_length))
	tile.add_theme_stylebox_override("normal", _tile_style(_row_fill(row_length), _row_border(row_length)))
	return tile

func _create_category_card(group: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	var row_length: int = int(group.get("size", 1))
	card.add_theme_stylebox_override("panel", _category_card_style(row_length))
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 3)
	margin.add_child(content)
	if int(group.get("size", 0)) != 1:
		var category: Label = Label.new()
		category.text = str(group.get("label", ""))
		category.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		category.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		category.add_theme_font_size_override("font_size", 16)
		category.add_theme_color_override("font_color", _row_text(row_length))
		content.add_child(category)
	var words: Label = Label.new()
	words.text = " · ".join(GameState._to_string_array(group.get("words", [])))
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.add_theme_font_size_override("font_size", 13)
	words.add_theme_color_override("font_color", _row_text(row_length))
	content.add_child(words)
	return card

func _solved_group_for_row(row_length: int) -> Dictionary:
	if row_length == 1 and GameState.is_top_solved:
		return {"size": 1, "words": [str(GameState.puzzle.get("top_word", ""))]}
	for group: Dictionary in GameState.get_solved_group_data():
		if int(group.get("size", 0)) == row_length:
			return group
	return {}

func _get_stable_word_order() -> Array[String]:
	var unsolved: Array[String] = GameState.get_unsolved_words()
	var ordered: Array[String] = []
	for word: String in _word_order:
		if unsolved.has(word):
			ordered.append(word)
	if ordered.is_empty():
		ordered = unsolved.duplicate()
		ordered.shuffle()
	else:
		for word: String in unsolved:
			if not ordered.has(word):
				ordered.append(word)
	_word_order = ordered.duplicate()
	return ordered

func _layout_for_width() -> void:
	if _card == null:
		return
	var card_width: float = clampf(size.x - 32.0, 300.0, 600.0)
	_card.custom_minimum_size = Vector2(card_width, 0.0)
	var tile_size: float = clampf((card_width - 105.0) / 5.0, 40.0, 88.0)
	for tile: Button in _word_buttons.values():
		tile.custom_minimum_size = Vector2(tile_size, tile_size)
		tile.size = Vector2(tile_size, tile_size)
		tile.add_theme_font_size_override("font_size", _tile_font_size(tile.text, tile_size))
	for hinted_tile: Button in _hinted_tiles.values():
		hinted_tile.custom_minimum_size = Vector2(tile_size, tile_size)
		hinted_tile.size = Vector2(tile_size, tile_size)
		hinted_tile.add_theme_font_size_override("font_size", _tile_font_size(hinted_tile.text, tile_size))
	for row_length: int in _placed_tiles:
		for placed_tile: Label in _placed_tiles[row_length]:
			placed_tile.custom_minimum_size = Vector2(tile_size, tile_size)
			placed_tile.size = Vector2(tile_size, tile_size)
			placed_tile.add_theme_font_size_override("font_size", _tile_font_size(placed_tile.text, tile_size))
	for row_length: int in _category_cards:
		var category_card: PanelContainer = _category_cards[row_length]
		var row_width: float = tile_size * row_length + TILE_GAP * float(row_length - 1)
		category_card.custom_minimum_size = Vector2(row_width, tile_size)
		category_card.size = Vector2(row_width, tile_size)
	var action_width: float = clampf((card_width - 80.0) / 3.0, 72.0, 110.0)
	for action_button: Button in _action_buttons:
		action_button.custom_minimum_size = Vector2(action_width, 42.0)

func _tile_font_size(word: String, tile_size: float) -> int:
	# A single-line word must fit within the square even in Finnish, where
	# compound words can be substantially longer than English equivalents.
	var characters: int = max(word.length(), 1)
	var estimated_size: int = floori((tile_size - 8.0) / (float(characters) * 0.70))
	return clampi(estimated_size, 7, 13)

func _update_mistakes() -> void:
	var maximum: int = int(SaveManager.settings.get("attempts", 4))
	var remaining: String = ""
	for index: int in maximum:
		remaining += "● " if index < GameState.attempts_left else "○ "
	_mistakes.text = "Virheitä jäljellä  %s" % remaining.strip_edges()

func _update_selection(selection: Array[String]) -> void:
	_selection.text = "Valitut: %s" % " · ".join(selection) if not selection.is_empty() else "Valitse 1–5 sanaa tarkistettavaksi"

func _on_game_started(_puzzle_title: String, _attempts_left: int) -> void:
	refresh()

func _on_selection_changed(selection: Array[String]) -> void:
	for word: String in _word_buttons:
		var tile: Button = _word_buttons[word]
		var selected: bool = selection.has(word)
		tile.button_pressed = selected
		tile.disabled = GameState.is_finished
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE if _is_placing else Control.MOUSE_FILTER_STOP
		tile.focus_mode = Control.FOCUS_NONE if _is_placing else Control.FOCUS_ALL
		tile.add_theme_stylebox_override("normal", _tile_style(SELECTED_FILL if selected else Color("e6e8e7"), SELECTED_BORDER if selected else Color("d8dcda")))
	_clear.disabled = selection.is_empty() or GameState.is_finished
	_check.disabled = not GameState.can_check_selection()
	_update_selection(selection)

func _on_group_solved(group: Dictionary) -> void:
	var row_length: int = int(group.get("size", 0))
	var swap: Dictionary = _capture_row_swap(row_length)
	_apply_swap_to_word_order(swap)
	_animating_row = row_length
	_is_placing = true
	_build_pyramid()
	if _placed_tiles.has(row_length):
		_animate_row_swap(swap)
		var placed_tween: Tween = create_tween()
		placed_tween.tween_interval(0.60)
		placed_tween.tween_callback(func() -> void: _show_placed_row(row_length))
		placed_tween.tween_interval(0.24)
		placed_tween.tween_callback(func() -> void: _activate_category_card(row_length, group))

func _on_top_solved(_word: String) -> void:
	_on_group_solved({"size": 1, "words": [str(GameState.puzzle.get("top_word", ""))]})

func _activate_category_card(row_length: int, group: Dictionary) -> void:
	if not _pyramid_rows.has(row_length) or not _placed_tiles.has(row_length):
		return
	var row: HBoxContainer = _pyramid_rows[row_length]
	for placed_tile: Label in _placed_tiles[row_length]:
		row.remove_child(placed_tile)
		placed_tile.queue_free()
	_placed_tiles.erase(row_length)
	var category_card: PanelContainer = _create_category_card(group)
	category_card.modulate.a = 0.0
	category_card.scale = Vector2(0.94, 0.94)
	row.add_child(category_card)
	_category_cards[row_length] = category_card
	_animating_row = -1
	_is_placing = false
	_layout_for_width()
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(category_card, "modulate:a", 1.0, 0.20)
	tween.tween_property(category_card, "scale", Vector2.ONE, 0.20)
	_on_selection_changed(GameState.selected_words)

func _show_placed_row(row_length: int) -> void:
	if not _placed_tiles.has(row_length):
		return
	for placed_tile: Label in _placed_tiles[row_length]:
		placed_tile.modulate.a = 1.0

func _capture_row_swap(row_length: int) -> Dictionary:
	var selected: Array[Dictionary] = []
	var targets: Array[Dictionary] = []
	for word: String in GameState.selected_words:
		if _word_buttons.has(word):
			var tile: Button = _word_buttons[word]
			selected.append({"word": word, "point": _to_board_point(tile.get_global_rect().get_center()), "size": tile.size})
	for word: String in _word_buttons:
		var target_tile: Button = _word_buttons[word]
		var parent: Node = target_tile.get_parent()
		if int(parent.get_meta("row_length", 0)) == row_length:
			targets.append({"word": word, "point": _to_board_point(target_tile.get_global_rect().get_center()), "size": target_tile.size, "row_length": row_length})
	return {"selected": selected, "targets": targets}

func _apply_swap_to_word_order(swap: Dictionary) -> void:
	var selected: Array = swap.get("selected", [])
	var targets: Array = swap.get("targets", [])
	var open_targets: Array = targets.duplicate()
	var moving_selected: Array = []
	var removals: Array[int] = []
	for source: Dictionary in selected:
		var matching_target_index: int = -1
		for target_index: int in open_targets.size():
			var candidate: Dictionary = open_targets[target_index]
			if str(candidate.get("word", "")) == str(source.get("word", "")):
				matching_target_index = target_index
				break
		if matching_target_index >= 0:
			var fixed_word_index: int = _word_order.find(str(source.get("word", "")))
			if fixed_word_index >= 0 and not removals.has(fixed_word_index):
				removals.append(fixed_word_index)
			open_targets.remove_at(matching_target_index)
		else:
			moving_selected.append(source)
	for index: int in moving_selected.size():
		var source: Dictionary = moving_selected[index]
		var target: Dictionary = open_targets[index]
		var source_word: String = str(source.get("word", ""))
		var target_word: String = str(target.get("word", ""))
		var source_index: int = _word_order.find(source_word)
		var target_index: int = _word_order.find(target_word)
		if source_index >= 0:
			_word_order[source_index] = target_word
		if target_index >= 0 and not removals.has(target_index):
			removals.append(target_index)
	removals.sort()
	for offset: int in removals.size():
		var removal_index: int = removals[removals.size() - 1 - offset]
		_word_order.remove_at(removal_index)

func _animate_row_swap(swap: Dictionary) -> void:
	var selected: Array = swap.get("selected", [])
	var targets: Array = swap.get("targets", [])
	if targets.is_empty():
		return
	var row_length: int = int(targets[0].get("row_length", 0))
	var correct_fill: Color = _row_fill(row_length)
	var correct_border: Color = _row_border(row_length)
	var open_targets: Array = targets.duplicate()
	var moving_selected: Array = []
	for source: Dictionary in selected:
		var matching_target_index: int = -1
		for target_index: int in open_targets.size():
			var candidate: Dictionary = open_targets[target_index]
			if str(candidate.get("word", "")) == str(source.get("word", "")):
				matching_target_index = target_index
				break
		if matching_target_index >= 0:
			var matched_target: Dictionary = open_targets[matching_target_index]
			var fixed_point: Vector2 = matched_target.get("point", Vector2.ZERO)
			var fixed_size: Vector2 = matched_target.get("size", Vector2(76.0, 76.0))
			_fly_ghost(str(source.get("word", "")), fixed_point, fixed_point, fixed_size, correct_fill, correct_border)
			open_targets.remove_at(matching_target_index)
		else:
			moving_selected.append(source)
	for index: int in moving_selected.size():
		var source: Dictionary = moving_selected[index]
		var target: Dictionary = open_targets[index]
		var source_point: Vector2 = source.get("point", Vector2.ZERO)
		var target_point: Vector2 = target.get("point", Vector2.ZERO)
		var source_size: Vector2 = source.get("size", Vector2(76.0, 76.0))
		var target_size: Vector2 = target.get("size", Vector2(76.0, 76.0))
		_fly_ghost(str(source.get("word", "")), source_point, target_point, source_size, correct_fill, correct_border)
		var target_word: String = str(target.get("word", ""))
		if target_word != str(source.get("word", "")) and not GameState.selected_words.has(target_word):
			_fly_ghost(target_word, target_point, source_point, target_size, Color("e6e8e7"), Color("d8dcda"))

func _fly_ghost(word: String, start: Vector2, destination: Vector2, block_size: Vector2, fill_color: Color, border_color: Color) -> void:
	var ghost: Label = Label.new()
	ghost.text = word
	ghost.position = start - block_size * 0.5
	ghost.size = block_size
	ghost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ghost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ghost.autowrap_mode = TextServer.AUTOWRAP_OFF
	ghost.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ghost.add_theme_font_size_override("font_size", 12)
	ghost.add_theme_color_override("font_color", Color("292d2e"))
	ghost.add_theme_stylebox_override("normal", _tile_style(fill_color, border_color))
	ghost.z_index = 10
	add_child(ghost)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "position", destination - block_size * 0.5, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.12).set_delay(0.40)
	tween.set_parallel(false)
	tween.tween_callback(ghost.queue_free)

func _to_board_point(global_point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_point

func _on_guess_failed(left: int) -> void:
	_update_mistakes()
	_message.text = "Nämä sanat eivät muodosta ryhmää. Kokeile uudelleen."
	_highlight_incorrect_selection()
	if left <= 0:
		_build_pyramid()

func _on_repeated_guess_attempted() -> void:
	_message.text = "Olet jo kokeillut tätä yhdistelmää."

func _on_guess_feedback(text: String) -> void:
	_message.text = text

func _highlight_incorrect_selection() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	for word: String in GameState.selected_words:
		if _word_buttons.has(word):
			var tile: Button = _word_buttons[word]
			tween.tween_property(tile, "modulate", Color("e69891"), 0.08)
	tween.set_parallel(false)
	tween.tween_interval(0.12)
	tween.set_parallel(true)
	for word: String in GameState.selected_words:
		if _word_buttons.has(word):
			var tile: Button = _word_buttons[word]
			tween.tween_property(tile, "modulate", Color.WHITE, 0.18)

func _on_game_finished(won: bool, top_word: String) -> void:
	for tile: Button in _word_buttons.values():
		tile.disabled = true
	_check.disabled = true
	_clear.disabled = true
	_hint.disabled = true
	_message.text = "Pyramidi valmis — huippusana: %s" % top_word if won else "Virheet loppuivat — ratkaisu näytetään."
	_update_mistakes()

func _on_puzzle_pool_completed(mode: String) -> void:
	var pool_name: String = "päivittäiset haasteet" if mode == "daily" else "rajattomat haasteet"
	_message.text = "Onneksi olkoon! Olet pelannut kaikki %s." % pool_name

func _on_hint_provided(text: String) -> void:
	_message.text = text

func _on_hint_placed(word: String, row_length: int) -> void:
	var source_point: Vector2 = Vector2.ZERO
	var source_size: Vector2 = Vector2.ZERO
	var has_source: bool = _word_buttons.has(word)
	if has_source:
		var source_tile: Button = _word_buttons[word]
		var source_rect: Rect2 = source_tile.get_global_rect()
		source_point = _to_board_point(source_rect.get_center())
		source_size = source_rect.size
	var displaced_word: String = ""
	var displaced_point: Vector2 = Vector2.ZERO
	var displaced_size: Vector2 = Vector2.ZERO
	# A hint always locks into the first position of its answer row. Capture the
	# tile currently in that position so it can exchange places with the hint.
	var leftmost_target_x: float = 1000000000.0
	for candidate_word: String in _word_buttons:
		var candidate_tile: Button = _word_buttons[candidate_word]
		var candidate_row: Node = candidate_tile.get_parent()
		if int(candidate_row.get_meta("row_length", 0)) != row_length:
			continue
		var candidate_rect: Rect2 = candidate_tile.get_global_rect()
		if candidate_rect.position.x < leftmost_target_x:
			leftmost_target_x = candidate_rect.position.x
			displaced_word = candidate_word
			displaced_point = _to_board_point(candidate_rect.get_center())
			displaced_size = candidate_rect.size
	if has_source and not displaced_word.is_empty() and displaced_word != word:
		_swap_hint_word_order(word, displaced_word)
	_build_pyramid()
	if has_source and not displaced_word.is_empty() and displaced_word != word and _word_buttons.has(displaced_word):
		# Its new, reflowed tile must not be visible before the outgoing block
		# reaches that position.
		var reflowed_tile: Button = _word_buttons[displaced_word]
		reflowed_tile.modulate.a = 0.0
	if has_source and _hinted_tiles.has(word):
		# Do not show a second copy of the hint at its destination while the
		# original is still travelling there.
		var locked_tile: Button = _hinted_tiles[word]
		locked_tile.modulate.a = 0.0
	if _hinted_tiles.has(word):
		call_deferred("_animate_hint_to_locked_slot", word, source_point, source_size, has_source, displaced_word, displaced_point, displaced_size)

func _swap_hint_word_order(hinted_word: String, displaced_word: String) -> void:
	var hinted_index: int = _word_order.find(hinted_word)
	var displaced_index: int = _word_order.find(displaced_word)
	if hinted_index < 0 or displaced_index < 0:
		return
	_word_order[hinted_index] = displaced_word
	_word_order[displaced_index] = hinted_word

func _animate_hint_to_locked_slot(word: String, source_point: Vector2, source_size: Vector2, has_source: bool, displaced_word: String, displaced_point: Vector2, displaced_size: Vector2) -> void:
	# Container controls receive their final positions on the next frame. Reading
	# the target before then caused the hint flight to use an incorrect position.
	await get_tree().process_frame
	if not _hinted_tiles.has(word):
		return
	var hinted_tile: Button = _hinted_tiles[word]
	if has_source:
		var target_rect: Rect2 = hinted_tile.get_global_rect()
		var destination: Vector2 = _to_board_point(target_rect.get_center())
		var target_row: Node = hinted_tile.get_parent()
		var row_length: int = int(target_row.get_meta("row_length", 0))
		_fly_ghost(word, source_point, destination, source_size, _row_fill(row_length), _row_border(row_length))
		var reveal_tween: Tween = create_tween()
		reveal_tween.tween_interval(0.52)
		reveal_tween.tween_callback(func() -> void:
			if _hinted_tiles.has(word):
				var locked_tile: Button = _hinted_tiles[word]
				locked_tile.modulate.a = 1.0
		)
		if not displaced_word.is_empty() and displaced_word != word:
			_fly_ghost(displaced_word, displaced_point, source_point, displaced_size, Color("e6e8e7"), Color("d8dcda"))
			if _word_buttons.has(displaced_word):
				var displaced_reveal_tween: Tween = create_tween()
				displaced_reveal_tween.tween_interval(0.52)
				displaced_reveal_tween.tween_callback(func() -> void:
					if _word_buttons.has(displaced_word):
						var reflowed_tile: Button = _word_buttons[displaced_word]
						reflowed_tile.modulate.a = 1.0
				)

func _on_hint_count_changed(used: int, limit: int) -> void:
	var remaining: int = max(limit - used, 0)
	if remaining > 0:
		_hint.text = "Vihje %d" % remaining
		_hint.disabled = false
	elif GameState.game_mode == "unlimited" or GameState.rewarded_hint_claimed:
		_hint.text = "Vihje 0"
		_hint.disabled = true
	else:
		_hint.text = "Bonusvihje"
		_hint.disabled = false

func _on_rewarded_hint_required() -> void:
	_hint.text = "Mainos +1"
	_message.text = "Kaksi maksutonta vihjettä on käytetty. Katso palkittu mainos saadaksesi bonusvihjeen."
	_hint.disabled = false

func _on_rewarded_ad_unavailable(message: String) -> void:
	_message.text = message
	_hint.text = "Mainos +1"
	_hint.disabled = false

func _on_hint_pressed() -> void:
	if _hint.text == "Mainos +1":
		AdManager.request_rewarded_hint()
	else:
		GameState.request_hint()

func _show_instructions() -> void:
	_message.text = "Etsi 2, 3, 4 ja 5 sanan ryhmät sekä arvaa huippusana yhdellä valinnalla."

func _action_button(label_text: String, filled: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(110, 42)
	button.add_theme_font_size_override("font_size", 15)
	var normal_color: Color = Color("777d7b") if filled else Color.WHITE
	button.add_theme_stylebox_override("normal", _button_style(normal_color))
	button.add_theme_stylebox_override("hover", _button_style(Color("656b69") if filled else Color("f1f2f1")))
	button.add_theme_stylebox_override("disabled", _button_style(Color("d9dcda") if filled else Color.WHITE))
	button.add_theme_color_override("font_color", Color.WHITE if filled else Color("4d5351"))
	button.add_theme_color_override("font_disabled_color", Color("969b99"))
	return button

func _card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.07)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 2)
	return style

func _tile_style(color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.border_color = border_color
	style.set_border_width_all(2)
	# Button's theme default margins are intended for wide UI buttons. Keeping
	# them here would make ordinary words such as MUSHROOM truncate early.
	style.content_margin_left = 3.0
	style.content_margin_right = 3.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style

func _row_fill(row_length: int) -> Color:
	match row_length:
		1: return Color("e2ccff") # violet: top word
		2: return Color("c9e9ff") # blue: pair
		3: return Color("ffe6a0") # gold: trio
		4: return Color("ffcdbf") # coral: four-word row
		5: return Color("c8edbd") # green: five-word row
		_: return Color("e6e8e7")

func _row_border(row_length: int) -> Color:
	match row_length:
		1: return Color("8964ae")
		2: return Color("4f93be")
		3: return Color("c38a1f")
		4: return Color("c76d51")
		5: return Color("4d9b5b")
		_: return Color("d8dcda")

func _row_text(row_length: int) -> Color:
	match row_length:
		1: return Color("4d3a62")
		2: return Color("244b61")
		3: return Color("5e4715")
		4: return Color("663c30")
		5: return Color("294438")
		_: return Color("292d2e")

func _category_card_style(row_length: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = _row_fill(row_length)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	style.border_color = _row_border(row_length)
	style.set_border_width_all(1)
	return style

func _button_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_color = Color("cfd3d1")
	style.set_border_width_all(1)
	return style
