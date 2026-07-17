class_name GameBoard
extends Control

signal request_menu
signal request_new_game
signal request_tutorial_exit(completed: bool)

const ROW_LENGTHS: Array[int] = [1, 2, 3, 4, 5]
const TILE_GAP: float = 6.0
const ROW_BAND_OVERHANG: Vector2 = Vector2(7.0, 3.0)
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
const WRONG_TILE_FILL: Color = Color("fff2ee")
const SELECTION_LIFT: float = 4.0
const SELECTION_MOTION_DURATION: float = 0.14
const WRONG_SHAKE_DURATION: float = 0.58
const WRONG_SHAKE_PEAK: float = 6.0
const WRONG_SHAKE_SETTLE: float = 3.0
const AFTERMATH_REVEAL_DELAY: float = 2.0
const STREAK_POP_DELAY: float = 0.70
const TUTORIAL_HINT_BREAK: float = 1.15
const TUTORIAL_CHECK_BREAK: float = 1.00
const FONT_AXIS_WIDTH: int = 2003072104 # wdth

var _card: PanelContainer
var _message: Label
var _selection: Label
var _mistakes: Label
var _lives_row: HBoxContainer
var _endless_header_hearts: HBoxContainer
var _puzzle_title: Label
var _mode_label: Label
var _pyramid: VBoxContainer
var _check: Button
var _clear: Button
var _hint: Button
var _result: Button
var _share: Button
var _aftermath_layer: Control
var _aftermath_sheet: PanelContainer
var _aftermath_stack: VBoxContainer
var _aftermath_drag_start_y: float = 0.0
var _aftermath_dragging: bool = false
var _aftermath_dismissing: bool = false
var _aftermath_open_tween: Tween
var _aftermath_snap_tween: Tween
var _game_was_running: bool = false
var _aftermath_scheduled: bool = false
var _word_buttons: Dictionary = {}
var _word_tile_wrappers: Dictionary = {}
var _word_order: Array[String] = []
var _hinted_tiles: Dictionary = {}
var _placed_tiles: Dictionary = {}
var _category_cards: Dictionary = {}
var _pyramid_rows: Dictionary = {}
var _pyramid_row_wrappers: Dictionary = {}
var _action_buttons: Array[Button] = []
var _animating_row: int = -1
var _is_placing: bool = false
var _displayed_selection: Array[String] = []
var _tile_motion_tweens: Dictionary = {}
var _row_reveal_tween: Tween
var _row_animation_ghosts: Array[Control] = []
var _pyramid_shake_tween: Tween
var _pyramid_shake_origin_x: float = 0.0
var _wrong_guess_active: bool = false
var _wrong_guess_words: Array[String] = []
var _font_fredoka_semibold: FontVariation
var _font_fredoka_condensed: FontVariation
var _font_fredoka_bold: FontVariation
var _font_dm_sans_semibold: FontVariation
var _tutorial_stage: int = 0
var _tutorial_finishing: bool = false
var _tutorial_spotlight: ColorRect
var _tutorial_paused: bool = false
var _tutorial_pause_id: int = 0
var _tutorial_focus_tweens: Dictionary = {}

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
	# Both nodes are autoloads, so this connection outlives individual boards.
	# Reopening the board must not connect the same callable a second time.
	if not AdManager.rewarded_hint_earned.is_connected(GameState.grant_rewarded_hint):
		AdManager.rewarded_hint_earned.connect(GameState.grant_rewarded_hint)
	if not AdManager.rewarded_heart_earned.is_connected(_on_rewarded_heart_earned):
		AdManager.rewarded_heart_earned.connect(_on_rewarded_heart_earned)
	AdManager.rewarded_ad_unavailable.connect(_on_rewarded_ad_unavailable)
	GameState.puzzle_pool_completed.connect(_on_puzzle_pool_completed)
	if not GameState.tutorial_completed.is_connected(_on_tutorial_completed):
		GameState.tutorial_completed.connect(_on_tutorial_completed)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		GameState.check_selection()
		get_viewport().set_input_as_handled()

func _setup_font_variations() -> void:
	_font_fredoka_semibold = _font_variation(FONT_FREDOKA, 600, 0.30)
	_font_fredoka_condensed = _font_variation(FONT_FREDOKA, 600, 0.30, 85)
	_font_fredoka_bold = _font_variation(FONT_FREDOKA, 700, 0.48)
	_font_dm_sans_semibold = _font_variation(FONT_DM_SANS, 600, 0.12)

func _font_variation(base_font: Font, weight: int, embolden: float, width: int = 100) -> FontVariation:
	var font: FontVariation = FontVariation.new()
	font.base_font = base_font
	var variations: Dictionary = {"wght": weight}
	if width != 100:
		variations[FONT_AXIS_WIDTH] = width
	font.variation_opentype = variations
	font.variation_embolden = embolden
	return font

func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = UI_BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var page_margin: MarginContainer = MarginContainer.new()
	page_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_margin.add_theme_constant_override("margin_left", 8)
	page_margin.add_theme_constant_override("margin_right", 8)
	page_margin.add_theme_constant_override("margin_top", 17)
	page_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(page_margin)
	var page: VBoxContainer = VBoxContainer.new()
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 7)
	page_margin.add_child(page)
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_theme_constant_override("separation", 10)
	page.add_child(top_bar)
	var back: Button = Button.new()
	back.text = SaveManager.text("tutorial_skip") if GameState.game_mode == GameState.TUTORIAL_MODE else "< " + SaveManager.text("back")
	back.custom_minimum_size = Vector2(73, 34)
	back.add_theme_font_override("font", _font_dm_sans_semibold)
	back.add_theme_font_size_override("font_size", 13)
	back.add_theme_stylebox_override("normal", _outline_button_style(UI_SURFACE))
	back.add_theme_stylebox_override("hover", _outline_button_style(UI_SURFACE_TINT))
	back.add_theme_color_override("font_color", UI_TEXT)
	back.pressed.connect(func() -> void:
		if GameState.game_mode == GameState.TUTORIAL_MODE:
			request_tutorial_exit.emit(false)
		else:
			request_menu.emit()
	)
	top_bar.add_child(back)
	var title_stack: VBoxContainer = VBoxContainer.new()
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title_stack)
	var game_title: Label = Label.new()
	game_title.text = "Word Pyramid"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_font_override("font", _font_fredoka_bold)
	game_title.add_theme_font_size_override("font_size", 21)
	game_title.add_theme_color_override("font_color", UI_TEXT)
	title_stack.add_child(game_title)
	_mode_label = Label.new()
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.add_theme_font_override("font", FONT_DM_SANS)
	_mode_label.add_theme_font_size_override("font_size", 10)
	_mode_label.add_theme_color_override("font_color", UI_MUTED_TEXT)
	title_stack.add_child(_mode_label)
	_endless_header_hearts = HBoxContainer.new()
	_endless_header_hearts.custom_minimum_size = Vector2(73, 34)
	_endless_header_hearts.alignment = BoxContainer.ALIGNMENT_END
	_endless_header_hearts.add_theme_constant_override("separation", 3)
	top_bar.add_child(_endless_header_hearts)
	_puzzle_title = Label.new()
	_puzzle_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_puzzle_title.add_theme_font_override("font", _font_fredoka_bold)
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
	content.add_theme_constant_override("separation", 7)
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
	instructions.add_theme_font_size_override("font_size", 12)
	instructions.add_theme_color_override("font_color", UI_MUTED_TEXT)
	instructions.pressed.connect(_show_instructions)
	instructions.visible = GameState.game_mode != GameState.TUTORIAL_MODE
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
	_message.add_theme_font_size_override("font_size", 13)
	_message.add_theme_color_override("font_color", UI_MUTED_TEXT)
	content.add_child(_message)
	if GameState.game_mode == GameState.TUTORIAL_MODE:
		_message.custom_minimum_size = Vector2(0, 64)
		_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_message.add_theme_font_override("font", _font_fredoka_semibold)
		_message.add_theme_font_size_override("font_size", 18)
		_message.add_theme_color_override("font_color", UI_TEXT)
		_message.add_theme_stylebox_override("normal", _tutorial_guide_style())
		_message.z_index = 22
	_selection = Label.new()
	_selection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection.add_theme_font_override("font", FONT_DM_SANS)
	_selection.add_theme_color_override("font_color", UI_MUTED_TEXT)
	_selection.add_theme_font_size_override("font_size", 12)
	content.add_child(_selection)
	_pyramid = VBoxContainer.new()
	_pyramid.alignment = BoxContainer.ALIGNMENT_BEGIN
	_pyramid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pyramid.add_theme_constant_override("separation", TILE_GAP)
	content.add_child(_pyramid)
	_lives_row = HBoxContainer.new()
	_lives_row.custom_minimum_size = Vector2(0, 14)
	_lives_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_lives_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_lives_row.add_theme_constant_override("separation", 7)
	content.add_child(_lives_row)
	var action_dock: PanelContainer = PanelContainer.new()
	action_dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_dock.add_theme_stylebox_override("panel", _action_dock_style())
	content.add_child(action_dock)
	var dock_margin: MarginContainer = MarginContainer.new()
	dock_margin.add_theme_constant_override("margin_left", 10)
	dock_margin.add_theme_constant_override("margin_right", 10)
	dock_margin.add_theme_constant_override("margin_top", 8)
	dock_margin.add_theme_constant_override("margin_bottom", 10)
	action_dock.add_child(dock_margin)
	var dock_content: VBoxContainer = VBoxContainer.new()
	dock_content.add_theme_constant_override("separation", 7)
	dock_margin.add_child(dock_content)
	_mistakes = Label.new()
	_mistakes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mistakes.add_theme_font_override("font", FONT_DM_SANS)
	_mistakes.add_theme_font_size_override("font_size", 12)
	_mistakes.add_theme_color_override("font_color", UI_MUTED_TEXT)
	dock_content.add_child(_mistakes)
	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 10)
	dock_content.add_child(action_row)
	_hint = _action_button(_hint_button_label(SaveManager.text("hint_count") % 2))
	_hint.pressed.connect(_on_hint_pressed)
	action_row.add_child(_hint)
	_clear = _action_button(SaveManager.text("clear"))
	_clear.pressed.connect(GameState.clear_selection)
	_clear.visible = false
	action_row.add_child(_clear)
	_check = _action_button(SaveManager.text("check"), true)
	_check.pressed.connect(_on_check_pressed)
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
	if GameState.game_mode == GameState.TUTORIAL_MODE:
		_tutorial_spotlight = ColorRect.new()
		_tutorial_spotlight.color = Color(0.08, 0.035, 0.22, 0.16)
		_tutorial_spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tutorial_spotlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_tutorial_spotlight.z_index = 20
		add_child(_tutorial_spotlight)

func refresh() -> void:
	if not is_node_ready():
		return
	var is_daily: bool = GameState.game_mode == "daily"
	var is_tutorial: bool = GameState.game_mode == GameState.TUTORIAL_MODE
	_selection.visible = not is_tutorial
	_message.text = SaveManager.text("tutorial_select_group") if is_tutorial else (SaveManager.text("daily_message") if is_daily else SaveManager.text("unlimited_message"))
	_mode_label.text = SaveManager.text("tutorial_mode_label").to_upper() if is_tutorial else (SaveManager.text("daily_challenge_label").to_upper() if is_daily else "∞ %s" % SaveManager.text("unlimited_mode_label").to_upper())
	_puzzle_title.text = str(GameState.puzzle.get("title", SaveManager.text("board_title")))
	_build_pyramid()
	_update_mistakes()
	_update_selection(GameState.selected_words)
	if GameState.is_finished:
		_on_game_finished(GameState.completed_won, str(GameState.puzzle.get("top_word", "")))
	else:
		_game_was_running = true
		_show_play_actions()
		if is_tutorial:
			_tutorial_stage = 0
			_apply_tutorial_stage()

func _build_pyramid() -> void:
	for tween_value: Variant in _tile_motion_tweens.values():
		var active_tween: Tween = tween_value as Tween
		if active_tween != null and active_tween.is_running():
			active_tween.kill()
	_tile_motion_tweens.clear()
	# Correct-row animations rebuild the pyramid in the same frame. Free the old
	# rows immediately so the VBox never lays out old and new copies together for
	# one frame, which showed up as intermittent jumping/duplicated words.
	for child: Node in _pyramid.get_children():
		child.free()
	_word_buttons.clear()
	_word_tile_wrappers.clear()
	_hinted_tiles.clear()
	_placed_tiles.clear()
	_category_cards.clear()
	_pyramid_rows.clear()
	_pyramid_row_wrappers.clear()
	var remaining_words: Array[String] = _get_stable_word_order()
	# Rows are built from the top down, whereas the first hint belongs in the
	# bottom row. Reserve every hinted word so an earlier row cannot consume it
	# before its correct row is created.
	var reserved_hint_words: Array[String] = []
	for hinted_row_length: int in ROW_LENGTHS:
		for reserved_word: String in GameState.get_hint_words_for_row(hinted_row_length):
			if remaining_words.has(reserved_word):
				reserved_hint_words.append(reserved_word)
	for row_length: int in ROW_LENGTHS:
		var row_wrapper: Control = Control.new()
		row_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row_wrapper.set_meta("row_length", row_length)
		_pyramid.add_child(row_wrapper)
		_pyramid_row_wrappers[row_length] = row_wrapper
		var row_band: Panel = Panel.new()
		row_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row_band.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row_band.offset_left = -ROW_BAND_OVERHANG.x
		row_band.offset_right = ROW_BAND_OVERHANG.x
		row_band.offset_top = -ROW_BAND_OVERHANG.y
		row_band.offset_bottom = ROW_BAND_OVERHANG.y
		row_band.add_theme_stylebox_override("panel", _row_band_style(row_length))
		row_wrapper.add_child(row_band)
		var row: HBoxContainer = HBoxContainer.new()
		row.set_meta("row_length", row_length)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", TILE_GAP)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row_wrapper.add_child(row)
		_pyramid_rows[row_length] = row
		var solved_group: Dictionary = _solved_group_for_row(row_length)
		if not solved_group.is_empty():
			if row_length == _animating_row:
				var placed_row: Array[Label] = []
				var locked_hint_words: Array[String] = GameState.get_hint_words_for_row(row_length)
				for solved_word: String in GameState._to_string_array(solved_group.get("words", [])):
					var placed_tile: Label = _create_placed_tile(solved_word, row_length)
					# The hint was already locked in this row, so keep it visible
					# while the remaining blocks finish their placement animation.
					placed_tile.modulate.a = 1.0 if locked_hint_words.has(solved_word) else 0.0
					row.add_child(placed_tile)
					placed_row.append(placed_tile)
				_placed_tiles[row_length] = placed_row
			else:
				var category_card: PanelContainer = _create_category_card(solved_group)
				row.add_child(category_card)
				_category_cards[row_length] = category_card
			continue
		for hinted_word: String in GameState.get_hint_words_for_row(row_length):
			if remaining_words.has(hinted_word):
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
			# Keep layout sizing on a stable wrapper. The button can then lift by a
			# few pixels without asking the row container to resize or move anything.
			var tile_wrapper: Control = Control.new()
			tile_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile_wrapper.set_meta("row_length", row_length)
			row.add_child(tile_wrapper)
			tile_wrapper.add_child(tile)
			tile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			tile.set_meta("row_length", row_length)
			_word_buttons[word] = tile
			_word_tile_wrappers[word] = tile_wrapper
	_layout_for_width()
	_on_selection_changed(GameState.selected_words)

func _create_word_tile(word: String) -> Button:
	var tile: Button = Button.new()
	tile.set_meta(SoundManager.SKIP_UI_CLICK_SOUND_META, true)
	tile.text = word
	tile.toggle_mode = true
	tile.autowrap_mode = TextServer.AUTOWRAP_OFF
	tile.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tile.alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.tooltip_text = SaveManager.text("select_tooltip") % word
	tile.add_theme_font_override("font", _tile_font(word))
	tile.add_theme_color_override("font_color", UI_TEXT)
	tile.add_theme_font_size_override("font_size", 13)
	_apply_word_tile_visual(tile, false)
	tile.pressed.connect(_on_word_tile_pressed.bind(tile, word))
	return tile

func _on_word_tile_pressed(tile: Button, word: String) -> void:
	GameState.toggle_word(word)
	# Toggle-mode buttons change their local pressed state before this callback.
	# If GameState rejects an over-limit selection, immediately restore the
	# visual state from the authoritative selection array.
	if is_instance_valid(tile):
		tile.set_pressed_no_signal(GameState.selected_words.has(word))

func _create_hinted_tile(word: String, row_length: int) -> Button:
	var tile: Button = Button.new()
	tile.set_meta(SoundManager.SKIP_UI_CLICK_SOUND_META, true)
	tile.text = word
	tile.disabled = true
	tile.autowrap_mode = TextServer.AUTOWRAP_OFF
	tile.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tile.alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_theme_font_override("font", _tile_font(word))
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
	tile.add_theme_font_override("font", _tile_font(word))
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
	var card_width: float = clampf(size.x - 16.0, 304.0, 620.0)
	_card.custom_minimum_size = Vector2(card_width, 0.0)
	var tile_size: float = clampf((card_width - TILE_GAP * 4.0) / 5.0, 48.0, 104.0)
	# The five-word row already consumes the available width on phones. Grow the
	# pyramid vertically instead, while every tier keeps the same block height
	# and centered 1-2-3-4-5 geometry.
	var pyramid_height: float = clampf(size.y - 365.0, 290.0, 480.0)
	var tile_height: float = clampf((pyramid_height - TILE_GAP * 4.0) / 5.0, 54.0, 92.0)
	for word: String in _word_buttons:
		var tile: Button = _word_buttons[word]
		var tile_wrapper: Control = _word_tile_wrappers.get(word) as Control
		if tile_wrapper != null:
			tile_wrapper.custom_minimum_size = Vector2(tile_size, tile_height)
			tile_wrapper.size = Vector2(tile_size, tile_height)
		tile.custom_minimum_size = Vector2(tile_size, tile_height)
		tile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tile.position.y = -SELECTION_LIFT if GameState.selected_words.has(word) else 0.0
		tile.set_meta("selection_lifted", GameState.selected_words.has(word))
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
	for row_length: int in _pyramid_row_wrappers:
		var row_wrapper: Control = _pyramid_row_wrappers[row_length]
		var row_width: float = tile_size * row_length + TILE_GAP * float(row_length - 1)
		row_wrapper.custom_minimum_size = Vector2(row_width, tile_height)
		row_wrapper.size = Vector2(row_width, tile_height)
	# The dock has 10 px inner margins on both sides and a 10 px button gap.
	var action_width: float = clampf((card_width - 30.0) / 2.0, 136.0, 260.0)
	for action_button: Button in _action_buttons:
		action_button.custom_minimum_size = Vector2(action_width, 52.0)
		action_button.add_theme_font_size_override("font_size", 16)
	_hint.custom_minimum_size = Vector2(82.0, 52.0)
	_hint.add_theme_font_size_override("font_size", 14)
	_check.custom_minimum_size = Vector2(max(card_width - 112.0, 180.0), 52.0)
	_check.add_theme_font_size_override("font_size", 17)

func _tile_font_size(word: String, tile_size: float) -> int:
	# Measure the real rendered width instead of estimating from character count.
	# This keeps long compounds as large as possible without arbitrary wrapping
	# or clipping them halfway through a word.
	var available_width: float = maxf(tile_size - 8.0, 24.0)
	var font: FontVariation = _tile_font(word)
	for candidate_size: int in range(15, 7, -1):
		if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, candidate_size).x <= available_width:
			return candidate_size
	return 7

func _tile_font(word: String) -> FontVariation:
	return _font_fredoka_condensed if word.length() >= 10 else _font_fredoka_semibold

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
	if GameState.game_mode == GameState.TUTORIAL_MODE:
		_mistakes.visible = false
		_lives_row.visible = false
		return
	_mistakes.visible = true
	_lives_row.visible = true
	var maximum: int = int(SaveManager.settings.get("attempts", 4))
	_mistakes.text = SaveManager.text("mistakes_left") % [GameState.attempts_left, maximum]
	_update_lives(maximum - GameState.attempts_left, maximum)
	_update_endless_header_hearts()

func _update_endless_header_hearts() -> void:
	if _endless_header_hearts == null:
		return
	for child: Node in _endless_header_hearts.get_children():
		child.queue_free()
	if GameState.game_mode != "unlimited":
		_add_header_confetti()
		return
	var hearts: int = SaveManager.get_endless_hearts()
	for index: int in range(SaveManager.ENDLESS_DAILY_HEARTS):
		var heart: Label = Label.new()
		heart.text = "♥"
		heart.add_theme_font_override("font", _font_fredoka_bold)
		heart.add_theme_font_size_override("font_size", 18)
		heart.add_theme_color_override("font_color", UI_RED if index < hearts else Color("c9c3da"))
		heart.add_theme_color_override("font_outline_color", UI_PRIMARY)
		heart.add_theme_constant_override("outline_size", 1)
		heart.modulate.a = 1.0 if index < hearts else 0.42
		_endless_header_hearts.add_child(heart)

func _add_header_confetti() -> void:
	var symbols: Array[String] = ["✦", "●", "▲"]
	var colors: Array[Color] = [UI_TEAL, UI_YELLOW, Color("ff7896")]
	for index: int in symbols.size():
		var accent: Label = Label.new()
		accent.text = symbols[index]
		accent.add_theme_font_override("font", _font_fredoka_bold)
		accent.add_theme_font_size_override("font_size", 13 + index)
		accent.add_theme_color_override("font_color", colors[index])
		accent.rotation_degrees = -10.0 + 10.0 * index
		_endless_header_hearts.add_child(accent)

func _update_lives(used: int, maximum: int) -> void:
	if _lives_row == null:
		return
	for child: Node in _lives_row.get_children():
		child.queue_free()
	for index: int in range(maximum):
		var dot: Panel = Panel.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var is_used: bool = index < used
		dot.add_theme_stylebox_override("panel", _life_dot_style(is_used))
		_lives_row.add_child(dot)

func _update_selection(selection: Array[String]) -> void:
	_selection.text = SaveManager.text("selected") % " · ".join(selection) if not selection.is_empty() else SaveManager.text("select_up_to") % GameState.get_selection_limit()

func _on_game_started(_puzzle_title: String, _attempts_left: int) -> void:
	refresh()

func _on_selection_changed(selection: Array[String]) -> void:
	var is_at_limit: bool = selection.size() >= GameState.get_selection_limit()
	for word: String in _word_buttons:
		var tile: Button = _word_buttons[word]
		var selected: bool = selection.has(word)
		var was_selected: bool = _displayed_selection.has(word)
		var showing_wrong: bool = _wrong_guess_active and _wrong_guess_words.has(word)
		var tutorial_blocked: bool = GameState.game_mode == GameState.TUTORIAL_MODE and (_tutorial_paused or not GameState.is_tutorial_word_allowed(word))
		var selection_blocked: bool = (is_at_limit and not selected) or tutorial_blocked
		tile.button_pressed = selected
		# Block excess taps at the Button level so they cannot animate, focus, or
		# emit a pressed signal. The disabled overrides below keep blocked tiles
		# visually identical to ordinary unselected tiles.
		tile.disabled = GameState.is_finished or selection_blocked
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE if _is_placing else Control.MOUSE_FILTER_STOP
		tile.focus_mode = Control.FOCUS_NONE if _is_placing or selection_blocked else Control.FOCUS_ALL
		_apply_word_tile_visual(tile, selected, showing_wrong)
		if GameState.game_mode == GameState.TUTORIAL_MODE and not _tutorial_paused and GameState.is_tutorial_word_allowed(word) and not selected:
			tile.add_theme_stylebox_override("normal", _tutorial_tile_style())
			tile.add_theme_stylebox_override("hover", _tutorial_tile_style())
		_set_tile_lift(tile, false if showing_wrong else selected, was_selected != selected and not _is_placing)
	_displayed_selection.assign(selection)
	_clear.disabled = selection.is_empty() or GameState.is_finished
	_check.disabled = _tutorial_paused or not GameState.can_check_selection()
	_update_selection(selection)
	if GameState.game_mode == GameState.TUTORIAL_MODE and not _tutorial_paused:
		_update_tutorial_selection_message()

func _on_group_solved(group: Dictionary) -> void:
	var row_length: int = int(group.get("size", 0))
	var swap: Dictionary = _capture_row_swap(row_length)
	_cancel_row_reveal_animation()
	_apply_swap_to_word_order(swap)
	_animating_row = row_length
	_is_placing = true
	_build_pyramid()
	if _placed_tiles.has(row_length):
		_animate_row_swap(swap)
		_row_reveal_tween = create_tween()
		_row_reveal_tween.tween_interval(0.60)
		_row_reveal_tween.tween_callback(func() -> void: _show_placed_row(row_length))
		_row_reveal_tween.tween_interval(0.24)
		_row_reveal_tween.tween_callback(func() -> void: _activate_category_card(row_length, group))
	if GameState.game_mode == GameState.TUTORIAL_MODE:
		call_deferred("_advance_tutorial_after_group", row_length)

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
	row.add_child(category_card)
	_category_cards[row_length] = category_card
	_animating_row = -1
	_is_placing = false
	_row_reveal_tween = null
	_layout_for_width()
	var tween: Tween = create_tween()
	tween.tween_property(category_card, "modulate:a", 1.0, 0.20)
	_on_selection_changed(GameState.selected_words)

func _show_placed_row(row_length: int) -> void:
	if not _placed_tiles.has(row_length):
		return
	for placed_tile: Label in _placed_tiles[row_length]:
		placed_tile.modulate.a = 1.0

func _cancel_row_reveal_animation() -> void:
	if _row_reveal_tween != null and _row_reveal_tween.is_running():
		_row_reveal_tween.kill()
	_row_reveal_tween = null
	for ghost: Control in _row_animation_ghosts:
		if is_instance_valid(ghost):
			ghost.free()
	_row_animation_ghosts.clear()

func _capture_row_swap(row_length: int) -> Dictionary:
	var selected: Array[Dictionary] = []
	var targets: Array[Dictionary] = []
	for word: String in GameState.selected_words:
		if _word_buttons.has(word):
			var tile: Button = _word_buttons[word]
			selected.append({"word": word, "point": _to_board_point(tile.get_global_rect().get_center()), "size": tile.size})
	for word: String in _word_buttons:
		var target_tile: Button = _word_buttons[word]
		if int(target_tile.get_meta("row_length", 0)) == row_length:
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
	ghost.add_theme_font_override("font", _tile_font(word))
	ghost.add_theme_font_size_override("font_size", _tile_font_size(word, block_size.x))
	ghost.add_theme_color_override("font_color", UI_TEXT)
	ghost.add_theme_stylebox_override("normal", _tile_style(fill_color, border_color))
	ghost.z_index = 10
	add_child(ghost)
	_row_animation_ghosts.append(ghost)
	# Bind the tween to its visual copy. If a second solved row starts, freeing
	# the old ghost also stops its tween instead of letting stale words fly over
	# the newly rebuilt board.
	var tween: Tween = ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "position", destination - block_size * 0.5, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.12).set_delay(0.40)
	tween.set_parallel(false)
	tween.tween_callback(_finish_fly_ghost.bind(ghost))

func _finish_fly_ghost(ghost: Control) -> void:
	_row_animation_ghosts.erase(ghost)
	if is_instance_valid(ghost):
		ghost.queue_free()

func _to_board_point(global_point: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * global_point

func _on_guess_failed(_left: int) -> void:
	_update_mistakes()
	_message.text = SaveManager.text("guess_failed")
	_highlight_incorrect_selection()

func _on_repeated_guess_attempted() -> void:
	_message.text = SaveManager.text("repeated_guess")

func _on_guess_feedback(text: String) -> void:
	_message.text = text

func _highlight_incorrect_selection() -> void:
	_wrong_guess_words.assign(GameState.selected_words)
	_wrong_guess_active = true
	for word: String in _wrong_guess_words:
		if _word_buttons.has(word):
			var tile: Button = _word_buttons[word]
			_apply_word_tile_visual(tile, true, true)
			_set_tile_lift(tile, false, true)
	_start_wrong_guess_shake()

func _start_wrong_guess_shake() -> void:
	if not is_instance_valid(_pyramid):
		_finish_wrong_guess_motion()
		return
	if _pyramid_shake_tween != null and _pyramid_shake_tween.is_running():
		_pyramid_shake_tween.kill()
		_pyramid.position.x = _pyramid_shake_origin_x
	_pyramid_shake_origin_x = _pyramid.position.x
	var segment_duration: float = WRONG_SHAKE_DURATION / 5.0
	_pyramid_shake_tween = create_tween()
	_pyramid_shake_tween.tween_property(_pyramid, "position:x", _pyramid_shake_origin_x - WRONG_SHAKE_PEAK, segment_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_pyramid_shake_tween.tween_property(_pyramid, "position:x", _pyramid_shake_origin_x + WRONG_SHAKE_PEAK, segment_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_pyramid_shake_tween.tween_property(_pyramid, "position:x", _pyramid_shake_origin_x - WRONG_SHAKE_SETTLE, segment_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_pyramid_shake_tween.tween_property(_pyramid, "position:x", _pyramid_shake_origin_x + WRONG_SHAKE_SETTLE, segment_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_pyramid_shake_tween.tween_property(_pyramid, "position:x", _pyramid_shake_origin_x, segment_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_pyramid_shake_tween.tween_callback(_finish_wrong_guess_motion)

func _finish_wrong_guess_motion() -> void:
	if is_instance_valid(_pyramid):
		_pyramid.position.x = _pyramid_shake_origin_x
	_wrong_guess_active = false
	_wrong_guess_words.clear()
	for word: String in _word_buttons:
		var tile: Button = _word_buttons[word]
		var selected: bool = GameState.selected_words.has(word)
		_apply_word_tile_visual(tile, selected)
		_set_tile_lift(tile, selected, true)

func _set_tile_lift(tile: Button, lifted: bool, animate: bool) -> void:
	if not is_instance_valid(tile):
		return
	var tween_key: int = tile.get_instance_id()
	var active_tween: Tween = _tile_motion_tweens.get(tween_key) as Tween
	if active_tween != null and active_tween.is_running():
		active_tween.kill()
	# Tiles fill a stable wrapper whose resting offset is always zero. Do not
	# derive that rest position from the current animated position: a wrong-guess
	# animation can interrupt the selection tween halfway and otherwise turn that
	# temporary offset into the tile's new baseline.
	var target_y: float = -SELECTION_LIFT if lifted else 0.0
	tile.set_meta("selection_lifted", lifted)
	if not animate or is_equal_approx(tile.position.y, target_y):
		tile.position.y = target_y
		_tile_motion_tweens.erase(tween_key)
		return
	var tween: Tween = create_tween()
	_tile_motion_tweens[tween_key] = tween
	tween.tween_property(tile, "position:y", target_y, SELECTION_MOTION_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void: _tile_motion_tweens.erase(tween_key))

func _apply_word_tile_visual(tile: Button, selected: bool, wrong: bool = false) -> void:
	var style: StyleBoxFlat
	var text_color: Color
	if wrong:
		style = _tile_style(WRONG_TILE_FILL, UI_RED)
		text_color = UI_RED
	elif selected:
		style = _selected_tile_style()
		text_color = Color.WHITE
	else:
		style = _tile_style(UI_SURFACE, UI_BORDER)
		text_color = UI_TEXT
	tile.add_theme_stylebox_override("normal", style)
	tile.add_theme_stylebox_override("pressed", style)
	tile.add_theme_stylebox_override("hover_pressed", style)
	tile.add_theme_stylebox_override("disabled", style)
	tile.add_theme_stylebox_override("hover", style if selected or wrong else _tile_style(UI_SURFACE, Color("a89dd4")))
	_apply_tile_text_colors(tile, text_color)
	tile.add_theme_color_override("font_disabled_color", text_color)

func _selected_tile_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _tile_style(SELECTED_FILL, SELECTED_BORDER)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.102, 0.039, 0.369, 0.32)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 8)
	return style

func _tutorial_tile_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _tile_style(Color("fff8dc"), UI_MAGENTA)
	style.set_border_width_all(3)
	style.shadow_color = Color(0.725, 0.224, 1.0, 0.18)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style

func _tutorial_guide_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("fff8dc")
	style.border_color = Color("eadb89")
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.10, 0.04, 0.37, 0.12)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style

func _on_game_finished(won: bool, top_word: String) -> void:
	if _aftermath_scheduled or is_instance_valid(_aftermath_layer):
		return
	var should_wait_for_board: bool = _game_was_running
	_game_was_running = false
	_aftermath_scheduled = true
	for tile: Button in _word_buttons.values():
		tile.disabled = true
	_hint.visible = false
	_check.visible = false
	_result.visible = false
	_share.visible = false
	_message.text = SaveManager.text("game_complete") % top_word if won else SaveManager.text("game_failed")
	_update_mistakes()
	if should_wait_for_board:
		await get_tree().create_timer(AFTERMATH_REVEAL_DELAY).timeout
		if not is_inside_tree() or not GameState.is_finished:
			_aftermath_scheduled = false
			return
	_show_result_actions()
	_aftermath_scheduled = false
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
	_aftermath_scheduled = false
	_show_aftermath(GameState.completed_won)

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
		# Recover an existing overlay if an interrupted gesture or animation left
		# its full-screen input layer active while the sheet itself was offscreen.
		if not _aftermath_dismissing:
			_aftermath_layer.modulate.a = 1.0
			if is_instance_valid(_aftermath_stack):
				_aftermath_stack.position.y = 0.0
		return
	var correct: int = max(GameState.result_correct_count, 0)
	var total: int = max(GameState.result_total_count(), correct)
	var is_endless: bool = GameState.game_mode == "unlimited"
	var is_endless_loss: bool = is_endless and not won
	var max_attempts: int = int(SaveManager.settings.get("attempts", 4))
	var mistakes: int = clampi(max_attempts - GameState.attempts_left, 0, max_attempts)
	var layer: Control = Control.new()
	layer.name = "AftermathLayer"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.modulate.a = 0.0
	add_child(layer)
	_aftermath_layer = layer

	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.102, 0.039, 0.369, 0.45)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.gui_input.connect(_on_aftermath_backdrop_input)
	layer.add_child(backdrop)

	var stack: VBoxContainer = VBoxContainer.new()
	_aftermath_stack = stack
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(stack)
	var top_space: Control = Control.new()
	top_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(top_space)

	var sheet: PanelContainer = PanelContainer.new()
	_aftermath_sheet = sheet
	sheet.add_theme_stylebox_override("panel", _aftermath_sheet_style(won))
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.gui_input.connect(_on_aftermath_drag_input)
	stack.add_child(sheet)
	var sheet_content: VBoxContainer = VBoxContainer.new()
	sheet_content.add_theme_constant_override("separation", 0)
	sheet.add_child(sheet_content)
	_add_aftermath_accent(sheet_content, won)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 24)
	sheet_content.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var handle: Panel = Panel.new()
	handle.custom_minimum_size = Vector2(40, 4)
	handle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	handle.add_theme_stylebox_override("panel", _aftermath_handle_style())
	content.add_child(handle)

	var emoji_text: String = "🎉" if won else ("💀" if is_endless_loss else "✕")
	var emoji: Label = _aftermath_label(emoji_text, 34, UI_YELLOW if won else UI_RED)
	content.add_child(emoji)
	var title: Label = _aftermath_label(SaveManager.text("aftermath_win_title") if won else SaveManager.text("aftermath_loss_title"), 28, UI_YELLOW if won else UI_RED)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(title)
	var subtitle_text: String
	if won:
		subtitle_text = SaveManager.text("aftermath_flawless") if mistakes == 0 else SaveManager.text("aftermath_solved_mistakes") % mistakes
	elif is_endless_loss:
		subtitle_text = SaveManager.text("aftermath_endless_better_luck")
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
	streak_margin.add_theme_constant_override("margin_top", 14)
	streak_margin.add_theme_constant_override("margin_bottom", 14)
	streak_panel.add_child(streak_margin)
	var streak_box: VBoxContainer = VBoxContainer.new()
	streak_box.alignment = BoxContainer.ALIGNMENT_CENTER
	streak_box.add_theme_constant_override("separation", 4)
	streak_margin.add_child(streak_box)
	var has_daily_streak: bool = GameState.game_mode == "daily"
	var play_streak_animation: bool = has_daily_streak and SaveManager.consume_daily_streak_animation(GameState.daily_date)
	var flame_text: String = "🔥" if has_daily_streak else ""
	var flame: Label = _aftermath_label(flame_text, 44, Color.WHITE)
	flame.visible = has_daily_streak
	streak_box.add_child(flame)
	var losing_heart: Label = null
	if is_endless:
		var aftermath_hearts: HBoxContainer = HBoxContainer.new()
		aftermath_hearts.alignment = BoxContainer.ALIGNMENT_CENTER
		aftermath_hearts.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		aftermath_hearts.add_theme_constant_override("separation", 12)
		streak_box.add_child(aftermath_hearts)
		var current_hearts: int = SaveManager.get_endless_hearts()
		for index: int in range(SaveManager.ENDLESS_DAILY_HEARTS):
			var heart: Label = _aftermath_label("♥", 34, UI_RED if index < current_hearts else Color("62578f"), _font_fredoka_bold)
			heart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			heart.add_theme_color_override("font_outline_color", Color("090321"))
			heart.add_theme_constant_override("outline_size", 2)
			heart.modulate.a = 1.0 if index < current_hearts else 0.30
			if is_endless_loss and index == current_hearts:
				heart.add_theme_color_override("font_color", UI_RED)
				heart.modulate.a = 1.0
				losing_heart = heart
			aftermath_hearts.add_child(heart)
	var streak_to: int = SaveManager.get_daily_streak(GameState.daily_date) if has_daily_streak else 0
	var streak_from: int = max(streak_to - 1, 0) if won and has_daily_streak else SaveManager.get_daily_streak_before(GameState.daily_date) if has_daily_streak else 0
	var visible_streak: int = streak_from if play_streak_animation or not won else streak_to
	var heart_count: int = SaveManager.get_endless_hearts() if is_endless else 0
	var endless_count_text: String = SaveManager.text("endless_hearts_remaining") % heart_count if heart_count > 0 else SaveManager.text("endless_out_of_hearts")
	var streak_number: Label = _aftermath_label(str(visible_streak) if has_daily_streak else endless_count_text, 56 if has_daily_streak else 18, UI_YELLOW if has_daily_streak else Color.WHITE)
	streak_box.add_child(streak_number)
	var streak_caption_text: String = SaveManager.text("aftermath_results") if has_daily_streak else SaveManager.endless_reset_countdown_text()
	if has_daily_streak:
		var visible_caption_streak: int = streak_from if play_streak_animation else streak_to
		streak_caption_text = SaveManager.text("aftermath_streak_current") % visible_caption_streak if won else SaveManager.text("aftermath_streak_lost")
	var streak_caption: Label = _aftermath_label(streak_caption_text, 13, Color(1, 1, 1, 0.66), _font_fredoka_semibold)
	streak_box.add_child(streak_caption)
	var crack_overlay: Control = Control.new()
	crack_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crack_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	streak_panel.add_child(crack_overlay)
	var streak_crack: ColorRect = ColorRect.new()
	streak_crack.color = UI_RED
	streak_crack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	streak_crack.visible = false
	crack_overlay.add_child(streak_crack)

	var stats_row: HBoxContainer = HBoxContainer.new()
	stats_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.add_theme_constant_override("separation", 10)
	content.add_child(stats_row)
	stats_row.visible = not is_endless_loss
	stats_row.add_child(_stat_pill(SaveManager.text("stat_mistakes"), str(mistakes), UI_YELLOW if mistakes == 0 else Color("ff8066")))
	stats_row.add_child(_stat_pill(SaveManager.text("stat_groups"), "%d / 4" % clampi(GameState.solved_groups.size(), 0, 4), UI_TEAL))
	stats_row.add_child(_stat_pill(SaveManager.text("stat_hints_used"), str(GameState.hints_used), UI_MAGENTA))

	var primary_button: Button
	if is_endless:
		if heart_count > 0:
			primary_button = _aftermath_button(SaveManager.text("endless_new_puzzle"), true, won)
			primary_button.pressed.connect(_on_endless_next_puzzle_pressed)
		elif SaveManager.can_claim_rewarded_endless_heart():
			primary_button = _aftermath_button(SaveManager.text("endless_watch_ad"), true, false)
			primary_button.pressed.connect(AdManager.request_rewarded_heart)
		else:
			primary_button = _aftermath_button(SaveManager.text("endless_ad_claimed"), true, false)
			primary_button.visible = false
	else:
		primary_button = _aftermath_button(SaveManager.text("share_result"), true, won)
		primary_button.pressed.connect(func() -> void:
			_on_share_pressed()
			primary_button.text = SaveManager.text("result_copied")
		)
	content.add_child(primary_button)
	var menu_button: Button = _aftermath_button(SaveManager.text("back_to_home") if is_endless else SaveManager.text("menu"), false)
	menu_button.pressed.connect(func() -> void: request_menu.emit())
	content.add_child(menu_button)

	await get_tree().process_frame
	if not is_instance_valid(sheet) or not is_instance_valid(layer):
		return
	flame.pivot_offset = flame.size * 0.5
	streak_number.pivot_offset = streak_number.size * 0.5
	stack.position.y = sheet.size.y
	_aftermath_open_tween = create_tween().set_parallel(true)
	_aftermath_open_tween.tween_property(layer, "modulate:a", 1.0, 0.22)
	_aftermath_open_tween.tween_property(stack, "position:y", 0.0, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if won and play_streak_animation:
		_animate_streak_win(layer, flame, streak_number, streak_caption, streak_from, streak_to)
	elif not won and play_streak_animation:
		_animate_streak_loss(layer, flame, streak_number, streak_caption, crack_overlay, streak_crack)
	elif not won and has_daily_streak:
		_apply_streak_loss_final(flame, streak_number, crack_overlay, streak_crack)
	elif is_endless_loss and is_instance_valid(losing_heart):
		_animate_endless_heart_loss(layer, losing_heart)

func _animate_endless_heart_loss(layer: Control, heart: Label) -> void:
	await get_tree().create_timer(0.42).timeout
	if not is_instance_valid(layer) or layer != _aftermath_layer or not is_instance_valid(heart):
		return
	heart.pivot_offset = heart.size * 0.5
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(heart, "scale", Vector2.ONE * 1.6, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(heart, "rotation_degrees", 12.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	var collapse: Tween = create_tween().set_parallel(true)
	collapse.tween_property(heart, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	collapse.tween_property(heart, "rotation_degrees", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	collapse.tween_property(heart, "modulate:a", 0.30, 0.24)
	heart.add_theme_color_override("font_color", Color("62578f"))

func _animate_streak_win(layer: Control, flame: Label, streak_number: Label, streak_caption: Label, streak_from: int, streak_to: int) -> void:
	await get_tree().create_timer(STREAK_POP_DELAY).timeout
	if not is_instance_valid(layer) or layer != _aftermath_layer:
		return
	streak_number.text = str(streak_to)
	streak_caption.text = SaveManager.text("aftermath_streak") % [streak_from, streak_to]
	var flame_pop: Tween = create_tween()
	flame_pop.tween_property(flame, "scale", Vector2.ONE * 1.38, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flame_pop.tween_property(flame, "scale", Vector2.ONE * 0.96, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	flame_pop.tween_property(flame, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var number_pop: Tween = create_tween()
	number_pop.tween_property(streak_number, "scale", Vector2.ONE * 1.32, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	number_pop.tween_property(streak_number, "scale", Vector2.ONE * 0.97, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	number_pop.tween_property(streak_number, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _animate_streak_loss(layer: Control, flame: Label, streak_number: Label, streak_caption: Label, crack_overlay: Control, streak_crack: ColorRect) -> void:
	streak_caption.modulate.a = 0.0
	await get_tree().create_timer(0.34).timeout
	if not is_instance_valid(layer) or layer != _aftermath_layer:
		return
	var flame_origin_x: float = flame.position.x
	var shake: Tween = create_tween()
	shake.tween_property(flame, "position:x", flame_origin_x + 7.0, 0.055)
	shake.tween_property(flame, "position:x", flame_origin_x - 7.0, 0.055)
	shake.tween_property(flame, "position:x", flame_origin_x + 5.0, 0.055)
	shake.tween_property(flame, "position:x", flame_origin_x - 3.0, 0.055)
	shake.tween_property(flame, "position:x", flame_origin_x, 0.055)
	var number_center: Vector2 = streak_number.get_global_rect().get_center() - crack_overlay.get_global_rect().position
	var crack_width: float = minf(maxf(streak_number.size.y * 1.75, 88.0), 112.0)
	streak_crack.position = Vector2(number_center.x - crack_width * 0.5, number_center.y)
	streak_crack.size = Vector2(0.0, 4.0)
	streak_crack.rotation_degrees = -7.0
	streak_crack.visible = true
	var shatter: Tween = create_tween().set_parallel(true)
	shatter.tween_property(flame, "modulate", Color(0.55, 0.55, 0.55, 1.0), 0.32).set_delay(0.16)
	shatter.tween_property(streak_number, "modulate:a", 0.48, 0.28).set_delay(0.18)
	shatter.tween_property(streak_caption, "modulate:a", 1.0, 0.22).set_delay(0.24)
	shatter.tween_property(streak_crack, "size:x", crack_width, 0.30).set_delay(0.20).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _apply_streak_loss_final(flame: Label, streak_number: Label, crack_overlay: Control, streak_crack: ColorRect) -> void:
	flame.modulate = Color(0.55, 0.55, 0.55, 1.0)
	streak_number.modulate.a = 0.48
	var number_center: Vector2 = streak_number.get_global_rect().get_center() - crack_overlay.get_global_rect().position
	var crack_width: float = minf(maxf(streak_number.size.y * 1.75, 88.0), 112.0)
	streak_crack.position = Vector2(number_center.x - crack_width * 0.5, number_center.y)
	streak_crack.size = Vector2(crack_width, 4.0)
	streak_crack.rotation_degrees = -7.0
	streak_crack.visible = true

func _on_aftermath_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dismiss_aftermath()
	elif event is InputEventScreenTouch and not event.pressed:
		_dismiss_aftermath()

func _on_aftermath_drag_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_aftermath_drag(event.position.y)
		elif _aftermath_dragging:
			_finish_aftermath_drag(event.position.y)
	elif event is InputEventScreenDrag and _aftermath_dragging:
		_update_aftermath_drag(event.position.y)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_aftermath_drag(event.global_position.y)
		elif _aftermath_dragging:
			_finish_aftermath_drag(event.global_position.y)
	elif event is InputEventMouseMotion and _aftermath_dragging and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_update_aftermath_drag(event.global_position.y)

func _start_aftermath_drag(pointer_y: float) -> void:
	if not is_instance_valid(_aftermath_sheet) or _aftermath_dismissing:
		return
	_stop_aftermath_motion()
	_aftermath_layer.modulate.a = 1.0
	_aftermath_stack.position.y = 0.0
	_aftermath_dragging = true
	_aftermath_drag_start_y = pointer_y

func _update_aftermath_drag(pointer_y: float) -> void:
	if not is_instance_valid(_aftermath_stack):
		return
	var offset: float = max(pointer_y - _aftermath_drag_start_y, 0.0)
	_aftermath_stack.position.y = offset
	if offset > 8.0:
		accept_event()

func _finish_aftermath_drag(pointer_y: float) -> void:
	_aftermath_dragging = false
	var offset: float = max(pointer_y - _aftermath_drag_start_y, 0.0)
	if offset >= 72.0:
		_dismiss_aftermath()
	elif is_instance_valid(_aftermath_stack):
		_aftermath_snap_tween = create_tween()
		_aftermath_snap_tween.tween_property(_aftermath_stack, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _stop_aftermath_motion() -> void:
	if _aftermath_open_tween != null and _aftermath_open_tween.is_running():
		_aftermath_open_tween.kill()
	if _aftermath_snap_tween != null and _aftermath_snap_tween.is_running():
		_aftermath_snap_tween.kill()

func _dismiss_aftermath() -> void:
	if _aftermath_dismissing or not is_instance_valid(_aftermath_layer):
		return
	_aftermath_dismissing = true
	_aftermath_dragging = false
	_stop_aftermath_motion()
	var layer: Control = _aftermath_layer
	var sheet: PanelContainer = _aftermath_sheet
	var stack: VBoxContainer = _aftermath_stack
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(layer, "modulate:a", 0.0, 0.20)
	if is_instance_valid(sheet) and is_instance_valid(stack):
		tween.tween_property(stack, "position:y", stack.position.y + sheet.size.y + 24.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	if is_instance_valid(layer):
		layer.queue_free()
	if _aftermath_layer == layer:
		_aftermath_layer = null
	_aftermath_sheet = null
	_aftermath_stack = null
	_aftermath_open_tween = null
	_aftermath_snap_tween = null
	_aftermath_dismissing = false

func _on_endless_next_puzzle_pressed() -> void:
	await _dismiss_aftermath()
	request_new_game.emit()

func _on_rewarded_heart_earned() -> void:
	# Main owns the persistent reward grant. Rebuild the visible Infinity sheet
	# one frame later so it reflects the newly restored heart.
	await get_tree().process_frame
	if GameState.game_mode != "unlimited" or not is_instance_valid(_aftermath_layer):
		return
	await _dismiss_aftermath()
	_show_aftermath(GameState.completed_won)

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
	if GameState.game_mode == GameState.TUTORIAL_MODE and _tutorial_stage == 1:
		_tutorial_stage = 2
		_hint.disabled = true
		call_deferred("_advance_tutorial_after_hint")

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
	if GameState.game_mode == GameState.TUTORIAL_MODE:
		_hint.disabled = _tutorial_stage != 1

func _apply_tutorial_stage() -> void:
	if GameState.game_mode != GameState.TUTORIAL_MODE or GameState.is_finished:
		return
	var allowed: Array[String] = []
	var guide_text: String = SaveManager.text("tutorial_select_group")
	match _tutorial_stage:
		0:
			allowed = GameState.tutorial_group_words(2)
		1:
			guide_text = SaveManager.text("tutorial_use_hint")
		2:
			allowed = GameState.tutorial_group_words(5)
			guide_text = SaveManager.text("tutorial_finish_row")
		3:
			allowed = GameState.tutorial_group_words(3)
		4:
			allowed = GameState.tutorial_group_words(4)
		5:
			allowed = GameState.tutorial_group_words(1)
			guide_text = SaveManager.text("tutorial_top_word")
	GameState.set_tutorial_allowed_words(allowed)
	_hint.disabled = _tutorial_paused or _tutorial_stage != 1
	_check.disabled = _tutorial_paused or not GameState.can_check_selection()
	if not _tutorial_paused:
		_message.text = guide_text
	_update_tutorial_spotlight()

func _update_tutorial_selection_message() -> void:
	if _tutorial_stage == 1:
		_message.text = SaveManager.text("tutorial_use_hint")
		_hint.disabled = false
		_check.disabled = true
		_update_tutorial_spotlight()
		return
	var expected_count: int = GameState.tutorial_allowed_words.size()
	if expected_count > 0 and GameState.selected_words.size() == expected_count:
		_message.text = SaveManager.text("tutorial_press_check")
	elif _tutorial_stage == 2:
		_message.text = SaveManager.text("tutorial_finish_row")
	elif _tutorial_stage == 5:
		_message.text = SaveManager.text("tutorial_top_word")
	else:
		_message.text = SaveManager.text("tutorial_select_group")
	_update_tutorial_spotlight()

func _update_tutorial_spotlight() -> void:
	if GameState.game_mode != GameState.TUTORIAL_MODE or not is_instance_valid(_tutorial_spotlight):
		return
	if _tutorial_paused:
		_tutorial_spotlight.visible = false
		_clear_tutorial_focus()
		return
	_tutorial_spotlight.visible = true
	for word: String in _word_buttons:
		var tile: Button = _word_buttons[word]
		var focused: bool = GameState.is_tutorial_word_allowed(word)
		tile.z_index = 21 if focused else 0
		_set_tutorial_focus(tile, focused)
	_hint.z_index = 21 if _tutorial_stage == 1 else 0
	_set_tutorial_focus(_hint, _tutorial_stage == 1)
	var selection_ready: bool = not GameState.tutorial_allowed_words.is_empty() and GameState.selected_words.size() == GameState.tutorial_allowed_words.size()
	_check.z_index = 21 if selection_ready and GameState.can_check_selection() else 0
	_set_tutorial_focus(_check, selection_ready and GameState.can_check_selection())
	_message.z_index = 22

func _set_tutorial_focus(control: Control, focused: bool, animate: bool = true) -> void:
	if not is_instance_valid(control):
		return
	var key: int = control.get_instance_id()
	var previous: Tween = _tutorial_focus_tweens.get(key) as Tween
	var already_focused: bool = bool(control.get_meta("tutorial_focused", false)) == focused
	if animate and already_focused:
		if focused and previous != null and previous.is_running():
			return
		if not focused and control.scale.is_equal_approx(Vector2.ONE):
			return
	control.set_meta("tutorial_focused", focused)
	control.pivot_offset = control.size * 0.5
	if previous != null and previous.is_running():
		previous.kill()
	if not animate:
		control.scale = Vector2(1.035, 1.035) if focused else Vector2.ONE
		_tutorial_focus_tweens.erase(key)
		return
	var tween: Tween = create_tween()
	_tutorial_focus_tweens[key] = tween
	if focused:
		# Keep the prompt visibly alive instead of relying on a one-time scale
		# change that is easy to miss on a phone-sized tile.
		tween.set_loops()
		tween.tween_property(control, "scale", Vector2(1.06, 1.06), 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(control, "scale", Vector2(1.025, 1.025), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		tween.tween_property(control, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func() -> void: _tutorial_focus_tweens.erase(key))

func _clear_tutorial_focus() -> void:
	for tile_value: Variant in _word_buttons.values():
		var tile: Button = tile_value as Button
		if tile != null:
			tile.z_index = 0
			_set_tutorial_focus(tile, false)
	_hint.z_index = 0
	_check.z_index = 0
	_set_tutorial_focus(_hint, false)
	_set_tutorial_focus(_check, false)

func _start_tutorial_break(duration: float) -> void:
	if GameState.game_mode != GameState.TUTORIAL_MODE or _tutorial_finishing:
		return
	_tutorial_pause_id += 1
	var pause_id: int = _tutorial_pause_id
	_tutorial_paused = true
	for tile_value: Variant in _word_buttons.values():
		var tile: Button = tile_value as Button
		if tile != null:
			tile.disabled = true
			# During the acknowledgement beat, keep only the player's actual
			# selected state. The tutorial border and spotlight return afterward.
			_apply_word_tile_visual(tile, GameState.selected_words.has(tile.text))
	_hint.disabled = true
	_check.disabled = true
	_update_tutorial_spotlight()
	await get_tree().create_timer(duration).timeout
	if not is_inside_tree() or pause_id != _tutorial_pause_id or _tutorial_finishing or GameState.game_mode != GameState.TUTORIAL_MODE:
		return
	_tutorial_paused = false
	_apply_tutorial_stage()
	_on_selection_changed(GameState.selected_words)

func _advance_tutorial_after_group(row_length: int) -> void:
	if GameState.game_mode != GameState.TUTORIAL_MODE:
		return
	if _is_placing:
		await get_tree().create_timer(0.90).timeout
		if not is_inside_tree() or GameState.game_mode != GameState.TUTORIAL_MODE:
			return
	if _tutorial_stage == 0 and row_length == 2:
		_tutorial_stage = 1
	elif _tutorial_stage == 2 and row_length == 5:
		_tutorial_stage = 3
	elif _tutorial_stage == 3 and row_length == 3:
		_tutorial_stage = 4
	elif _tutorial_stage == 4 and row_length == 4:
		_tutorial_stage = 5
	_apply_tutorial_stage()

func _advance_tutorial_after_hint() -> void:
	await get_tree().create_timer(0.58).timeout
	if is_inside_tree() and GameState.game_mode == GameState.TUTORIAL_MODE and _tutorial_stage == 2:
		_apply_tutorial_stage()

func _on_tutorial_completed() -> void:
	if _tutorial_finishing or GameState.game_mode != GameState.TUTORIAL_MODE:
		return
	_tutorial_finishing = true
	_tutorial_paused = true
	GameState.set_tutorial_allowed_words([])
	_hint.disabled = true
	_check.disabled = true
	_update_tutorial_spotlight()
	_message.text = SaveManager.text("tutorial_complete")
	await get_tree().create_timer(1.35).timeout
	if is_inside_tree():
		request_tutorial_exit.emit(true)

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
		if GameState.game_mode == GameState.TUTORIAL_MODE:
			_start_tutorial_break(TUTORIAL_HINT_BREAK)
		GameState.request_hint()

func _on_check_pressed() -> void:
	if not GameState.can_check_selection():
		return
	if GameState.game_mode == GameState.TUTORIAL_MODE:
		_start_tutorial_break(TUTORIAL_CHECK_BREAK)
	GameState.check_selection()

func _show_instructions() -> void:
	_message.text = SaveManager.text("instructions_text")

func _action_button(label_text: String, filled: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(110, 52)
	button.add_theme_font_override("font", _font_fredoka_semibold)
	button.add_theme_font_size_override("font_size", 15)
	var normal_color: Color = UI_RED if filled else UI_SURFACE
	button.add_theme_stylebox_override("normal", _button_style(normal_color, normal_color if filled else UI_PRIMARY))
	button.add_theme_stylebox_override("hover", _button_style(UI_RED.lightened(0.08) if filled else Color("f4f0ff"), UI_RED if filled else UI_PRIMARY_HOVER))
	button.add_theme_stylebox_override("pressed", _button_style(UI_RED.darkened(0.10) if filled else Color("e8e4f4"), UI_RED.darkened(0.10) if filled else UI_PRIMARY_PRESSED))
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
	button.custom_minimum_size = Vector2(0, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font", _font_fredoka_semibold)
	button.add_theme_font_size_override("font_size", 17)
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
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.102, 0.039, 0.369, 0.10)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
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
	style.shadow_color = Color(0.102, 0.039, 0.369, 0.12)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	return style

func _row_band_style(row_length: int) -> StyleBoxFlat:
	var colors: Dictionary = {
		1: Color("eee7ff"),
		2: Color("ffe3eb"),
		3: Color("ffe9d8"),
		4: Color("dff8f4"),
		5: Color("fff3c6"),
	}
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = colors.get(row_length, UI_SURFACE_TINT)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0.102, 0.039, 0.369, 0.04)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	return style

func _action_dock_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("f3effb")
	style.border_color = Color("e8e1f7")
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.102, 0.039, 0.369, 0.08)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style

func _tile_style(color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_color = border_color
	style.set_border_width_all(1)
	style.shadow_color = Color(0.102, 0.039, 0.369, 0.13)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
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
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_left = 9
	style.corner_radius_bottom_right = 9
	style.border_color = _row_border(row_length)
	style.set_border_width_all(1)
	return style

func _button_style(color: Color, border_color: Color = UI_BORDER) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.border_color = border_color
	style.set_border_width_all(2)
	style.shadow_color = Color(0.102, 0.039, 0.369, 0.10)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	return style

func _aftermath_sheet_style(won: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UI_PRIMARY
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.border_color = Color(1, 1, 1, 0.08)
	style.set_border_width_all(1)
	style.shadow_color = UI_YELLOW if won else UI_RED
	style.shadow_size = 1
	style.shadow_offset = Vector2(8, 8)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	return style

func _add_aftermath_accent(parent: VBoxContainer, won: bool) -> void:
	var accent: HBoxContainer = HBoxContainer.new()
	accent.custom_minimum_size = Vector2(0, 5)
	accent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	accent.add_theme_constant_override("separation", 0)
	parent.add_child(accent)
	var colors: Array[Color] = []
	if won:
		colors.append(UI_YELLOW)
		colors.append(UI_MAGENTA)
		colors.append(UI_TEAL)
		colors.append(UI_RED)
	else:
		colors.append(UI_RED)
	for color in colors:
		var segment: ColorRect = ColorRect.new()
		segment.color = color
		segment.custom_minimum_size = Vector2(0, 5)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		accent.add_child(segment)

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
