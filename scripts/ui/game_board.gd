class_name GameBoard
extends Control

signal request_menu
signal request_new_game

const ROW_LENGTHS: Array[int] = [1, 2, 3, 4, 5]
const TILE_GAP: float = 8.0
const FONT_FREDOKA: Font = preload("res://assets/fonts/Fredoka.ttf")
const FONT_DM_SANS: Font = preload("res://assets/fonts/DMSans.ttf")
const UI_BACKGROUND: Color = Color("fffdf5")
const UI_SURFACE: Color = Color.WHITE
const UI_TEXT: Color = Color("1a0a5e")
const UI_MUTED_TEXT: Color = Color("9b8cd4")
const UI_BORDER: Color = Color("d6cfef")
const UI_SURFACE_TINT: Color = Color("eee9fa")
const UI_PRIMARY: Color = Color("1a0a5e")
const UI_PRIMARY_HOVER: Color = Color("2a167c")
const UI_PRIMARY_PRESSED: Color = Color("120742")
const UI_YELLOW: Color = Color("ffd600")
const UI_MAGENTA: Color = Color("b939ff")
const UI_RED: Color = Color("ff5533")
const UI_TEAL: Color = Color("00bfa5")
const SELECTED_FILL: Color = UI_PRIMARY
const SELECTED_BORDER: Color = UI_PRIMARY

var _card: PanelContainer
var _message: Label
var _selection: Label
var _mistakes: Label
var _lives_row: HBoxContainer
var _puzzle_title: Label
var _mode_label: Label
var _pyramid: VBoxContainer
var _check: Button
var _clear: Button
var _hint: Button
var _result: Button
var _share: Button
var _aftermath_layer: Control
var _word_buttons: Dictionary = {}
var _word_order: Array[String] = []
var _hinted_tiles: Dictionary = {}
var _placed_tiles: Dictionary = {}
var _category_cards: Dictionary = {}
var _pyramid_rows: Dictionary = {}
var _action_buttons: Array[Button] = []
var _animating_row: int = -1
var _is_placing: bool = false
var _font_fredoka_semibold: FontVariation
var _font_fredoka_bold: FontVariation

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_font_variations()
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

func _setup_font_variations() -> void:
	_font_fredoka_semibold = _font_variation(FONT_FREDOKA, 600, 0.10)
	_font_fredoka_bold = _font_variation(FONT_FREDOKA, 650, 0.18)

func _font_variation(base_font: Font, weight: int, embolden: float) -> FontVariation:
	var font: FontVariation = FontVariation.new()
	font.base_font = base_font
	font.variation_opentype = {"wght": weight}
	font.variation_embolden = embolden
	return font

func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = UI_BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var page_margin: MarginContainer = MarginContainer.new()
	page_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_margin.add_theme_constant_override("margin_left", 12)
	page_margin.add_theme_constant_override("margin_right", 12)
	page_margin.add_theme_constant_override("margin_top", 12)
	page_margin.add_theme_constant_override("margin_bottom", 14)
	add_child(page_margin)
	var page: VBoxContainer = VBoxContainer.new()
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 8)
	page_margin.add_child(page)
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_theme_constant_override("separation", 10)
	page.add_child(top_bar)
	var back: Button = Button.new()
	back.text = "< " + SaveManager.text("back")
	back.custom_minimum_size = Vector2(84, 34)
	back.add_theme_font_override("font", FONT_DM_SANS)
	back.add_theme_font_size_override("font_size", 14)
	back.add_theme_stylebox_override("normal", _outline_button_style(UI_SURFACE))
	back.add_theme_stylebox_override("hover", _outline_button_style(UI_SURFACE_TINT))
	back.add_theme_color_override("font_color", UI_TEXT)
	back.pressed.connect(func() -> void: request_menu.emit())
	top_bar.add_child(back)
	var title_stack: VBoxContainer = VBoxContainer.new()
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title_stack)
	var game_title: Label = Label.new()
	game_title.text = "Word Pyramid"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_font_override("font", _font_fredoka_semibold)
	game_title.add_theme_font_size_override("font_size", 21)
	game_title.add_theme_color_override("font_color", UI_TEXT)
	title_stack.add_child(game_title)
	_mode_label = Label.new()
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.add_theme_font_override("font", FONT_DM_SANS)
	_mode_label.add_theme_font_size_override("font_size", 11)
	_mode_label.add_theme_color_override("font_color", UI_MUTED_TEXT)
	title_stack.add_child(_mode_label)
	var right_spacer: Control = Control.new()
	right_spacer.custom_minimum_size = Vector2(84, 34)
	top_bar.add_child(right_spacer)
	_lives_row = HBoxContainer.new()
	_puzzle_title = Label.new()
	_puzzle_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_puzzle_title.add_theme_font_override("font", _font_fredoka_semibold)
	_puzzle_title.add_theme_font_size_override("font_size", 22)
	_puzzle_title.add_theme_color_override("font_color", UI_TEXT)
	page.add_child(_puzzle_title)
	_card = PanelContainer.new()
	_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_card.add_theme_stylebox_override("panel", _card_style())
	page.add_child(_card)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 0)
	_card.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var top: HBoxContainer = HBoxContainer.new()
	content.add_child(top)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var instructions: Button = Button.new()
	instructions.text = SaveManager.text("instructions")
	instructions.flat = true
	instructions.add_theme_font_override("font", FONT_DM_SANS)
	instructions.add_theme_font_size_override("font_size", 13)
	instructions.add_theme_color_override("font_color", UI_MUTED_TEXT)
	instructions.pressed.connect(_show_instructions)
	top.add_child(instructions)
	var title: Label = Label.new()
	title.text = SaveManager.text("board_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", _font_fredoka_semibold)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", UI_TEXT)
	title.visible = false
	content.add_child(title)
	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.add_theme_font_override("font", FONT_DM_SANS)
	_message.add_theme_color_override("font_color", UI_MUTED_TEXT)
	content.add_child(_message)
	_selection = Label.new()
	_selection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection.add_theme_font_override("font", FONT_DM_SANS)
	_selection.add_theme_color_override("font_color", UI_MUTED_TEXT)
	_selection.add_theme_font_size_override("font_size", 14)
	content.add_child(_selection)
	_pyramid = VBoxContainer.new()
	_pyramid.alignment = BoxContainer.ALIGNMENT_CENTER
	_pyramid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pyramid.add_theme_constant_override("separation", TILE_GAP)
	content.add_child(_pyramid)
	_mistakes = Label.new()
	_mistakes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mistakes.add_theme_font_override("font", FONT_DM_SANS)
	_mistakes.add_theme_font_size_override("font_size", 15)
	_mistakes.add_theme_color_override("font_color", UI_MUTED_TEXT)
	content.add_child(_mistakes)
	var action_spacer: Control = Control.new()
	action_spacer.custom_minimum_size = Vector2(0, 8)
	content.add_child(action_spacer)
	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 12)
	content.add_child(action_row)
	_hint = _action_button(_hint_button_label(SaveManager.text("hint_count") % 2))
	_hint.pressed.connect(_on_hint_pressed)
	action_row.add_child(_hint)
	_clear = _action_button(SaveManager.text("clear"))
	_clear.pressed.connect(GameState.clear_selection)
	_clear.visible = false
	action_row.add_child(_clear)
	_check = _action_button(SaveManager.text("check"), true)
	_check.pressed.connect(GameState.check_selection)
	action_row.add_child(_check)
	_result = _action_button("", false)
	_result.visible = false
	_result.pressed.connect(_on_result_pressed)
	action_row.add_child(_result)
	_share = _action_button(SaveManager.text("share_result"), true)
	_share.visible = false
	_share.pressed.connect(_on_share_pressed)
	action_row.add_child(_share)
	_action_buttons = [_hint, _check, _result, _share]
	var game_actions: HBoxContainer = HBoxContainer.new()
	game_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	game_actions.add_theme_constant_override("separation", 10)
	game_actions.visible = false
	content.add_child(game_actions)
	var new_game: Button = Button.new()
	new_game.text = SaveManager.text("new_game")
	new_game.flat = true
	new_game.add_theme_font_override("font", FONT_DM_SANS)
	new_game.add_theme_color_override("font_color", UI_MUTED_TEXT)
	new_game.pressed.connect(func() -> void: request_new_game.emit())
	game_actions.add_child(new_game)
	var second_divider: Label = Label.new()
	second_divider.text = "|"
	second_divider.add_theme_font_override("font", FONT_DM_SANS)
	game_actions.add_child(second_divider)
	var menu: Button = Button.new()
	menu.text = SaveManager.text("menu")
	menu.flat = true
	menu.add_theme_font_override("font", FONT_DM_SANS)
	menu.add_theme_color_override("font_color", UI_MUTED_TEXT)
	menu.pressed.connect(func() -> void: request_menu.emit())
	game_actions.add_child(menu)

func refresh() -> void:
	if not is_node_ready():
		return
	_message.text = SaveManager.text("daily_message")
	_mode_label.text = SaveManager.text("daily_challenge_label").to_upper() if GameState.game_mode == "daily" else SaveManager.text("unlimited_mode_label").to_upper()
	_puzzle_title.text = str(GameState.puzzle.get("title", SaveManager.text("board_title")))
	_build_pyramid()
	_update_mistakes()
	_update_selection(GameState.selected_words)
	if GameState.is_finished:
		_on_game_finished(GameState.completed_won, str(GameState.puzzle.get("top_word", "")))
	else:
		_show_play_actions()

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
	tile.tooltip_text = SaveManager.text("select_tooltip") % word
	tile.add_theme_font_override("font", _font_fredoka_semibold)
	tile.add_theme_stylebox_override("normal", _tile_style(UI_SURFACE, UI_BORDER))
	tile.add_theme_stylebox_override("hover", _tile_style(UI_SURFACE, Color("a89dd4")))
	tile.add_theme_stylebox_override("pressed", _tile_style(SELECTED_FILL, SELECTED_BORDER))
	tile.add_theme_stylebox_override("hover_pressed", _tile_style(SELECTED_FILL, SELECTED_BORDER))
	tile.add_theme_color_override("font_color", UI_TEXT)
	_apply_tile_text_colors(tile, UI_TEXT)
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
	tile.add_theme_font_override("font", _font_fredoka_semibold)
	tile.add_theme_font_size_override("font_size", 13)
	tile.add_theme_color_override("font_disabled_color", _row_text(row_length))
	tile.add_theme_stylebox_override("disabled", _tile_style(_row_fill(row_length), _row_border(row_length)))
	tile.tooltip_text = SaveManager.text("hint_tooltip")
	return tile

func _create_placed_tile(word: String, row_length: int) -> Label:
	var tile: Label = Label.new()
	tile.text = word
	tile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tile.autowrap_mode = TextServer.AUTOWRAP_OFF
	tile.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tile.add_theme_font_override("font", _font_fredoka_semibold)
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
		category.name = "CategoryLabel"
		category.text = str(group.get("label", ""))
		category.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		category.autowrap_mode = TextServer.AUTOWRAP_OFF
		category.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		category.add_theme_font_override("font", _font_fredoka_semibold)
		category.add_theme_font_size_override("font_size", 16)
		category.add_theme_color_override("font_color", _row_text(row_length))
		content.add_child(category)
	var words: Label = Label.new()
	words.name = "WordsLabel"
	words.text = " · ".join(GameState._to_string_array(group.get("words", [])))
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.autowrap_mode = TextServer.AUTOWRAP_OFF
	words.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	words.add_theme_font_override("font", FONT_DM_SANS)
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
	var card_width: float = clampf(size.x - 24.0, 300.0, 600.0)
	_card.custom_minimum_size = Vector2(card_width, 0.0)
	var tile_size: float = clampf((card_width - TILE_GAP * 4.0) / 5.0, 44.0, 98.0)
	var tile_height: float = clampf(tile_size * 0.72, 46.0, 70.0)
	for tile: Button in _word_buttons.values():
		tile.custom_minimum_size = Vector2(tile_size, tile_height)
		tile.size = Vector2(tile_size, tile_height)
		tile.add_theme_font_size_override("font_size", _tile_font_size(tile.text, tile_size))
	for hinted_tile: Button in _hinted_tiles.values():
		hinted_tile.custom_minimum_size = Vector2(tile_size, tile_height)
		hinted_tile.size = Vector2(tile_size, tile_height)
		hinted_tile.add_theme_font_size_override("font_size", _tile_font_size(hinted_tile.text, tile_size))
	for row_length: int in _placed_tiles:
		for placed_tile: Label in _placed_tiles[row_length]:
			placed_tile.custom_minimum_size = Vector2(tile_size, tile_height)
			placed_tile.size = Vector2(tile_size, tile_height)
			placed_tile.add_theme_font_size_override("font_size", _tile_font_size(placed_tile.text, tile_size))
	for row_length: int in _category_cards:
		var category_card: PanelContainer = _category_cards[row_length]
		var row_width: float = tile_size * row_length + TILE_GAP * float(row_length - 1)
		category_card.custom_minimum_size = Vector2(row_width, tile_height)
		category_card.size = Vector2(row_width, tile_height)
		_fit_category_card_text(category_card, row_width)
	var action_width: float = clampf((card_width - 12.0) / 2.0, 136.0, 260.0)
	for action_button: Button in _action_buttons:
		action_button.custom_minimum_size = Vector2(action_width, 64.0)
		action_button.add_theme_font_size_override("font_size", 18)

func _tile_font_size(word: String, tile_size: float) -> int:
	# A single-line word must fit within the square even in Finnish, where
	# compound words can be substantially longer than English equivalents.
	var characters: int = max(word.length(), 1)
	var estimated_size: int = floori((tile_size - 8.0) / (float(characters) * 0.70))
	return clampi(estimated_size, 8, 15)

func _fit_category_card_text(category_card: PanelContainer, row_width: float) -> void:
	var available_width: float = max(row_width - 30.0, 24.0)
	var category: Label = category_card.find_child("CategoryLabel", true, false) as Label
	if category != null:
		category.add_theme_font_size_override("font_size", _single_line_font_size(category.text, available_width, 16))
	var words: Label = category_card.find_child("WordsLabel", true, false) as Label
	if words != null:
		words.add_theme_font_size_override("font_size", _single_line_font_size(words.text, available_width, 13))

func _single_line_font_size(text: String, available_width: float, maximum_size: int) -> int:
	var characters: int = max(text.length(), 1)
	var estimated_size: int = floori(available_width / (float(characters) * 0.58))
	return clampi(estimated_size, 7, maximum_size)

func _update_mistakes() -> void:
	var maximum: int = int(SaveManager.settings.get("attempts", 4))
	_mistakes.text = SaveManager.text("mistakes_left") % [GameState.attempts_left, maximum]
	_update_lives(maximum - GameState.attempts_left, maximum)

func _update_lives(used: int, maximum: int) -> void:
	if _lives_row == null:
		return
	for child: Node in _lives_row.get_children():
		child.queue_free()
	for index: int in range(maximum):
		var dot: Panel = Panel.new()
		dot.custom_minimum_size = Vector2(14, 14)
		var is_used: bool = index < used
		dot.add_theme_stylebox_override("panel", _life_dot_style(is_used))
		_lives_row.add_child(dot)

func _update_selection(selection: Array[String]) -> void:
	_selection.text = SaveManager.text("selected") % " · ".join(selection) if not selection.is_empty() else SaveManager.text("select_words")

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
		tile.add_theme_stylebox_override("normal", _tile_style(SELECTED_FILL if selected else UI_SURFACE, SELECTED_BORDER if selected else UI_BORDER))
		tile.add_theme_stylebox_override("hover_pressed", _tile_style(SELECTED_FILL, SELECTED_BORDER))
		_apply_tile_text_colors(tile, Color.WHITE if selected else UI_TEXT)
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
			_fly_ghost(target_word, target_point, source_point, target_size, UI_SURFACE, UI_BORDER)

func _fly_ghost(word: String, start: Vector2, destination: Vector2, block_size: Vector2, fill_color: Color, border_color: Color) -> void:
	var ghost: Label = Label.new()
	ghost.text = word
	ghost.position = start - block_size * 0.5
	ghost.size = block_size
	ghost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ghost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ghost.autowrap_mode = TextServer.AUTOWRAP_OFF
	ghost.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ghost.add_theme_font_override("font", _font_fredoka_semibold)
	ghost.add_theme_font_size_override("font_size", _tile_font_size(word, block_size.x))
	ghost.add_theme_color_override("font_color", UI_TEXT)
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
	_message.text = SaveManager.text("guess_failed")
	_highlight_incorrect_selection()
	if left <= 0:
		_build_pyramid()

func _on_repeated_guess_attempted() -> void:
	_message.text = SaveManager.text("repeated_guess")

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
	_show_result_actions()
	_message.text = SaveManager.text("game_complete") % top_word if won else SaveManager.text("game_failed")
	_update_mistakes()
	_show_aftermath(won)

func _show_play_actions() -> void:
	_hint.visible = true
	_check.visible = true
	_clear.visible = false
	_result.visible = false
	_share.visible = false
	_hint.disabled = false
	_check.disabled = not GameState.can_check_selection()

func _show_result_actions() -> void:
	_hint.visible = false
	_check.visible = false
	_clear.visible = false
	_result.visible = true
	_share.visible = true
	_result.disabled = false
	_share.disabled = false
	_result.text = _result_score_text()

func _result_score_text() -> String:
	var correct: int = max(GameState.result_correct_count, 0)
	var total: int = max(GameState.result_total_count(), correct)
	return SaveManager.text("result_score") % [correct, total]

func _on_result_pressed() -> void:
	_message.text = _result_score_text()

func _on_share_pressed() -> void:
	var correct: int = max(GameState.result_correct_count, 0)
	var total: int = max(GameState.result_total_count(), correct)
	var text: String = SaveManager.text("share_daily_result") % [
		GameState.daily_date,
		correct,
		total,
		SaveManager.get_daily_streak(GameState.daily_date)
	]
	DisplayServer.clipboard_set(text)
	_message.text = SaveManager.text("result_copied")

func _show_aftermath(won: bool) -> void:
	if is_instance_valid(_aftermath_layer):
		return
	var correct: int = max(GameState.result_correct_count, 0)
	var total: int = max(GameState.result_total_count(), correct)
	var max_attempts: int = int(SaveManager.settings.get("attempts", 4))
	var mistakes: int = clampi(max_attempts - GameState.attempts_left, 0, max_attempts)
	var layer: Control = Control.new()
	layer.name = "AftermathLayer"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.modulate.a = 0.0
	add_child(layer)
	_aftermath_layer = layer

	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.102, 0.039, 0.369, 0.58)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(backdrop)

	var stack: VBoxContainer = VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(stack)
	var top_space: Control = Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(top_space)

	var sheet: PanelContainer = PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", _aftermath_sheet_style())
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_child(sheet)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 32)
	sheet.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)

	var handle: Panel = Panel.new()
	handle.custom_minimum_size = Vector2(42, 4)
	handle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	handle.add_theme_stylebox_override("panel", _aftermath_handle_style())
	content.add_child(handle)

	var emoji: Label = _aftermath_label("🎉" if won else "✕", 40, UI_YELLOW if won else UI_RED)
	content.add_child(emoji)
	var title: Label = _aftermath_label(SaveManager.text("aftermath_win_title") if won else SaveManager.text("aftermath_loss_title"), 31, UI_YELLOW if won else UI_RED)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(title)
	var subtitle_text: String
	if won:
		subtitle_text = SaveManager.text("aftermath_flawless") if mistakes == 0 else SaveManager.text("aftermath_solved_mistakes") % mistakes
	else:
		subtitle_text = SaveManager.text("aftermath_loss_subtitle") % [correct, total]
	content.add_child(_aftermath_label(subtitle_text, 14, Color(1, 1, 1, 0.58), FONT_DM_SANS))

	var streak_panel: PanelContainer = PanelContainer.new()
	streak_panel.add_theme_stylebox_override("panel", _aftermath_inner_style())
	streak_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(streak_panel)
	var streak_margin: MarginContainer = MarginContainer.new()
	streak_margin.add_theme_constant_override("margin_left", 16)
	streak_margin.add_theme_constant_override("margin_right", 16)
	streak_margin.add_theme_constant_override("margin_top", 18)
	streak_margin.add_theme_constant_override("margin_bottom", 18)
	streak_panel.add_child(streak_margin)
	var streak_box: VBoxContainer = VBoxContainer.new()
	streak_box.alignment = BoxContainer.ALIGNMENT_CENTER
	streak_box.add_theme_constant_override("separation", 4)
	streak_margin.add_child(streak_box)
	var has_daily_streak: bool = GameState.game_mode == "daily"
	var flame_text: String = "🔥" if has_daily_streak else ("✓" if won else "✕")
	var flame: Label = _aftermath_label(flame_text, 52, Color.WHITE)
	streak_box.add_child(flame)
	var streak_to: int = SaveManager.get_daily_streak(GameState.daily_date) if has_daily_streak else 0
	var streak_from: int = max(streak_to - 1, 0) if won and has_daily_streak else streak_to
	var streak_number: Label = _aftermath_label(str(streak_from) if has_daily_streak else "%d/%d" % [correct, total], 64, UI_YELLOW)
	streak_box.add_child(streak_number)
	var streak_caption_text: String = SaveManager.text("aftermath_results")
	if has_daily_streak:
		streak_caption_text = SaveManager.text("aftermath_streak") % [streak_from, streak_to] if won else SaveManager.text("aftermath_streak_lost")
	var streak_caption: Label = _aftermath_label(streak_caption_text, 13, Color(1, 1, 1, 0.66), _font_fredoka_semibold)
	streak_box.add_child(streak_caption)

	var stats_row: HBoxContainer = HBoxContainer.new()
	stats_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.add_theme_constant_override("separation", 10)
	content.add_child(stats_row)
	stats_row.add_child(_stat_pill(SaveManager.text("stat_mistakes"), str(mistakes), UI_YELLOW if mistakes == 0 else Color("ff8066")))
	stats_row.add_child(_stat_pill(SaveManager.text("stat_groups"), "%d / 4" % clampi(GameState.solved_groups.size(), 0, 4), UI_TEAL))
	stats_row.add_child(_stat_pill(SaveManager.text("stat_hints_used"), str(GameState.hints_used), UI_MAGENTA))

	var share_button: Button = _aftermath_button(SaveManager.text("share_result"), true, won)
	share_button.pressed.connect(func() -> void:
		_on_share_pressed()
		share_button.text = SaveManager.text("result_copied")
	)
	content.add_child(share_button)
	var menu_button: Button = _aftermath_button(SaveManager.text("menu"), false)
	menu_button.pressed.connect(func() -> void: request_menu.emit())
	content.add_child(menu_button)

	await get_tree().process_frame
	sheet.position.y += sheet.size.y
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(layer, "modulate:a", 1.0, 0.22)
	tween.tween_property(sheet, "position:y", sheet.position.y - sheet.size.y, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if won and has_daily_streak:
		flame.scale = Vector2(0.65, 0.65)
		streak_number.text = str(streak_from)
		await get_tree().create_timer(0.56).timeout
		streak_number.text = str(streak_to)
		streak_caption.text = SaveManager.text("aftermath_streak") % [streak_from, streak_to]
		var pop: Tween = create_tween().set_parallel(true)
		pop.tween_property(flame, "scale", Vector2(1.36, 1.36), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(flame, "scale", Vector2.ONE, 0.22).set_delay(0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		pop.tween_property(streak_number, "scale", Vector2(1.22, 1.22), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(streak_number, "scale", Vector2.ONE, 0.22).set_delay(0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif not won and has_daily_streak:
		await get_tree().create_timer(0.42).timeout
		create_tween().tween_property(flame, "modulate", Color(0.55, 0.55, 0.55, 1.0), 0.32)

func _on_puzzle_pool_completed(mode: String) -> void:
	var pool_name: String = SaveManager.text("daily_pool") if mode == "daily" else SaveManager.text("unlimited_pool")
	_message.text = SaveManager.text("pool_complete") % pool_name

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
			_fly_ghost(displaced_word, displaced_point, source_point, displaced_size, UI_SURFACE, UI_BORDER)
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
		_set_hint_button_text(SaveManager.text("hint_count") % remaining)
		_hint.disabled = false
	elif GameState.game_mode == "unlimited" or GameState.rewarded_hint_claimed:
		_set_hint_button_text(SaveManager.text("hint_zero"))
		_hint.disabled = true
	else:
		_set_hint_button_text(SaveManager.text("bonus_hint"))
		_hint.disabled = false

func _on_rewarded_hint_required() -> void:
	_set_hint_button_text(SaveManager.text("ad_hint"), true)
	_message.text = SaveManager.text("rewarded_hint_required")
	_hint.disabled = false

func _on_rewarded_ad_unavailable(message: String) -> void:
	_message.text = message
	_set_hint_button_text(SaveManager.text("ad_hint"), true)
	_hint.disabled = false

func _on_hint_pressed() -> void:
	if bool(_hint.get_meta("rewarded_ad", false)):
		AdManager.request_rewarded_hint()
	else:
		GameState.request_hint()

func _show_instructions() -> void:
	_message.text = SaveManager.text("instructions_text")

func _action_button(label_text: String, filled: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(110, 42)
	button.add_theme_font_override("font", _font_fredoka_semibold)
	button.add_theme_font_size_override("font_size", 16)
	var normal_color: Color = UI_PRIMARY if filled else UI_SURFACE
	button.add_theme_stylebox_override("normal", _button_style(normal_color, UI_PRIMARY if filled else UI_BORDER))
	button.add_theme_stylebox_override("hover", _button_style(UI_PRIMARY_HOVER if filled else Color("eee9fa"), UI_PRIMARY_HOVER if filled else UI_BORDER))
	button.add_theme_stylebox_override("pressed", _button_style(UI_PRIMARY_PRESSED if filled else Color("e8e4f4"), UI_PRIMARY_PRESSED if filled else UI_BORDER))
	button.add_theme_stylebox_override("disabled", _button_style(Color("e8e4f4") if filled else Color("f0edf9"), Color("e8e4f4")))
	button.add_theme_color_override("font_color", Color.WHITE if filled else UI_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE if filled else UI_TEXT)
	button.add_theme_color_override("font_pressed_color", Color.WHITE if filled else UI_TEXT)
	button.add_theme_color_override("font_hover_pressed_color", Color.WHITE if filled else UI_TEXT)
	button.add_theme_color_override("font_disabled_color", UI_MUTED_TEXT)
	return button

func _hint_button_label(label_text: String) -> String:
	return "💡  %s" % label_text

func _set_hint_button_text(label_text: String, rewarded_ad: bool = false) -> void:
	_hint.text = _hint_button_label(label_text)
	_hint.set_meta("rewarded_ad", rewarded_ad)

func _apply_tile_text_colors(tile: Button, color: Color) -> void:
	tile.add_theme_color_override("font_color", color)
	tile.add_theme_color_override("font_hover_color", color)
	tile.add_theme_color_override("font_pressed_color", color)
	tile.add_theme_color_override("font_hover_pressed_color", color)
	tile.add_theme_color_override("font_focus_color", color)

func _thicken_label(label: Label, color: Color, outline_size: int) -> void:
	label.add_theme_color_override("font_outline_color", color)
	label.add_theme_constant_override("outline_size", outline_size)

func _thicken_button(button: Button, color: Color, outline_size: int) -> void:
	button.add_theme_color_override("font_outline_color", color)
	button.add_theme_constant_override("outline_size", outline_size)

func _aftermath_label(text_value: String, font_size: int, color: Color, font: Font = null) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _font_fredoka_semibold if font == null else font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if font_size >= 24:
		label.add_theme_color_override("font_outline_color", color)
		label.add_theme_constant_override("outline_size", 1)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label

func _aftermath_button(label_text: String, filled: bool, won: bool = true) -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 56)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", _font_fredoka_semibold)
	button.add_theme_font_size_override("font_size", 18)
	var fill: Color = UI_YELLOW if won else UI_RED
	if filled:
		button.add_theme_stylebox_override("normal", _aftermath_button_style(fill, fill))
		button.add_theme_stylebox_override("hover", _aftermath_button_style(fill.lightened(0.08), fill.lightened(0.08)))
		button.add_theme_stylebox_override("pressed", _aftermath_button_style(fill.darkened(0.08), fill.darkened(0.08)))
		button.add_theme_color_override("font_color", UI_PRIMARY if won else Color.WHITE)
		button.add_theme_color_override("font_hover_color", UI_PRIMARY if won else Color.WHITE)
		button.add_theme_color_override("font_pressed_color", UI_PRIMARY if won else Color.WHITE)
	else:
		button.add_theme_stylebox_override("normal", _aftermath_button_style(Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.16)))
		button.add_theme_stylebox_override("hover", _aftermath_button_style(Color(1, 1, 1, 0.13), Color(1, 1, 1, 0.22)))
		button.add_theme_stylebox_override("pressed", _aftermath_button_style(Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.28)))
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
	return button

func _stat_pill(label_text: String, value_text: String, accent: Color) -> PanelContainer:
	var pill: PanelContainer = PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.add_theme_stylebox_override("panel", _aftermath_inner_style(14))
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	pill.add_child(margin)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 3)
	margin.add_child(stack)
	var value: Label = _aftermath_label(value_text, 24, accent, _font_fredoka_bold)
	value.add_theme_constant_override("outline_size", 0)
	stack.add_child(value)
	var label: Label = _aftermath_label(label_text.to_upper(), 11, Color(1, 1, 1, 0.45), _font_fredoka_semibold)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_constant_override("outline_size", 0)
	stack.add_child(label)
	return pill

func _card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	return style

func _outline_button_style(fill: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = UI_PRIMARY
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

func _life_dot_style(used: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UI_RED if used else Color("e8e4f4")
	style.border_color = UI_RED if used else UI_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	return style

func _tile_style(color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_color = border_color
	style.set_border_width_all(2)
	style.shadow_color = Color(0, 0, 0, 0.07)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	# Button's theme default margins are intended for wide UI buttons. Keeping
	# them here would make ordinary words such as MUSHROOM truncate early.
	style.content_margin_left = 3.0
	style.content_margin_right = 3.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style

func _row_fill(row_length: int) -> Color:
	match row_length:
		1: return UI_MAGENTA
		2: return UI_RED
		3: return UI_TEAL
		4: return Color("ccfaf4")
		5: return UI_YELLOW
		_: return UI_SURFACE

func _row_border(row_length: int) -> Color:
	match row_length:
		1: return UI_MAGENTA
		2: return UI_RED
		3: return UI_TEAL
		4: return UI_TEAL
		5: return UI_YELLOW
		_: return UI_BORDER

func _row_text(row_length: int) -> Color:
	match row_length:
		1: return Color.WHITE
		2: return Color.WHITE
		3: return Color.WHITE
		4: return UI_TEXT
		5: return UI_TEXT
		_: return UI_TEXT

func _category_card_style(row_length: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = _row_fill(row_length)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_color = _row_border(row_length)
	style.set_border_width_all(1)
	return style

func _button_style(color: Color, border_color: Color = UI_BORDER) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.border_color = border_color
	style.set_border_width_all(1)
	return style

func _aftermath_sheet_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UI_PRIMARY
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.border_color = Color(1, 1, 1, 0.08)
	style.set_border_width_all(1)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	return style

func _aftermath_inner_style(radius: int = 20) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.07)
	style.border_color = Color(1, 1, 1, 0.08)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _aftermath_handle_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.22)
	style.set_corner_radius_all(2)
	return style

func _aftermath_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style
