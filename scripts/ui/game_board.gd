class_name GameBoard
extends Control

signal request_menu
signal request_new_game
signal request_tutorial_exit(completed: bool)
signal request_mode_transition(mode: String)

const ROW_LENGTHS: Array[int] = [1, 2, 3, 4, 5]
const TILE_GAP: float = 6.0
const ROW_BAND_OVERHANG: Vector2 = Vector2(7.0, 3.0)
const FONT_FREDOKA: Font = preload("res://assets/fonts/Fredoka.ttf")
const FONT_DM_SANS: Font = preload("res://assets/fonts/DMSans.ttf")
const ICON_HOME: Texture2D = preload("res://assets/icons/home.svg")
const ICON_SHARE: Texture2D = preload("res://assets/icons/share.svg")
const ICON_FLAME: Texture2D = preload("res://assets/icons/flame.svg")
const ICON_LIGHTBULB: Texture2D = preload("res://assets/icons/lightbulb.svg")
const ICON_HEART: Texture2D = preload("res://assets/heart.svg")
const INSTRUCTIONS_STYLE_DEMO_SCENE: PackedScene = preload("res://scenes/instructions_style_demo.tscn")
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
const SELECTED_FILL: Color = Color("ff9a76")
const SELECTED_BORDER: Color = UI_YELLOW
const WRONG_TILE_FILL: Color = Color("fff2ee")
const SELECTION_LIFT: float = 4.0
const SELECTION_MOTION_DURATION: float = 0.14
const WRONG_SHAKE_DURATION: float = 0.58
const WRONG_SHAKE_PEAK: float = 6.0
const WRONG_SHAKE_SETTLE: float = 3.0
const AFTERMATH_REVEAL_DELAY: float = 2.0
const STREAK_POP_DELAY: float = 0.70
const XP_REWARD_ANIMATION_DELAY: float = 0.38
const XP_REWARD_ANIMATION_DURATION: float = 1.20
const TUTORIAL_HINT_BREAK: float = 1.65
const TUTORIAL_CHECK_BREAK: float = 1.30
const TUTORIAL_FINISH_BREAK: float = 2.00
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
var _debug_auto_solve: Button
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
var _aftermath_xp_tween: Tween
var _level_up_overlay: Control
var _game_was_running: bool = false
var _aftermath_scheduled: bool = false
var _fresh_result_reveal: bool = false
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
var _message_selection_snapshot: Array[String] = []
var _font_fredoka_semibold: FontVariation
var _font_fredoka_condensed: FontVariation
var _font_fredoka_bold: FontVariation
var _font_dm_sans_semibold: FontVariation
var _tutorial_stage: int = 0
var _tutorial_finishing: bool = false
var _tutorial_spotlight: ColorRect
var _tutorial_paused: bool = false
var _tutorial_pause_id: int = 0
var _tutorial_help_level: int = 0
var _tutorial_target_words: Array[String] = []
var _tutorial_focus_words: Array[String] = []
var _tutorial_independent_intro_pending: bool = false
var _tutorial_focus_tweens: Dictionary = {}
var _tutorial_guide_button: Button
var _tutorial_intro_layer: Control
var _tutorial_feature_layer: Control
var _tutorial_feature_card: Control
var _tutorial_feature_tween: Tween
var _tutorial_restart_layer: ColorRect
var _tutorial_completion_layer: Control
var _instructions_layer: Control

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
	add_child(_create_game_decor())
	var page_margin: MarginContainer = MarginContainer.new()
	page_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_margin.add_theme_constant_override("margin_left", 8)
	page_margin.add_theme_constant_override("margin_right", 8)
	page_margin.add_theme_constant_override("margin_top", 12)
	page_margin.add_theme_constant_override("margin_bottom", 16)
	add_child(page_margin)
	var page: VBoxContainer = VBoxContainer.new()
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 10)
	page_margin.add_child(page)
	var header_card: PanelContainer = PanelContainer.new()
	header_card.add_theme_stylebox_override("panel", _header_card_style())
	page.add_child(header_card)
	var header_margin: MarginContainer = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 12)
	header_margin.add_theme_constant_override("margin_right", 12)
	header_margin.add_theme_constant_override("margin_top", 10)
	header_margin.add_theme_constant_override("margin_bottom", 10)
	header_card.add_child(header_margin)
	var header_content: VBoxContainer = VBoxContainer.new()
	header_content.add_theme_constant_override("separation", 4)
	header_margin.add_child(header_content)
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_theme_constant_override("separation", 10)
	header_content.add_child(top_bar)
	var header_side_width: float = 78.0
	var back: Button = Button.new()
	back.text = SaveManager.text("tutorial_skip") if GameState.game_mode == GameState.TUTORIAL_MODE else "←  " + SaveManager.text("back")
	back.custom_minimum_size = Vector2(header_side_width, 36)
	back.add_theme_font_override("font", _font_dm_sans_semibold)
	back.add_theme_font_size_override("font_size", 13)
	back.add_theme_stylebox_override("normal", _header_button_style(UI_YELLOW))
	back.add_theme_stylebox_override("hover", _header_button_style(Color("ffe23d")))
	back.add_theme_stylebox_override("pressed", _header_button_style(Color("e9c400")))
	back.add_theme_color_override("font_color", UI_PRIMARY)
	back.add_theme_color_override("font_hover_color", UI_PRIMARY)
	back.add_theme_color_override("font_pressed_color", UI_PRIMARY)
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
	game_title.text = "▲  Word Pyramid"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_title.add_theme_font_override("font", _font_fredoka_bold)
	game_title.add_theme_font_size_override("font_size", 21)
	game_title.add_theme_color_override("font_color", Color.WHITE)
	title_stack.add_child(game_title)
	_mode_label = Label.new()
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.add_theme_font_override("font", FONT_DM_SANS)
	_mode_label.add_theme_font_size_override("font_size", 10)
	_mode_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.62))
	title_stack.add_child(_mode_label)
	_endless_header_hearts = HBoxContainer.new()
	# Match the back-button width so the title remains geometrically centered.
	_endless_header_hearts.custom_minimum_size = Vector2(header_side_width, 36)
	_endless_header_hearts.alignment = BoxContainer.ALIGNMENT_END
	_endless_header_hearts.add_theme_constant_override("separation", 3)
	top_bar.add_child(_endless_header_hearts)
	_puzzle_title = Label.new()
	_puzzle_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_puzzle_title.add_theme_font_override("font", _font_fredoka_bold)
	_puzzle_title.add_theme_font_size_override("font_size", 21)
	_puzzle_title.add_theme_color_override("font_color", UI_YELLOW)
	header_content.add_child(_puzzle_title)
	_card = PanelContainer.new()
	_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_card.add_theme_stylebox_override("panel", _card_style())
	page.add_child(_card)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_card.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var top: HBoxContainer = HBoxContainer.new()
	content.add_child(top)
	_debug_auto_solve = Button.new()
	_debug_auto_solve.text = SaveManager.text("debug_auto_solve")
	_debug_auto_solve.add_theme_font_override("font", _font_dm_sans_semibold)
	_debug_auto_solve.add_theme_font_size_override("font_size", 11)
	_debug_auto_solve.add_theme_color_override("font_color", UI_PRIMARY)
	_debug_auto_solve.add_theme_color_override("font_hover_color", UI_PRIMARY)
	_debug_auto_solve.add_theme_color_override("font_pressed_color", UI_PRIMARY)
	_debug_auto_solve.add_theme_stylebox_override("normal", _small_pill_style(Color("fff3bd"), UI_YELLOW))
	_debug_auto_solve.add_theme_stylebox_override("hover", _small_pill_style(UI_YELLOW, UI_PRIMARY))
	_debug_auto_solve.add_theme_stylebox_override("pressed", _small_pill_style(Color("e9c400"), UI_PRIMARY))
	_debug_auto_solve.pressed.connect(_on_debug_auto_solve_pressed)
	_debug_auto_solve.visible = false
	top.add_child(_debug_auto_solve)
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var instructions: Button = Button.new()
	instructions.text = "?  " + SaveManager.text("instructions")
	instructions.add_theme_font_override("font", _font_dm_sans_semibold)
	instructions.add_theme_font_size_override("font_size", 12)
	instructions.add_theme_color_override("font_color", UI_MUTED_TEXT)
	instructions.add_theme_color_override("font_hover_color", UI_TEXT)
	instructions.add_theme_stylebox_override("normal", _small_pill_style(Color("f4f0ff"), UI_BORDER))
	instructions.add_theme_stylebox_override("hover", _small_pill_style(Color("ebe4fb"), Color("bcaef0")))
	instructions.add_theme_stylebox_override("pressed", _small_pill_style(Color("e1d8f5"), Color("a99be0")))
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
	_message.add_theme_font_override("font", _font_dm_sans_semibold)
	_message.add_theme_font_size_override("font_size", 14)
	_message.add_theme_color_override("font_color", Color("d9d1f3"))
	if GameState.game_mode == GameState.TUTORIAL_MODE:
		# A plain Control isolates the VBox from the Label's changing wrapped-text
		# minimum height, so every tutorial instruction occupies the same space.
		var message_slot: Control = Control.new()
		message_slot.custom_minimum_size = Vector2(0, 96)
		message_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		message_slot.clip_contents = true
		content.add_child(message_slot)
		message_slot.add_child(_message)
		_message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_message.offset_bottom = -32.0
		_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_message.add_theme_font_override("font", _font_fredoka_semibold)
		_message.add_theme_font_size_override("font_size", 18)
		_message.add_theme_color_override("font_color", UI_TEXT)
		_message.add_theme_stylebox_override("normal", _tutorial_guide_style())
		_message.z_index = 22
		_tutorial_guide_button = Button.new()
		_tutorial_guide_button.name = "TutorialGuideContinue"
		_tutorial_guide_button.text = SaveManager.text("tutorial_continue")
		_tutorial_guide_button.custom_minimum_size = Vector2(104, 28)
		_tutorial_guide_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		_tutorial_guide_button.position = Vector2(-52, -30)
		_tutorial_guide_button.add_theme_font_override("font", _font_fredoka_semibold)
		_tutorial_guide_button.add_theme_font_size_override("font_size", 13)
		_tutorial_guide_button.add_theme_color_override("font_color", UI_PRIMARY)
		_tutorial_guide_button.add_theme_color_override("font_hover_color", UI_PRIMARY)
		_tutorial_guide_button.add_theme_color_override("font_pressed_color", UI_PRIMARY)
		_tutorial_guide_button.add_theme_stylebox_override("normal", _small_pill_style(UI_YELLOW, UI_PRIMARY))
		_tutorial_guide_button.add_theme_stylebox_override("hover", _small_pill_style(Color("ffe23d"), UI_PRIMARY))
		_tutorial_guide_button.add_theme_stylebox_override("pressed", _small_pill_style(Color("e9c400"), UI_PRIMARY))
		_tutorial_guide_button.visible = false
		_tutorial_guide_button.z_index = 22
		_tutorial_guide_button.pressed.connect(_on_tutorial_guide_continue)
		message_slot.add_child(_tutorial_guide_button)
	else:
		content.add_child(_message)
	_selection = Label.new()
	_selection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection.add_theme_font_override("font", _font_dm_sans_semibold)
	_selection.add_theme_color_override("font_color", Color("d9d1f3"))
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
	dock_margin.add_theme_constant_override("margin_left", 12)
	dock_margin.add_theme_constant_override("margin_right", 12)
	dock_margin.add_theme_constant_override("margin_top", 10)
	dock_margin.add_theme_constant_override("margin_bottom", 12)
	action_dock.add_child(dock_margin)
	var dock_content: VBoxContainer = VBoxContainer.new()
	dock_content.add_theme_constant_override("separation", 7)
	dock_margin.add_child(dock_content)
	_mistakes = Label.new()
	_mistakes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mistakes.add_theme_font_override("font", _font_dm_sans_semibold)
	_mistakes.add_theme_font_size_override("font_size", 12)
	_mistakes.add_theme_color_override("font_color", Color(1, 1, 1, 0.68))
	dock_content.add_child(_mistakes)
	var action_row: HBoxContainer = HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 10)
	dock_content.add_child(action_row)
	_hint = _action_button(_hint_button_label(SaveManager.text("hint_count") % 2))
	_hint.icon = ICON_LIGHTBULB
	_hint.expand_icon = true
	_hint.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hint.add_theme_constant_override("icon_max_width", 20)
	_hint.pressed.connect(_on_hint_pressed)
	action_row.add_child(_hint)
	_clear = _action_button(SaveManager.text("clear"))
	_clear.pressed.connect(GameState.clear_selection)
	_clear.visible = false
	action_row.add_child(_clear)
	_check = _action_button("✓  " + SaveManager.text("check"), true)
	_check.pressed.connect(_on_check_pressed)
	action_row.add_child(_check)
	_result = _action_button("", false)
	_result.visible = false
	_result.pressed.connect(_on_result_pressed)
	action_row.add_child(_result)
	_share = _action_button("↗  " + SaveManager.text("share_result"), true)
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
	new_game.text = "↻  " + SaveManager.text("new_game")
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
	menu.text = "⌂  " + SaveManager.text("menu")
	menu.flat = true
	menu.add_theme_font_override("font", FONT_DM_SANS)
	menu.add_theme_color_override("font_color", UI_MUTED_TEXT)
	menu.pressed.connect(func() -> void: request_menu.emit())
	game_actions.add_child(menu)
	if GameState.game_mode == GameState.TUTORIAL_MODE:
		_tutorial_spotlight = ColorRect.new()
		_tutorial_spotlight.color = Color(0.08, 0.035, 0.22, 0.35)
		_tutorial_spotlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tutorial_spotlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_tutorial_spotlight.z_index = 20
		add_child(_tutorial_spotlight)

func refresh() -> void:
	if not is_node_ready():
		return
	var is_daily: bool = GameState.game_mode == "daily"
	var is_tutorial: bool = GameState.game_mode == GameState.TUTORIAL_MODE
	_debug_auto_solve.visible = false
	_debug_auto_solve.disabled = GameState.is_auto_solving
	_selection.visible = not is_tutorial
	if is_tutorial:
		_message.visible = true
		_message.text = SaveManager.text("tutorial_select_group")
	else:
		_clear_board_message()
	_mode_label.text = SaveManager.text("tutorial_mode_label").to_upper() if is_tutorial else (SaveManager.text("daily_challenge_label").to_upper() if is_daily else "∞ %s · %s" % [SaveManager.text("unlimited_mode_label").to_upper(), (SaveManager.text("difficulty_short") % PuzzleLoader.get_difficulty_tier(GameState.puzzle)).to_upper()])
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
			_tutorial_independent_intro_pending = false
			_show_tutorial_intro()

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
			# The top word always remains a word block. Other solved rows are only
			# represented by word blocks during their placement animation, after
			# which a category card covers the completed row.
			if row_length == 1 or row_length == _animating_row:
				var placed_row: Array[Button] = []
				var locked_hint_words: Array[String] = GameState.get_hint_words_for_row(row_length)
				for solved_word: String in GameState._to_string_array(solved_group.get("words", [])):
					var placed_tile: Button = _create_placed_tile(solved_word, row_length)
					# The hint was already locked in this row, so keep it visible
					# while the remaining blocks finish their placement animation.
					var placement_is_finished: bool = row_length != _animating_row
					placed_tile.modulate.a = 1.0 if placement_is_finished or locked_hint_words.has(solved_word) else 0.0
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
	_configure_word_tile(tile, word)
	tile.set_meta(SoundManager.SKIP_UI_CLICK_SOUND_META, true)
	tile.toggle_mode = true
	tile.tooltip_text = SaveManager.text("select_tooltip") % word
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
	_configure_word_tile(tile, word)
	tile.name = "HintedTile_%d" % row_length
	tile.set_meta("hinted", true)
	tile.set_meta("row_length", row_length)
	tile.set_meta(SoundManager.SKIP_UI_CLICK_SOUND_META, true)
	tile.disabled = true
	# Hinted tiles are rebuilt whenever the board refreshes. Apply the row style
	# to the disabled state itself so the locked color survives that rebuild.
	tile.add_theme_color_override("font_disabled_color", _row_text(row_length))
	tile.add_theme_stylebox_override("disabled", _tile_style(_row_fill(row_length), _row_border(row_length)))
	tile.tooltip_text = SaveManager.text("hint_tooltip")
	return tile

func _create_placed_tile(word: String, row_length: int) -> Button:
	var tile: Button = Button.new()
	_configure_word_tile(tile, word)
	tile.name = "PlacedTile_%d" % row_length
	tile.disabled = true
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.focus_mode = Control.FOCUS_NONE
	_apply_static_tile_visual(tile, _tile_style(_row_fill(row_length), _row_border(row_length)), _row_text(row_length))
	return tile

func _configure_word_tile(tile: Button, word: String) -> void:
	# Every board word uses this exact text configuration. Keeping playable,
	# hinted, placed, and flying tiles on the same Button control prevents Godot
	# from changing text metrics when a correct row is rebuilt.
	tile.text = _display_word(word)
	tile.set_meta("word", word)
	tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	tile.alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_theme_font_override("font", _tile_font(word))
	tile.add_theme_font_size_override("font_size", 13)
	tile.add_theme_color_override("font_color", UI_TEXT)

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
	# Rebuilding rows during the automatic finish must not derive a new block
	# size from transient Control geometry. The viewport is the stable phone
	# canvas and only changes when the actual window/device layout changes.
	var viewport_size: Vector2 = get_viewport_rect().size
	var layout_width: float = viewport_size.x if viewport_size.x > 0.0 else size.x
	var layout_height: float = viewport_size.y if viewport_size.y > 0.0 else size.y
	var card_width: float = clampf(layout_width - 16.0, 304.0, 620.0)
	_card.custom_minimum_size = Vector2(card_width, 0.0)
	var usable_width: float = card_width
	var tile_size: float = clampf((card_width - TILE_GAP * 4.0) / 5.0, 48.0, 104.0)
	# Match the 1.0.2 Android build: blocks use the five-word row for width and
	# the available phone height separately, producing the slightly taller shape.
	# The tutorial reserves a stable 76 px guide slot in place of the normal
	# single-line message. Deduct the extra space here so its board and controls
	# fit the same phone viewport instead of extending below the screen.
	var tutorial_guide_reservation: float = 60.0 if GameState.game_mode == GameState.TUTORIAL_MODE else 0.0
	var pyramid_height: float = clampf(layout_height - 365.0 - tutorial_guide_reservation, 290.0, 480.0)
	var tile_height: float = clampf((pyramid_height - TILE_GAP * 4.0) / 5.0, 54.0, 92.0)
	var shared_font_size: int = _uniform_tile_font_size(tile_size)
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
		tile.add_theme_font_size_override("font_size", shared_font_size)
	for hinted_tile: Button in _hinted_tiles.values():
		hinted_tile.custom_minimum_size = Vector2(tile_size, tile_height)
		hinted_tile.size = Vector2(tile_size, tile_height)
		hinted_tile.add_theme_font_size_override("font_size", shared_font_size)
	for row_length: int in _placed_tiles:
		for placed_tile: Button in _placed_tiles[row_length]:
			placed_tile.custom_minimum_size = Vector2(tile_size, tile_height)
			placed_tile.size = Vector2(tile_size, tile_height)
			placed_tile.add_theme_font_size_override("font_size", shared_font_size)
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
	var action_width: float = clampf((usable_width - 34.0) / 2.0, 130.0, 260.0)
	for action_button: Button in _action_buttons:
		action_button.custom_minimum_size = Vector2(action_width, 52.0)
		action_button.add_theme_font_size_override("font_size", 16)
	_hint.custom_minimum_size = Vector2(82.0, 52.0)
	_hint.add_theme_font_size_override("font_size", 14)
	_check.custom_minimum_size = Vector2(max(usable_width - 116.0, 180.0), 52.0)
	_check.add_theme_font_size_override("font_size", 17)

func _uniform_tile_font_size(tile_size: float) -> int:
	# One responsive size is shared by every word tile. Longer compounds still
	# use the condensed Fredoka variation, but are not arbitrarily made smaller.
	return clampi(floori(tile_size * 0.17), 9, 13)

func _display_word(word: String) -> String:
	var display_breaks_value: Variant = GameState.puzzle.get("display_breaks", {})
	if display_breaks_value is Dictionary:
		return str((display_breaks_value as Dictionary).get(word, word))
	return word

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
		_mistakes.visible = true
		_lives_row.visible = true
		var maximum: int = int(SaveManager.settings.get("attempts", 4))
		_mistakes.text = SaveManager.text("mistakes_left") % [GameState.attempts_left, maximum]
		_update_lives(maximum - GameState.attempts_left, maximum)
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
	var selection_actually_changed: bool = selection != _displayed_selection
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
		if GameState.game_mode == GameState.TUTORIAL_MODE and not _tutorial_paused and _tutorial_focus_words.has(word) and not selected:
			tile.add_theme_stylebox_override("normal", _tutorial_tile_style())
			tile.add_theme_stylebox_override("hover", _tutorial_tile_style())
		_set_tile_lift(tile, false if showing_wrong else selected, was_selected != selected and not _is_placing)
	_displayed_selection.assign(selection)
	_clear.disabled = selection.is_empty() or GameState.is_finished
	_check.disabled = _tutorial_paused or not GameState.can_check_selection()
	_update_selection(selection)
	if GameState.game_mode != GameState.TUTORIAL_MODE and selection_actually_changed and not _wrong_guess_active and not _is_placing and selection != _message_selection_snapshot:
		_clear_board_message()
	if GameState.game_mode == GameState.TUTORIAL_MODE and not _tutorial_paused:
		_update_tutorial_selection_message()

func _on_group_solved(group: Dictionary) -> void:
	if GameState.game_mode != GameState.TUTORIAL_MODE:
		_clear_board_message()
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
		if row_length == 1:
			_row_reveal_tween.tween_callback(_finish_top_word_placement)
		else:
			_row_reveal_tween.tween_interval(0.24)
			_row_reveal_tween.tween_callback(func() -> void: _activate_category_card(row_length, group))
	if GameState.game_mode == GameState.TUTORIAL_MODE:
		call_deferred("_advance_tutorial_after_group", row_length)

func _on_top_solved(_word: String) -> void:
	_on_group_solved({"size": 1, "words": [str(GameState.puzzle.get("top_word", ""))]})

func _activate_category_card(row_length: int, group: Dictionary) -> void:
	if row_length == 1 or not _pyramid_rows.has(row_length) or not _placed_tiles.has(row_length):
		return
	var row: HBoxContainer = _pyramid_rows[row_length]
	for placed_tile: Button in _placed_tiles[row_length]:
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
	# The row wrapper keeps a fixed slot for the full game.  Size only the new
	# category card from that slot instead of relaying out the whole board here:
	# a full relayout during the reveal could briefly change the other tiles'
	# bounds and therefore their apparent font size/position on a phone.
	_size_category_card_for_row(category_card, row_length)
	var tween: Tween = create_tween()
	tween.tween_property(category_card, "modulate:a", 1.0, 0.20)
	_on_selection_changed(GameState.selected_words)

func _finish_top_word_placement() -> void:
	_animating_row = -1
	_is_placing = false
	_row_reveal_tween = null
	_on_selection_changed(GameState.selected_words)

func _size_category_card_for_row(category_card: PanelContainer, row_length: int) -> void:
	var row_wrapper: Control = _pyramid_row_wrappers.get(row_length) as Control
	if row_wrapper == null:
		return
	var row_size: Vector2 = row_wrapper.size
	if row_size.x <= 0.0 or row_size.y <= 0.0:
		row_size = row_wrapper.custom_minimum_size
	category_card.custom_minimum_size = row_size
	category_card.size = row_size
	_fit_category_card_text(category_card, row_size.x)

func _show_placed_row(row_length: int) -> void:
	if not _placed_tiles.has(row_length):
		return
	for placed_tile: Button in _placed_tiles[row_length]:
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
			selected.append({
				"word": word,
				"point": _to_board_point(tile.get_global_rect().get_center()),
				"size": tile.size,
				"font_size": tile.get_theme_font_size("font_size"),
			})
	for word: String in _word_buttons:
		var target_tile: Button = _word_buttons[word]
		if int(target_tile.get_meta("row_length", 0)) == row_length:
			var resting_center: Vector2 = target_tile.get_global_rect().get_center()
			# Selected blocks are visually lifted, but a solved row must always land
			# on the row's fixed resting baseline. Without this correction the final
			# destination varied depending on which target slots were selected.
			if bool(target_tile.get_meta("selection_lifted", false)):
				resting_center.y += SELECTION_LIFT
			targets.append({
				"word": word,
				"point": _to_board_point(resting_center),
				"size": target_tile.size,
				"font_size": target_tile.get_theme_font_size("font_size"),
				"row_length": row_length,
			})
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
			var fixed_font_size: int = int(source.get("font_size", _uniform_tile_font_size(fixed_size.x)))
			_fly_ghost(str(source.get("word", "")), source.get("point", fixed_point), fixed_point, fixed_size, correct_fill, correct_border, fixed_font_size, true)
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
		var source_font_size: int = int(source.get("font_size", _uniform_tile_font_size(source_size.x)))
		_fly_ghost(str(source.get("word", "")), source_point, target_point, source_size, correct_fill, correct_border, source_font_size, true)
		var target_word: String = str(target.get("word", ""))
		if target_word != str(source.get("word", "")) and not GameState.selected_words.has(target_word):
			var target_font_size: int = int(target.get("font_size", _uniform_tile_font_size(target_size.x)))
			_fly_ghost(target_word, target_point, source_point, target_size, UI_SURFACE, UI_BORDER, target_font_size)

func _fly_ghost(word: String, start: Vector2, destination: Vector2, block_size: Vector2, fill_color: Color, border_color: Color, font_size: int = -1, preserve_selected_visual: bool = false) -> void:
	var ghost: Button = Button.new()
	_configure_word_tile(ghost, word)
	ghost.name = "FlyingTile"
	ghost.position = start - block_size * 0.5
	ghost.size = block_size
	ghost.custom_minimum_size = block_size
	ghost.disabled = true
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.focus_mode = Control.FOCUS_NONE
	ghost.add_theme_font_size_override("font_size", _uniform_tile_font_size(block_size.x) if font_size < 0 else font_size)
	var style: StyleBoxFlat = _selected_tile_style() if preserve_selected_visual else _tile_style(fill_color, border_color)
	var text_color: Color = UI_PRIMARY if preserve_selected_visual else UI_TEXT
	_apply_static_tile_visual(ghost, style, text_color)
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

func _show_board_message(text: String) -> void:
	_message.text = text
	_message.visible = not text.is_empty()
	_message_selection_snapshot.assign(GameState.selected_words)

func _clear_board_message() -> void:
	_message.text = ""
	_message.visible = GameState.game_mode == GameState.TUTORIAL_MODE
	_message_selection_snapshot.assign(GameState.selected_words)

func _on_guess_failed(left: int) -> void:
	_update_mistakes()
	_show_board_message(SaveManager.text("guess_failed"))
	_highlight_incorrect_selection()
	if GameState.game_mode == GameState.TUTORIAL_MODE and _tutorial_stage >= 5 and left > 0:
		_show_tutorial_wrong_answer_help.call_deferred(_tutorial_stage)

func _show_tutorial_wrong_answer_help(stage: int) -> void:
	await get_tree().create_timer(WRONG_SHAKE_DURATION + 0.12).timeout
	if not is_inside_tree() or GameState.game_mode != GameState.TUTORIAL_MODE or _tutorial_stage != stage or GameState.is_finished:
		return
	_apply_tutorial_wrong_answer_help()

func _on_repeated_guess_attempted() -> void:
	_show_board_message(SaveManager.text("repeated_guess"))

func _on_guess_feedback(text: String) -> void:
	_show_board_message(text)

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
		text_color = UI_PRIMARY
	else:
		style = _tile_style(UI_SURFACE, UI_BORDER)
		text_color = UI_TEXT
	_apply_static_tile_visual(tile, style, text_color)
	tile.add_theme_stylebox_override("hover", style if selected or wrong else _tile_style(UI_SURFACE, Color("a89dd4")))

func _apply_static_tile_visual(tile: Button, style: StyleBoxFlat, text_color: Color) -> void:
	# Apply one geometry-identical style to every state. A tile can be disabled
	# while it is placed or flying, but that state must never change its margins,
	# font metrics, or outer block dimensions.
	for state: String in ["normal", "pressed", "hover_pressed", "disabled", "hover", "focus"]:
		tile.add_theme_stylebox_override(state, style)
	_apply_tile_text_colors(tile, text_color)
	tile.add_theme_color_override("font_disabled_color", text_color)

func _selected_tile_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _tile_style(SELECTED_FILL, SELECTED_BORDER)
	style.set_border_width_all(2)
	style.shadow_color = Color(1.0, 0.84, 0.0, 0.30)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 6)
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

func _tutorial_completion_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = UI_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.10, 0.04, 0.37, 0.16)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 10)
	return style

func _on_game_finished(won: bool, _top_word: String) -> void:
	if _aftermath_scheduled or is_instance_valid(_aftermath_layer):
		return
	var should_wait_for_board: bool = _game_was_running
	_game_was_running = false
	_fresh_result_reveal = should_wait_for_board
	_aftermath_scheduled = true
	for tile: Button in _word_buttons.values():
		tile.disabled = true
	_debug_auto_solve.visible = false
	_hint.visible = false
	_check.visible = false
	_result.visible = false
	_share.visible = false
	if won:
		_clear_board_message()
	else:
		_show_board_message(SaveManager.text("game_failed"))
	_update_mistakes()
	if won and should_wait_for_board:
		SoundManager.game_complete()
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
	_debug_auto_solve.visible = false
	_debug_auto_solve.disabled = GameState.is_auto_solving

func _on_debug_auto_solve_pressed() -> void:
	if GameState.is_finished or GameState.is_auto_solving:
		return
	_debug_auto_solve.disabled = true
	_debug_auto_solve.visible = false
	_hint.disabled = true
	_check.disabled = true
	GameState.debug_auto_solve()

func _show_result_actions() -> void:
	_hint.visible = false
	_check.visible = false
	_clear.visible = false
	_result.visible = true
	_share.visible = true
	_result.disabled = false
	_share.disabled = false
	_result.text = "▦  " + _result_score_text()

func _result_score_text() -> String:
	var correct: int = max(GameState.result_correct_count, 0)
	var total: int = max(GameState.result_total_count(), correct)
	return SaveManager.text("result_score") % [correct, total]

func _on_result_pressed() -> void:
	_aftermath_scheduled = false
	_show_aftermath(GameState.completed_won)

func _on_share_pressed() -> void:
	DisplayServer.clipboard_set(GameState.build_share_text())
	_show_board_message(SaveManager.text("result_copied"))

func _show_aftermath(won: bool) -> void:
	if is_instance_valid(_aftermath_layer):
		if not _aftermath_dismissing:
			_aftermath_layer.modulate.a = 1.0
			if is_instance_valid(_aftermath_stack):
				_aftermath_stack.position.y = 0.0
		return
	var correct: int = max(GameState.result_correct_count, 0)
	var total: int = max(GameState.result_total_count(), correct)
	var is_endless: bool = GameState.game_mode == GameState.UNLIMITED_MODE
	var unlimited_pool_complete: bool = is_endless and GameState.is_puzzle_pool_completed(GameState.UNLIMITED_MODE)
	var is_endless_loss: bool = is_endless and not won
	var max_attempts: int = int(SaveManager.settings.get("attempts", 4))
	var mistakes: int = clampi(max_attempts - GameState.attempts_left, 0, max_attempts)
	var solved_row_count: int = 5 if won else clampi(GameState.result_solved_groups.size() + (1 if GameState.result_top_solved else 0), 0, 5)

	var layer: Control = Control.new()
	layer.name = "AftermathLayer"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.modulate.a = 0.0
	layer.z_index = 200
	add_child(layer)
	_aftermath_layer = layer

	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = UI_BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(backdrop)
	_add_aftermath_background_decor(layer)

	var stack: VBoxContainer = VBoxContainer.new()
	_aftermath_stack = stack
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(stack)

	var sheet: PanelContainer = PanelContainer.new()
	_aftermath_sheet = sheet
	sheet.add_theme_stylebox_override("panel", _aftermath_fullscreen_style())
	sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sheet.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sheet.gui_input.connect(_on_aftermath_drag_input)
	stack.add_child(sheet)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	sheet.add_child(margin)
	var page: VBoxContainer = VBoxContainer.new()
	page.name = "AftermathPage"
	page.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_theme_constant_override("separation", 10)
	margin.add_child(page)

	var eyebrow_row: HBoxContainer = HBoxContainer.new()
	page.add_child(eyebrow_row)
	var mode_chip: PanelContainer = PanelContainer.new()
	mode_chip.add_theme_stylebox_override("panel", _aftermath_mode_chip_style())
	mode_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	eyebrow_row.add_child(mode_chip)
	var chip_margin: MarginContainer = MarginContainer.new()
	chip_margin.add_theme_constant_override("margin_left", 10)
	chip_margin.add_theme_constant_override("margin_right", 10)
	chip_margin.add_theme_constant_override("margin_top", 5)
	chip_margin.add_theme_constant_override("margin_bottom", 5)
	mode_chip.add_child(chip_margin)
	var mode_text: String = SaveManager.text("unlimited_mode_label") if is_endless else SaveManager.text("daily_challenge_label")
	chip_margin.add_child(_aftermath_label(mode_text.to_upper(), 10, UI_PRIMARY, _font_dm_sans_semibold))
	var eyebrow_spacer: Control = Control.new()
	eyebrow_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eyebrow_row.add_child(eyebrow_spacer)
	var brand: Label = _aftermath_label("WORD PYRAMID", 11, UI_MUTED_TEXT, _font_dm_sans_semibold)
	brand.size_flags_horizontal = Control.SIZE_SHRINK_END
	eyebrow_row.add_child(brand)

	var title: Label = _aftermath_label(SaveManager.text("aftermath_win_title") if won else SaveManager.text("aftermath_loss_title"), 31, UI_PRIMARY, _font_fredoka_bold)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(title)
	var subtitle_text: String
	if won:
		subtitle_text = SaveManager.text("aftermath_flawless") if mistakes == 0 else SaveManager.text("aftermath_solved_mistakes") % mistakes
	elif is_endless_loss:
		subtitle_text = SaveManager.text("aftermath_endless_better_luck")
	else:
		subtitle_text = SaveManager.text("aftermath_loss_subtitle") % [correct, total]
	var subtitle: Label = _aftermath_label(subtitle_text, 13, Color("5d5286"), FONT_DM_SANS)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(subtitle)

	var result_card: PanelContainer = PanelContainer.new()
	result_card.name = "ResultCard"
	result_card.add_theme_stylebox_override("panel", _aftermath_result_card_style(won))
	result_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(result_card)
	var card_margin: MarginContainer = MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 16)
	card_margin.add_theme_constant_override("margin_right", 16)
	card_margin.add_theme_constant_override("margin_top", 16)
	card_margin.add_theme_constant_override("margin_bottom", 16)
	result_card.add_child(card_margin)
	var card: VBoxContainer = VBoxContainer.new()
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_theme_constant_override("separation", 10)
	card_margin.add_child(card)

	var score_badge: PanelContainer = PanelContainer.new()
	score_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	score_badge.add_theme_stylebox_override("panel", _aftermath_score_badge_style())
	card.add_child(score_badge)
	var score_margin: MarginContainer = MarginContainer.new()
	score_margin.add_theme_constant_override("margin_left", 20)
	score_margin.add_theme_constant_override("margin_right", 20)
	score_margin.add_theme_constant_override("margin_top", 8)
	score_margin.add_theme_constant_override("margin_bottom", 8)
	score_badge.add_child(score_margin)
	var solved_group_score: Label = _aftermath_label("%d / 5  %s" % [solved_row_count, SaveManager.text("stat_rows").to_lower()], 20, UI_PRIMARY, _font_fredoka_bold)
	solved_group_score.name = "SolvedGroupScore"
	var score_stack: VBoxContainer = VBoxContainer.new()
	score_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	score_stack.add_theme_constant_override("separation", 2)
	score_margin.add_child(score_stack)
	score_stack.add_child(solved_group_score)
	var progression_reward: Dictionary = GameState.result_progression
	var total_xp_after: int = int(progression_reward.get("total_xp_after", SaveManager.get_total_xp()))
	var level_after: int = int(progression_reward.get("level_after", SaveManager.get_player_level(total_xp_after)))
	var xp_gained: int = int(progression_reward.get("xp_gained", 0))
	var total_xp_before: int = int(progression_reward.get("total_xp_before", maxi(total_xp_after - xp_gained, 0)))
	var level_before: int = int(progression_reward.get("level_before", level_after))
	var final_xp_copy: String = SaveManager.text("level_up") % level_after if level_after > level_before else SaveManager.text("level_short") % level_after
	if xp_gained > 0:
		final_xp_copy = "%s · %s" % [SaveManager.text("xp_earned") % xp_gained, final_xp_copy]
	var xp_reward_label: Label = _aftermath_label(final_xp_copy, 11, Color("67569e"), _font_dm_sans_semibold)
	xp_reward_label.name = "XpRewardLabel"
	score_stack.add_child(xp_reward_label)
	var level_progress: Dictionary = SaveManager.get_level_progress(total_xp_before if xp_gained > 0 else total_xp_after)
	var xp_progress: ProgressBar = ProgressBar.new()
	xp_progress.name = "XpProgress"
	xp_progress.custom_minimum_size = Vector2(180, 6)
	xp_progress.max_value = float(level_progress.get("required", 1))
	xp_progress.value = float(level_progress.get("current", 0))
	xp_progress.show_percentage = false
	var xp_background: StyleBoxFlat = StyleBoxFlat.new()
	xp_background.bg_color = Color("ded5f1")
	xp_background.corner_radius_top_left = 3
	xp_background.corner_radius_top_right = 3
	xp_background.corner_radius_bottom_left = 3
	xp_background.corner_radius_bottom_right = 3
	var xp_fill: StyleBoxFlat = xp_background.duplicate()
	xp_fill.bg_color = UI_MAGENTA
	xp_progress.add_theme_stylebox_override("background", xp_background)
	xp_progress.add_theme_stylebox_override("fill", xp_fill)
	xp_progress.set_meta("animation_from_total_xp", total_xp_before)
	xp_progress.set_meta("animation_to_total_xp", total_xp_after)
	score_stack.add_child(xp_progress)
	if xp_gained > 0:
		_update_aftermath_xp_display(total_xp_before, xp_reward_label, xp_progress, total_xp_before, xp_gained)

	card.add_child(_build_aftermath_result_pyramid())

	var streak_panel: PanelContainer = PanelContainer.new()
	streak_panel.add_theme_stylebox_override("panel", _aftermath_streak_style())
	streak_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(streak_panel)
	var streak_margin: MarginContainer = MarginContainer.new()
	streak_margin.add_theme_constant_override("margin_left", 14)
	streak_margin.add_theme_constant_override("margin_right", 14)
	streak_margin.add_theme_constant_override("margin_top", 10)
	streak_margin.add_theme_constant_override("margin_bottom", 10)
	streak_panel.add_child(streak_margin)
	var streak_box: BoxContainer = VBoxContainer.new() if is_endless else HBoxContainer.new()
	streak_box.alignment = BoxContainer.ALIGNMENT_CENTER
	streak_box.add_theme_constant_override("separation", 10)
	streak_margin.add_child(streak_box)
	var has_daily_streak: bool = not is_endless
	var play_streak_animation: bool = has_daily_streak and not GameState.is_debug_completion and SaveManager.consume_daily_streak_animation(GameState.daily_date)
	var flame: TextureRect = TextureRect.new()
	flame.name = "StreakFlame"
	flame.texture = ICON_FLAME
	flame.custom_minimum_size = Vector2(32, 40)
	flame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flame.visible = has_daily_streak
	flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	streak_box.add_child(flame)
	var losing_heart: Control = null
	if is_endless:
		var aftermath_hearts: HBoxContainer = HBoxContainer.new()
		aftermath_hearts.name = "AftermathHearts"
		aftermath_hearts.alignment = BoxContainer.ALIGNMENT_CENTER
		aftermath_hearts.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		aftermath_hearts.add_theme_constant_override("separation", 6)
		streak_box.add_child(aftermath_hearts)
		var current_hearts: int = SaveManager.get_endless_hearts()
		for index: int in range(SaveManager.ENDLESS_DAILY_HEARTS):
			var heart: TextureRect = _create_aftermath_heart(index, index < current_hearts)
			if is_endless_loss and index == current_hearts:
				heart.modulate = UI_RED
				losing_heart = heart
			aftermath_hearts.add_child(heart)
	var streak_copy: VBoxContainer = VBoxContainer.new()
	streak_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	streak_copy.add_theme_constant_override("separation", 0)
	streak_box.add_child(streak_copy)
	var streak_to: int = SaveManager.get_daily_streak(GameState.daily_date) if has_daily_streak else 0
	var streak_from: int = max(streak_to - 1, 0) if won and has_daily_streak else SaveManager.get_daily_streak_before(GameState.daily_date) if has_daily_streak else 0
	var visible_streak: int = streak_from if play_streak_animation or not won else streak_to
	var heart_count: int = SaveManager.get_endless_hearts() if is_endless else 0
	var endless_count_text: String = SaveManager.text("endless_hearts_remaining") % heart_count if heart_count > 0 else SaveManager.text("endless_out_of_hearts")
	var streak_number: Label = _aftermath_label(str(visible_streak) if has_daily_streak else endless_count_text, 36 if has_daily_streak else 16, UI_YELLOW if has_daily_streak else Color.WHITE, _font_fredoka_bold)
	streak_number.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	streak_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	streak_copy.add_child(streak_number)
	var streak_caption_text: String = SaveManager.endless_reset_countdown_text()
	if has_daily_streak:
		var visible_caption_streak: int = streak_from if play_streak_animation else streak_to
		streak_caption_text = SaveManager.text("aftermath_streak_current") % visible_caption_streak if won else SaveManager.text("aftermath_streak_lost")
	var streak_caption: Label = _aftermath_label(streak_caption_text, 12, Color(1, 1, 1, 0.70), _font_fredoka_semibold)
	streak_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	streak_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	streak_copy.add_child(streak_caption)
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
	stats_row.add_theme_constant_override("separation", 8)
	card.add_child(stats_row)
	stats_row.add_child(_stat_pill(SaveManager.text("stat_mistakes"), str(mistakes), UI_YELLOW if mistakes == 0 else Color("ff8066")))
	stats_row.add_child(_stat_pill(SaveManager.text("stat_rows"), "%d / 5" % solved_row_count, UI_TEAL))
	stats_row.add_child(_stat_pill(SaveManager.text("stat_hints_used"), str(GameState.hints_used), UI_MAGENTA))
	if unlimited_pool_complete:
		var complete_panel: PanelContainer = PanelContainer.new()
		complete_panel.name = "UnlimitedPoolCompletePanel"
		complete_panel.add_theme_stylebox_override("panel", _aftermath_streak_style())
		complete_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(complete_panel)
		var complete_margin: MarginContainer = MarginContainer.new()
		complete_margin.add_theme_constant_override("margin_left", 12)
		complete_margin.add_theme_constant_override("margin_right", 12)
		complete_margin.add_theme_constant_override("margin_top", 7)
		complete_margin.add_theme_constant_override("margin_bottom", 7)
		complete_panel.add_child(complete_margin)
		var complete_copy: VBoxContainer = VBoxContainer.new()
		complete_copy.add_theme_constant_override("separation", 0)
		complete_margin.add_child(complete_copy)
		var complete_title: Label = _aftermath_label(SaveManager.text("unlimited_pool_complete_title"), 14, UI_YELLOW, _font_fredoka_bold)
		complete_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		complete_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		complete_copy.add_child(complete_title)
		var complete_body: Label = _aftermath_label(SaveManager.text("unlimited_pool_complete_body"), 10, Color(1, 1, 1, 0.72), FONT_DM_SANS)
		complete_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		complete_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		complete_copy.add_child(complete_body)

	var primary_button: Button
	var can_continue_to_endless: bool = not is_endless and SaveManager.can_start_endless()
	if is_endless:
		if unlimited_pool_complete:
			primary_button = _aftermath_button(SaveManager.text("back_to_home"), true, true)
			_set_aftermath_button_icon(primary_button, ICON_HOME)
			primary_button.pressed.connect(func() -> void: request_menu.emit())
		elif heart_count > 0:
			primary_button = _aftermath_button(SaveManager.text("continue_to_next"), true, true)
			primary_button.pressed.connect(_on_endless_next_puzzle_pressed)
		elif SaveManager.can_claim_rewarded_endless_heart():
			primary_button = _aftermath_button(SaveManager.text("endless_watch_ad"), true, true)
			primary_button.pressed.connect(AdManager.request_rewarded_heart)
		else:
			primary_button = _aftermath_button(SaveManager.text("endless_ad_claimed"), true, true)
			primary_button.disabled = true
	elif can_continue_to_endless:
		primary_button = _aftermath_button(SaveManager.text("continue_to_unlimited"), true, true)
		primary_button.pressed.connect(_on_daily_continue_to_unlimited_pressed)
	else:
		primary_button = _aftermath_button(SaveManager.text("share_result"), true, true)
		_set_aftermath_button_icon(primary_button, ICON_SHARE)
		primary_button.pressed.connect(func() -> void:
			_on_share_pressed()
			primary_button.text = SaveManager.text("result_copied")
		)
	card.add_child(primary_button)
	primary_button.name = "PrimaryAction"

	var secondary_row: HBoxContainer = HBoxContainer.new()
	secondary_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	secondary_row.add_theme_constant_override("separation", 8)
	card.add_child(secondary_row)
	if is_endless or can_continue_to_endless:
		var share_button: Button = _aftermath_button(SaveManager.text("share_result"), false)
		share_button.name = "ShareButton"
		_set_aftermath_button_icon(share_button, ICON_SHARE)
		share_button.pressed.connect(func() -> void:
			_on_share_pressed()
			share_button.text = SaveManager.text("result_copied")
		)
		secondary_row.add_child(share_button)
	if not unlimited_pool_complete:
		var menu_button: Button = _aftermath_button(SaveManager.text("menu"), false)
		menu_button.name = "MenuButton"
		_set_aftermath_button_icon(menu_button, ICON_HOME)
		menu_button.pressed.connect(func() -> void: request_menu.emit())
		secondary_row.add_child(menu_button)

	await get_tree().process_frame
	if not is_instance_valid(sheet) or not is_instance_valid(layer):
		return
	flame.pivot_offset = flame.size * 0.5
	streak_number.pivot_offset = streak_number.size * 0.5
	stack.position.y = size.y * 0.06
	_aftermath_open_tween = create_tween().set_parallel(true)
	_aftermath_open_tween.tween_property(layer, "modulate:a", 1.0, 0.24)
	_aftermath_open_tween.tween_property(stack, "position:y", 0.0, 0.40).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var play_xp_sound: bool = _fresh_result_reveal
	var play_level_up_sound: bool = _fresh_result_reveal and level_after > level_before
	_fresh_result_reveal = false
	_animate_aftermath_xp(
		layer,
		xp_reward_label,
		xp_progress,
		total_xp_before,
		total_xp_after,
		xp_gained,
		final_xp_copy,
		level_after,
		play_xp_sound,
		play_level_up_sound
	)
	if won and play_streak_animation:
		_animate_streak_win(layer, flame, streak_number, streak_caption, streak_from, streak_to)
	elif not won and play_streak_animation:
		_animate_streak_loss(layer, flame, streak_number, streak_caption, crack_overlay, streak_crack)
	elif not won and has_daily_streak:
		_apply_streak_loss_final(flame, streak_number, crack_overlay, streak_crack)
	elif is_endless_loss and is_instance_valid(losing_heart):
		_animate_endless_heart_loss(layer, losing_heart)

func _show_aftermath_legacy(won: bool) -> void:
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
	var legacy_solved_rows: int = clampi(GameState.result_solved_groups.size() + (1 if GameState.result_top_solved else 0), 0, 5)
	stats_row.add_child(_stat_pill(SaveManager.text("stat_rows"), "%d / 5" % legacy_solved_rows, UI_TEAL))
	stats_row.add_child(_stat_pill(SaveManager.text("stat_hints_used"), str(GameState.hints_used), UI_MAGENTA))

	var primary_button: Button
	var can_continue_to_endless: bool = not is_endless and SaveManager.can_start_endless()
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
	elif can_continue_to_endless:
		primary_button = _aftermath_button(SaveManager.text("continue_to_unlimited"), true, won)
		primary_button.pressed.connect(_on_daily_continue_to_unlimited_pressed)
	else:
		primary_button = _aftermath_button(SaveManager.text("share_result"), true, won)
		primary_button.pressed.connect(func() -> void:
			_on_share_pressed()
			primary_button.text = SaveManager.text("result_copied")
		)
	content.add_child(primary_button)
	if can_continue_to_endless:
		var secondary_row: HBoxContainer = HBoxContainer.new()
		secondary_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		secondary_row.add_theme_constant_override("separation", 10)
		content.add_child(secondary_row)
		var share_button: Button = _aftermath_button(SaveManager.text("share_result"), false)
		share_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		share_button.pressed.connect(func() -> void:
			_on_share_pressed()
			share_button.text = SaveManager.text("result_copied")
		)
		secondary_row.add_child(share_button)
		var home_button: Button = _aftermath_button(SaveManager.text("menu"), false)
		home_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		home_button.pressed.connect(func() -> void: request_menu.emit())
		secondary_row.add_child(home_button)
	else:
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

func _create_aftermath_heart(index: int, filled: bool) -> TextureRect:
	var heart: TextureRect = TextureRect.new()
	heart.name = "AftermathHeart%d" % (index + 1)
	heart.texture = ICON_HEART
	heart.custom_minimum_size = Vector2(26, 24)
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart.modulate = UI_RED if filled else Color(0.79, 0.76, 0.85, 0.42)
	return heart

func _animate_endless_heart_loss(layer: Control, heart: Control) -> void:
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
	collapse.tween_callback(func() -> void:
		if is_instance_valid(heart):
			heart.modulate = Color(0.79, 0.76, 0.85, 0.42)
	)

func _animate_streak_win(layer: Control, flame: Control, streak_number: Label, streak_caption: Label, streak_from: int, streak_to: int) -> void:
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

func _animate_streak_loss(layer: Control, flame: Control, streak_number: Label, streak_caption: Label, crack_overlay: Control, streak_crack: ColorRect) -> void:
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

func _apply_streak_loss_final(flame: Control, streak_number: Label, crack_overlay: Control, streak_crack: ColorRect) -> void:
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

func _stop_aftermath_motion(stop_xp: bool = false) -> void:
	if _aftermath_open_tween != null and _aftermath_open_tween.is_running():
		_aftermath_open_tween.kill()
	if _aftermath_snap_tween != null and _aftermath_snap_tween.is_running():
		_aftermath_snap_tween.kill()
	if stop_xp and _aftermath_xp_tween != null and _aftermath_xp_tween.is_running():
		_aftermath_xp_tween.kill()

func _animate_aftermath_xp(layer: Control, label: Label, progress: ProgressBar, total_before: int, total_after: int, xp_gained: int, final_text: String, level_after: int, play_xp_sound: bool, play_level_up_sound: bool) -> void:
	if xp_gained <= 0 or total_after <= total_before:
		return
	_aftermath_xp_tween = create_tween()
	_aftermath_xp_tween.tween_interval(XP_REWARD_ANIMATION_DELAY)
	_aftermath_xp_tween.tween_callback(func() -> void:
		if play_xp_sound and is_instance_valid(layer) and layer == _aftermath_layer:
			SoundManager.xp_gain()
	)
	_aftermath_xp_tween.tween_method(
		func(animated_total: float) -> void:
			if is_instance_valid(layer) and layer == _aftermath_layer and is_instance_valid(label) and is_instance_valid(progress):
				_update_aftermath_xp_display(roundi(animated_total), label, progress, total_before, xp_gained),
		float(total_before),
		float(total_after),
		XP_REWARD_ANIMATION_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_aftermath_xp_tween.tween_callback(func() -> void:
		if is_instance_valid(layer) and layer == _aftermath_layer and is_instance_valid(label):
			label.text = final_text
			if play_level_up_sound:
				_play_level_up_celebration(layer, progress, level_after)
	)

func _play_level_up_celebration(layer: Control, progress: ProgressBar, level: int) -> void:
	if not is_instance_valid(layer) or layer != _aftermath_layer:
		return
	if is_instance_valid(_level_up_overlay):
		_level_up_overlay.queue_free()
	SoundManager.level_up()
	Input.vibrate_handheld(38)

	var overlay: Control = Control.new()
	overlay.name = "LevelUpCelebration"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 360
	layer.add_child(overlay)
	_level_up_overlay = overlay

	var focus_dim: ColorRect = ColorRect.new()
	focus_dim.color = Color(UI_PRIMARY, 0.0)
	focus_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(focus_dim)
	var focus_tween: Tween = overlay.create_tween()
	focus_tween.tween_property(focus_dim, "color:a", 0.13, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	focus_tween.tween_interval(0.86)
	focus_tween.tween_property(focus_dim, "color:a", 0.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var flash: ColorRect = ColorRect.new()
	flash.color = Color(UI_YELLOW, 0.0)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(flash)
	var flash_tween: Tween = overlay.create_tween()
	flash_tween.tween_property(flash, "color:a", 0.20, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash, "color:a", 0.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var center: Vector2 = layer.size * 0.5
	var halo: Panel = _level_up_circle("LevelUpHalo", center, 190.0, Color(UI_YELLOW, 0.24), Color.TRANSPARENT, 0)
	halo.scale = Vector2(0.52, 0.52)
	halo.modulate.a = 0.0
	overlay.add_child(halo)
	var halo_tween: Tween = overlay.create_tween().set_parallel(true)
	halo_tween.tween_property(halo, "modulate:a", 1.0, 0.12)
	halo_tween.tween_property(halo, "scale", Vector2(1.52, 1.52), 0.72).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	halo_tween.tween_property(halo, "modulate:a", 0.0, 0.46).set_delay(0.26)

	var ring: Panel = _level_up_circle("LevelUpRing", center, 164.0, Color.TRANSPARENT, UI_YELLOW, 4)
	ring.scale = Vector2(0.72, 0.72)
	ring.modulate.a = 0.85
	overlay.add_child(ring)
	var ring_tween: Tween = overlay.create_tween().set_parallel(true)
	ring_tween.tween_property(ring, "scale", Vector2(1.42, 1.42), 0.62).set_delay(0.06).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	ring_tween.tween_property(ring, "modulate:a", 0.0, 0.44).set_delay(0.24)

	_spawn_level_up_confetti(overlay, center)
	var badge: PanelContainer = _build_level_up_badge(level)
	badge.set_anchors_preset(Control.PRESET_CENTER)
	badge.offset_left = -116.0
	badge.offset_top = -82.0
	badge.offset_right = 116.0
	badge.offset_bottom = 82.0
	badge.pivot_offset = Vector2(116.0, 82.0)
	badge.scale = Vector2(0.62, 0.62)
	badge.rotation = deg_to_rad(-4.0)
	badge.modulate.a = 0.0
	overlay.add_child(badge)
	var level_number: Label = badge.find_child("LevelNumber", true, false) as Label

	var badge_scale_tween: Tween = overlay.create_tween()
	badge_scale_tween.tween_property(badge, "scale", Vector2(1.13, 1.13), 0.31).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	badge_scale_tween.tween_property(badge, "scale", Vector2(0.985, 0.985), 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	badge_scale_tween.tween_property(badge, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	badge_scale_tween.tween_interval(0.48)
	badge_scale_tween.tween_property(badge, "scale", Vector2(1.035, 1.035), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	var badge_visual_tween: Tween = overlay.create_tween().set_parallel(true)
	badge_visual_tween.tween_property(badge, "modulate:a", 1.0, 0.12)
	badge_visual_tween.tween_property(badge, "rotation", deg_to_rad(1.4), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	badge_visual_tween.tween_property(badge, "rotation", 0.0, 0.18).set_delay(0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	badge_visual_tween.tween_property(badge, "modulate:a", 0.0, 0.25).set_delay(1.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_animate_level_up_number.call_deferred(overlay, level_number)

	if is_instance_valid(progress):
		progress.pivot_offset = progress.size * 0.5
		var progress_tween: Tween = layer.create_tween()
		progress_tween.tween_property(progress, "scale", Vector2(1.035, 1.75), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		progress_tween.tween_property(progress, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var cleanup_tween: Tween = overlay.create_tween()
	cleanup_tween.tween_interval(1.38)
	cleanup_tween.tween_callback(_finish_level_up_celebration.bind(overlay))

func _build_level_up_badge(level: int) -> PanelContainer:
	var badge: PanelContainer = PanelContainer.new()
	badge.name = "LevelUpBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UI_PRIMARY
	style.border_color = UI_YELLOW
	style.set_border_width_all(3)
	style.set_corner_radius_all(30)
	style.shadow_color = Color(0.05, 0.015, 0.20, 0.34)
	style.shadow_size = 20
	style.shadow_offset = Vector2(0, 10)
	badge.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	badge.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 0)
	margin.add_child(content)
	var title: Label = _aftermath_label(SaveManager.text("level_up_title"), 22, UI_YELLOW, _font_fredoka_bold)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var level_number: Label = _aftermath_label(str(level), 64, Color.WHITE, _font_fredoka_bold)
	level_number.name = "LevelNumber"
	level_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_number.modulate.a = 0.0
	level_number.add_theme_constant_override("outline_size", 5)
	level_number.add_theme_color_override("font_outline_color", Color(0.06, 0.02, 0.24, 0.72))
	content.add_child(level_number)
	var caption_text: String = SaveManager.text("daily_unlocked_reward") if level == SaveManager.DAILY_UNLOCK_LEVEL else SaveManager.text("level_up_new_level")
	var caption: Label = _aftermath_label(caption_text, 11, UI_YELLOW if level == SaveManager.DAILY_UNLOCK_LEVEL else Color(1, 1, 1, 0.70), _font_dm_sans_semibold)
	caption.name = "LevelReward"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(caption)
	return badge

func _animate_level_up_number(overlay: Control, level_number: Label) -> void:
	if not is_instance_valid(overlay) or not is_instance_valid(level_number):
		return
	level_number.pivot_offset = level_number.size * 0.5
	level_number.scale = Vector2(0.48, 0.48)
	var number_tween: Tween = overlay.create_tween().set_parallel(true)
	number_tween.tween_property(level_number, "modulate:a", 1.0, 0.10).set_delay(0.10)
	number_tween.tween_property(level_number, "scale", Vector2(1.16, 1.16), 0.27).set_delay(0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	number_tween.tween_property(level_number, "scale", Vector2.ONE, 0.14).set_delay(0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _level_up_circle(node_name: String, center: Vector2, diameter: float, fill: Color, border: Color, border_width: int) -> Panel:
	var circle: Panel = Panel.new()
	circle.name = node_name
	circle.position = center - Vector2.ONE * diameter * 0.5
	circle.size = Vector2.ONE * diameter
	circle.pivot_offset = Vector2.ONE * diameter * 0.5
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(roundi(diameter * 0.5))
	circle.add_theme_stylebox_override("panel", style)
	return circle

func _spawn_level_up_confetti(parent: Control, origin: Vector2) -> void:
	var colors: Array[Color] = [UI_YELLOW, UI_RED, UI_TEAL, UI_MAGENTA, Color("cbbdf5"), Color.WHITE]
	for index: int in 22:
		var angle: float = TAU * float(index) / 22.0 + (0.10 if index % 2 == 0 else -0.06)
		var distance: float = 116.0 + float((index * 17) % 54)
		var piece_size: Vector2 = Vector2(6.0 + float(index % 3) * 2.0, 10.0 + float((index + 1) % 3) * 2.0)
		var piece: ColorRect = ColorRect.new()
		piece.name = "Confetti%02d" % index
		piece.color = colors[index % colors.size()]
		piece.size = piece_size
		piece.position = origin - piece_size * 0.5
		piece.pivot_offset = piece_size * 0.5
		piece.scale = Vector2(0.25, 0.25)
		piece.rotation = angle * 0.35
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(piece)
		var destination: Vector2 = origin + Vector2(cos(angle), sin(angle)) * distance + Vector2(0, 32.0)
		var delay: float = 0.03 + float(index % 5) * 0.012
		var move_tween: Tween = parent.create_tween().set_parallel(true)
		move_tween.tween_property(piece, "position", destination - piece_size * 0.5, 0.82 + float(index % 4) * 0.04).set_delay(delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		move_tween.tween_property(piece, "scale", Vector2.ONE, 0.16).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		move_tween.tween_property(piece, "rotation", piece.rotation + deg_to_rad(210.0 + float(index % 4) * 55.0), 0.92).set_delay(delay)
		move_tween.tween_property(piece, "modulate:a", 0.0, 0.36).set_delay(0.62 + delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _finish_level_up_celebration(overlay: Control) -> void:
	if _level_up_overlay == overlay:
		_level_up_overlay = null
	if is_instance_valid(overlay):
		overlay.queue_free()

func _update_aftermath_xp_display(animated_total: int, label: Label, progress: ProgressBar, total_before: int, xp_gained: int) -> void:
	var current_total: int = clampi(animated_total, total_before, total_before + xp_gained)
	var gained_so_far: int = current_total - total_before
	var level_progress: Dictionary = SaveManager.get_level_progress(current_total)
	var current_level: int = int(level_progress.get("level", 1))
	progress.max_value = float(level_progress.get("required", 1))
	progress.value = float(level_progress.get("current", 0))
	label.text = "%s / %s · %s" % [
		SaveManager.text("xp_earned") % gained_so_far,
		SaveManager.text("xp_earned") % xp_gained,
		SaveManager.text("level_short") % current_level,
	]

func _dismiss_aftermath() -> void:
	if _aftermath_dismissing or not is_instance_valid(_aftermath_layer):
		return
	_aftermath_dismissing = true
	_aftermath_dragging = false
	_stop_aftermath_motion(true)
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
	_aftermath_xp_tween = null
	_aftermath_dismissing = false

func _on_endless_next_puzzle_pressed() -> void:
	await _dismiss_aftermath()
	request_new_game.emit()

func _on_daily_continue_to_unlimited_pressed() -> void:
	request_mode_transition.emit(GameState.UNLIMITED_MODE)

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
	_show_board_message(SaveManager.text("pool_complete") % pool_name)

func _on_hint_provided(text: String) -> void:
	_show_board_message(text)

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
	if GameState.game_mode == GameState.TUTORIAL_MODE and _tutorial_stage == 2:
		_tutorial_stage = 3
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
		_hint.disabled = _tutorial_stage != 2

func _apply_tutorial_stage() -> void:
	if GameState.game_mode != GameState.TUTORIAL_MODE or GameState.is_finished:
		return
	_tutorial_help_level = 0
	_tutorial_target_words.clear()
	_tutorial_focus_words.clear()
	var allowed: Array[String] = []
	var guide_text: String = SaveManager.text("tutorial_first_group")
	if is_instance_valid(_tutorial_guide_button):
		_tutorial_guide_button.visible = false
	match _tutorial_stage:
		0:
			_tutorial_target_words = _tutorial_selectable_words(2)
			allowed.assign(_tutorial_target_words)
			_tutorial_focus_words.assign(_tutorial_target_words)
		1:
			guide_text = SaveManager.text("tutorial_mistakes_body")
		2:
			guide_text = SaveManager.text("tutorial_use_hint")
		3:
			_tutorial_target_words = _tutorial_selectable_words(5)
			allowed.assign(_tutorial_target_words)
			_tutorial_focus_words.assign(_tutorial_target_words)
			guide_text = SaveManager.text("tutorial_finish_hint_row")
		4:
			_tutorial_target_words = _tutorial_selectable_words(1)
			allowed.assign(_tutorial_target_words)
			_tutorial_focus_words.assign(_tutorial_target_words)
			guide_text = SaveManager.text("tutorial_top_any_order")
		5:
			_tutorial_target_words = _tutorial_selectable_words(3)
			if _tutorial_independent_intro_pending:
				guide_text = SaveManager.text("tutorial_independent_three_intro")
				if is_instance_valid(_tutorial_guide_button):
					_tutorial_guide_button.visible = true
			else:
				allowed = _tutorial_all_selectable_words()
				guide_text = SaveManager.text("tutorial_find_three")
		6:
			_tutorial_target_words = _tutorial_selectable_words(4)
			if _tutorial_independent_intro_pending:
				guide_text = SaveManager.text("tutorial_independent_last_intro")
				if is_instance_valid(_tutorial_guide_button):
					_tutorial_guide_button.visible = true
			else:
				allowed = _tutorial_all_selectable_words()
				guide_text = SaveManager.text("tutorial_find_last")
	GameState.set_tutorial_allowed_words(allowed)
	_hint.disabled = _tutorial_paused or _tutorial_stage != 2
	_check.disabled = _tutorial_paused or not GameState.can_check_selection()
	_update_mistakes()
	if not _tutorial_paused:
		_message.text = guide_text
	_update_tutorial_spotlight()
	if not _tutorial_paused and _tutorial_stage == 1:
		call_deferred("_show_tutorial_mistakes_feature")
	elif not _tutorial_paused and _tutorial_stage == 2:
		call_deferred("_show_tutorial_hint_feature")

func _tutorial_selectable_words(row_length: int) -> Array[String]:
	var result: Array[String] = []
	for word: String in GameState.tutorial_group_words(row_length):
		if _word_buttons.has(word):
			result.append(word)
	return result

func _tutorial_all_selectable_words() -> Array[String]:
	var result: Array[String] = []
	for word: String in _word_order:
		if _word_buttons.has(word):
			result.append(word)
	return result

func _apply_tutorial_wrong_answer_help() -> void:
	if _tutorial_stage < 5 or _tutorial_target_words.is_empty():
		return
	_tutorial_help_level = mini(_tutorial_help_level + 1, 3)
	_tutorial_focus_words.clear()
	if _tutorial_help_level >= 3:
		_tutorial_focus_words.assign(_tutorial_target_words)
		_message.text = SaveManager.text("tutorial_wrong_help_group")
	elif _tutorial_help_level == 2 and _tutorial_target_words.size() > 1:
		_tutorial_focus_words = _tutorial_target_words.slice(0, 2)
		_message.text = SaveManager.text("tutorial_wrong_help_more")
	else:
		_tutorial_focus_words = [_tutorial_target_words[0]]
		_message.text = SaveManager.text("tutorial_wrong_help_one")
	_update_tutorial_spotlight()

func _on_tutorial_guide_continue() -> void:
	if _tutorial_stage < 5 or not _tutorial_independent_intro_pending or _tutorial_paused:
		return
	_tutorial_independent_intro_pending = false
	_apply_tutorial_stage()

func _show_tutorial_mistakes_feature() -> void:
	if _tutorial_stage != 1 or _tutorial_paused or is_instance_valid(_tutorial_feature_layer):
		return
	await get_tree().process_frame
	if _tutorial_stage != 1 or _tutorial_paused or not is_instance_valid(_lives_row):
		return
	_create_tutorial_feature_layer(1)
	var card: PanelContainer = PanelContainer.new()
	card.name = "TutorialMistakesFeature"
	card.size = Vector2(304, 178)
	card.add_theme_stylebox_override("panel", _tutorial_completion_style())
	_tutorial_feature_layer.add_child(card)
	_tutorial_feature_card = card
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 9)
	margin.add_child(content)
	var title: Label = Label.new()
	title.text = SaveManager.text("tutorial_mistakes_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font_fredoka_bold)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UI_PRIMARY)
	content.add_child(title)
	var dots: HBoxContainer = HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 12)
	content.add_child(dots)
	var maximum: int = int(SaveManager.settings.get("attempts", 4))
	for _index: int in range(maximum):
		var dot: Panel = Panel.new()
		dot.custom_minimum_size = Vector2(18, 18)
		dot.add_theme_stylebox_override("panel", _life_dot_style(false))
		dots.add_child(dot)
	var action: Button = Button.new()
	action.name = "TutorialMistakesContinue"
	action.text = SaveManager.text("tutorial_continue")
	action.custom_minimum_size = Vector2(150, 42)
	action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	action.disabled = true
	action.add_theme_font_override("font", _font_fredoka_bold)
	action.add_theme_font_size_override("font_size", 15)
	action.add_theme_color_override("font_color", UI_PRIMARY)
	action.add_theme_color_override("font_hover_color", UI_PRIMARY)
	action.add_theme_color_override("font_pressed_color", UI_PRIMARY)
	action.add_theme_stylebox_override("normal", _button_style(UI_YELLOW, UI_PRIMARY))
	action.add_theme_stylebox_override("hover", _button_style(Color("ffe23d"), UI_PRIMARY))
	action.add_theme_stylebox_override("pressed", _button_style(Color("e9c400"), UI_PRIMARY))
	action.pressed.connect(_on_tutorial_mistakes_feature_pressed.bind(action))
	content.add_child(action)
	_lives_row.modulate.a = 0.0
	await _animate_tutorial_feature_in(card, _lives_row, Vector2(304, 178))
	if is_instance_valid(action) and _tutorial_stage == 1:
		action.disabled = false

func _on_tutorial_mistakes_feature_pressed(action: Button) -> void:
	if action.disabled or _tutorial_stage != 1 or not is_instance_valid(_tutorial_feature_card):
		return
	action.disabled = true
	await _animate_tutorial_feature_back(_tutorial_feature_card, _lives_row)
	_lives_row.modulate.a = 1.0
	_clear_tutorial_feature_layer()
	_tutorial_stage = 2
	_apply_tutorial_stage()

func _show_tutorial_hint_feature() -> void:
	if _tutorial_stage != 2 or _tutorial_paused or is_instance_valid(_tutorial_feature_layer):
		return
	await get_tree().process_frame
	if _tutorial_stage != 2 or _tutorial_paused or not is_instance_valid(_hint):
		return
	_create_tutorial_feature_layer(2)
	var action: Button = _action_button(_hint.text)
	action.name = "TutorialHintFeature"
	action.icon = ICON_LIGHTBULB
	action.expand_icon = true
	action.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	action.add_theme_constant_override("icon_max_width", 24)
	action.custom_minimum_size = Vector2(230, 72)
	action.size = Vector2(230, 72)
	action.disabled = true
	action.add_theme_font_size_override("font_size", 18)
	action.add_theme_stylebox_override("normal", _button_style(UI_YELLOW, UI_PRIMARY))
	action.add_theme_stylebox_override("hover", _button_style(Color("ffe23d"), UI_PRIMARY))
	action.add_theme_stylebox_override("pressed", _button_style(Color("e9c400"), UI_PRIMARY))
	action.pressed.connect(_on_tutorial_hint_feature_pressed.bind(action))
	_tutorial_feature_layer.add_child(action)
	_tutorial_feature_card = action
	_hint.modulate.a = 0.0
	await _animate_tutorial_feature_in(action, _hint, Vector2(230, 72))
	if is_instance_valid(action) and _tutorial_stage == 2:
		action.disabled = false

func _on_tutorial_hint_feature_pressed(action: Button) -> void:
	if action.disabled or _tutorial_stage != 2 or not is_instance_valid(_tutorial_feature_card):
		return
	action.disabled = true
	await _animate_tutorial_feature_back(_tutorial_feature_card, _hint)
	_hint.modulate.a = 1.0
	_clear_tutorial_feature_layer()
	_on_hint_pressed()

func _create_tutorial_feature_layer(stage: int) -> void:
	_tutorial_feature_layer = Control.new()
	_tutorial_feature_layer.name = "TutorialFeatureLayer"
	_tutorial_feature_layer.set_meta("tutorial_stage", stage)
	_tutorial_feature_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_feature_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_feature_layer.z_index = 31
	add_child(_tutorial_feature_layer)

func _animate_tutorial_feature_in(feature: Control, source: Control, feature_size: Vector2) -> void:
	await get_tree().process_frame
	if not is_instance_valid(feature) or not is_instance_valid(source):
		return
	var source_center: Vector2 = source.get_global_rect().get_center() - get_global_rect().position
	var target_center: Vector2 = Vector2(size.x * 0.5, size.y * 0.54)
	feature.size = feature_size
	feature.position = source_center - feature_size * 0.5
	feature.pivot_offset = feature_size * 0.5
	feature.scale = Vector2(0.68, 0.68)
	feature.modulate.a = 0.35
	if _tutorial_feature_tween != null and _tutorial_feature_tween.is_running():
		_tutorial_feature_tween.kill()
	_tutorial_feature_tween = create_tween().set_parallel(true)
	_tutorial_feature_tween.tween_property(feature, "position", target_center - feature_size * 0.5, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tutorial_feature_tween.tween_property(feature, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tutorial_feature_tween.tween_property(feature, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _tutorial_feature_tween.finished

func _animate_tutorial_feature_back(feature: Control, source: Control) -> void:
	if not is_instance_valid(feature) or not is_instance_valid(source):
		return
	var source_center: Vector2 = source.get_global_rect().get_center() - get_global_rect().position
	var target_position: Vector2 = source_center - feature.size * 0.5
	if _tutorial_feature_tween != null and _tutorial_feature_tween.is_running():
		_tutorial_feature_tween.kill()
	_tutorial_feature_tween = create_tween().set_parallel(true)
	_tutorial_feature_tween.tween_property(feature, "position", target_position, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tutorial_feature_tween.tween_property(feature, "scale", Vector2(0.68, 0.68), 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tutorial_feature_tween.tween_property(feature, "modulate:a", 0.25, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _tutorial_feature_tween.finished

func _clear_tutorial_feature_layer() -> void:
	if _tutorial_feature_tween != null and _tutorial_feature_tween.is_running():
		_tutorial_feature_tween.kill()
	_tutorial_feature_tween = null
	_tutorial_feature_card = null
	if is_instance_valid(_tutorial_feature_layer):
		_tutorial_feature_layer.queue_free()
	_tutorial_feature_layer = null

func _show_tutorial_intro() -> void:
	if is_instance_valid(_tutorial_intro_layer):
		return
	_tutorial_paused = true
	GameState.set_tutorial_allowed_words([])
	_update_tutorial_spotlight()
	_tutorial_intro_layer = Control.new()
	_tutorial_intro_layer.name = "TutorialIntro"
	_tutorial_intro_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_intro_layer.z_index = 50
	_tutorial_intro_layer.modulate.a = 0.0
	add_child(_tutorial_intro_layer)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.07, 0.025, 0.20, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_intro_layer.add_child(shade)
	var card: PanelContainer = PanelContainer.new()
	card.name = "TutorialIntroCard"
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-170, -220)
	card.size = Vector2(340, 440)
	card.add_theme_stylebox_override("panel", _tutorial_completion_style())
	_tutorial_intro_layer.add_child(card)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	card.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var eyebrow: Label = Label.new()
	eyebrow.text = SaveManager.text("tutorial_intro_eyebrow")
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_override("font", _font_dm_sans_semibold)
	eyebrow.add_theme_font_size_override("font_size", 11)
	eyebrow.add_theme_color_override("font_color", UI_MAGENTA)
	content.add_child(eyebrow)
	var title: Label = Label.new()
	title.text = SaveManager.text("tutorial_intro_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font_fredoka_bold)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", UI_PRIMARY)
	content.add_child(title)
	var body: Label = Label.new()
	body.text = SaveManager.text("tutorial_intro_body")
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_override("font", _font_dm_sans_semibold)
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", UI_MUTED_TEXT)
	content.add_child(body)
	var preview: VBoxContainer = VBoxContainer.new()
	preview.alignment = BoxContainer.ALIGNMENT_CENTER
	preview.add_theme_constant_override("separation", 3)
	content.add_child(preview)
	var row_colors: Array[Color] = [UI_MAGENTA, UI_RED, UI_TEAL, UI_YELLOW, Color("d7c8ff")]
	for row_size: int in range(1, 6):
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 3)
		preview.add_child(row)
		for _tile_index: int in range(row_size):
			var tile: Panel = Panel.new()
			tile.custom_minimum_size = Vector2(27, 22)
			var tile_style: StyleBoxFlat = StyleBoxFlat.new()
			tile_style.bg_color = row_colors[row_size - 1]
			tile_style.corner_radius_top_left = 6
			tile_style.corner_radius_top_right = 6
			tile_style.corner_radius_bottom_left = 6
			tile_style.corner_radius_bottom_right = 6
			tile_style.shadow_color = Color(0.08, 0.03, 0.20, 0.14)
			tile_style.shadow_size = 2
			tile.add_theme_stylebox_override("panel", tile_style)
			row.add_child(tile)
	var note: Label = Label.new()
	note.text = SaveManager.text("tutorial_intro_note")
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_override("font", _font_dm_sans_semibold)
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", UI_PRIMARY)
	content.add_child(note)
	var start_button: Button = Button.new()
	start_button.name = "TutorialStart"
	start_button.text = SaveManager.text("tutorial_intro_start")
	start_button.custom_minimum_size = Vector2(0, 48)
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_button.add_theme_font_override("font", _font_fredoka_bold)
	start_button.add_theme_font_size_override("font_size", 16)
	start_button.add_theme_color_override("font_color", UI_PRIMARY)
	start_button.add_theme_color_override("font_hover_color", UI_PRIMARY)
	start_button.add_theme_color_override("font_pressed_color", UI_PRIMARY)
	start_button.add_theme_stylebox_override("normal", _button_style(UI_YELLOW, UI_PRIMARY))
	start_button.add_theme_stylebox_override("hover", _button_style(Color("ffe23d"), UI_PRIMARY))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color("e9c400"), UI_PRIMARY))
	start_button.pressed.connect(_on_tutorial_intro_start.bind(start_button))
	content.add_child(start_button)
	await get_tree().process_frame
	if not is_instance_valid(card):
		return
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.95, 0.95)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_tutorial_intro_layer, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_tutorial_intro_start(button: Button) -> void:
	if button.disabled or not is_instance_valid(_tutorial_intro_layer):
		return
	button.disabled = true
	var layer: Control = _tutorial_intro_layer
	var tween: Tween = create_tween()
	tween.tween_property(layer, "modulate:a", 0.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if is_instance_valid(layer):
		layer.queue_free()
	if _tutorial_intro_layer == layer:
		_tutorial_intro_layer = null
	_tutorial_paused = false
	_tutorial_stage = 0
	_tutorial_independent_intro_pending = false
	_apply_tutorial_stage()

func _update_tutorial_selection_message() -> void:
	if _tutorial_stage == 1:
		_message.text = SaveManager.text("tutorial_mistakes_body")
		_check.disabled = true
		_update_tutorial_spotlight()
		return
	if _tutorial_stage == 2:
		_message.text = SaveManager.text("tutorial_use_hint")
		_hint.disabled = false
		_check.disabled = true
		_update_tutorial_spotlight()
		return
	if _tutorial_stage >= 5 and _tutorial_independent_intro_pending:
		_message.text = SaveManager.text("tutorial_independent_three_intro") if _tutorial_stage == 5 else SaveManager.text("tutorial_independent_last_intro")
		_check.disabled = true
		_update_tutorial_spotlight()
		return
	var target_size_reached: bool = not _tutorial_target_words.is_empty() and GameState.selected_words.size() == _tutorial_target_words.size()
	if target_size_reached and GameState.can_check_selection():
		_message.text = SaveManager.text("tutorial_press_check")
	elif _tutorial_stage == 3:
		_message.text = SaveManager.text("tutorial_finish_hint_row")
	elif _tutorial_stage == 4:
		_message.text = SaveManager.text("tutorial_top_any_order")
	elif _tutorial_stage == 5:
		_message.text = SaveManager.text("tutorial_find_three")
	elif _tutorial_stage == 6:
		_message.text = SaveManager.text("tutorial_find_last")
	else:
		_message.text = SaveManager.text("tutorial_first_group")
	_update_tutorial_spotlight()

func _update_tutorial_spotlight() -> void:
	if GameState.game_mode != GameState.TUTORIAL_MODE or not is_instance_valid(_tutorial_spotlight):
		return
	if _tutorial_paused:
		_tutorial_spotlight.visible = false
		_clear_tutorial_focus()
		return
	var full_guidance: bool = _tutorial_stage <= 4
	_tutorial_spotlight.visible = full_guidance
	if full_guidance:
		_tutorial_spotlight.color = Color(0.08, 0.035, 0.22, 0.35)
	for word: String in _word_buttons:
		var tile: Button = _word_buttons[word]
		var focused: bool = _tutorial_focus_words.has(word)
		tile.z_index = 21 if focused else 0
		_set_tutorial_focus(tile, focused)
	_hint.z_index = 21 if _tutorial_stage == 2 else 0
	_set_tutorial_focus(_hint, _tutorial_stage == 2)
	var selection_ready: bool = not GameState.selected_words.is_empty() and GameState.can_check_selection()
	_check.z_index = 21 if selection_ready and GameState.can_check_selection() else 0
	_set_tutorial_focus(_check, selection_ready and GameState.can_check_selection())
	if is_instance_valid(_tutorial_guide_button):
		var guide_focused: bool = _tutorial_stage >= 5 and _tutorial_independent_intro_pending
		_tutorial_guide_button.z_index = 21 if guide_focused else 0
		_set_tutorial_focus(_tutorial_guide_button, guide_focused)
	_lives_row.z_index = 21 if _tutorial_stage == 1 else 0
	_set_tutorial_focus(_lives_row, _tutorial_stage == 1)
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
		# change that is easy to miss on a phone-sized tile. A large finite loop
		# avoids Godot 4.7's infinite-loop diagnostic while remaining effectively
		# continuous for the lifetime of a tutorial step.
		tween.set_loops(600)
		tween.tween_property(control, "scale", Vector2(1.06, 1.06), 0.50).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(control, "scale", Vector2(1.025, 1.025), 0.60).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
	if is_instance_valid(_tutorial_guide_button):
		_tutorial_guide_button.z_index = 0
		_set_tutorial_focus(_tutorial_guide_button, false)
	_lives_row.z_index = 0
	_set_tutorial_focus(_lives_row, false)

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
	elif _tutorial_stage == 3 and row_length == 5:
		_tutorial_stage = 4
	elif _tutorial_stage == 4 and row_length == 1:
		_tutorial_stage = 5
		_tutorial_independent_intro_pending = true
	elif _tutorial_stage == 5 and row_length == 3:
		_tutorial_stage = 6
		_tutorial_independent_intro_pending = true
	_apply_tutorial_stage()

func _advance_tutorial_after_hint() -> void:
	await get_tree().create_timer(TUTORIAL_HINT_BREAK).timeout
	if is_inside_tree() and GameState.game_mode == GameState.TUTORIAL_MODE and _tutorial_stage == 3:
		_apply_tutorial_stage()

func _on_tutorial_completed() -> void:
	if _tutorial_finishing or GameState.game_mode != GameState.TUTORIAL_MODE:
		return
	if not GameState.completed_won:
		_restart_tutorial_after_failure()
		return
	_tutorial_finishing = true
	_tutorial_paused = true
	GameState.set_tutorial_allowed_words([])
	_hint.disabled = true
	_check.disabled = true
	_update_tutorial_spotlight()
	_message.text = SaveManager.text("tutorial_complete")
	await get_tree().create_timer(TUTORIAL_FINISH_BREAK).timeout
	if is_inside_tree():
		_show_tutorial_completion_screen()

func _restart_tutorial_after_failure() -> void:
	_tutorial_finishing = true
	_tutorial_paused = true
	GameState.set_tutorial_allowed_words([])
	_hint.disabled = true
	_check.disabled = true
	_lives_row.modulate.a = 1.0
	_hint.modulate.a = 1.0
	_clear_tutorial_feature_layer()
	_update_tutorial_spotlight()
	_update_mistakes()
	_message.text = SaveManager.text("tutorial_restart_message")
	# Let the fourth error, its used attempt marker and the shake finish before
	# covering the old board. The new practice then appears beneath one short
	# full-screen fade, so no half-reset layout is ever visible.
	await get_tree().create_timer(0.85).timeout
	if not is_inside_tree() or GameState.game_mode != GameState.TUTORIAL_MODE:
		return
	_tutorial_restart_layer = ColorRect.new()
	_tutorial_restart_layer.name = "TutorialRestartTransition"
	_tutorial_restart_layer.color = UI_PRIMARY
	_tutorial_restart_layer.modulate.a = 0.0
	_tutorial_restart_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_restart_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_restart_layer.z_index = 55
	add_child(_tutorial_restart_layer)
	var cover_in: Tween = create_tween()
	cover_in.tween_property(_tutorial_restart_layer, "modulate:a", 1.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await cover_in.finished
	if not is_inside_tree() or not is_instance_valid(_tutorial_restart_layer):
		return
	_tutorial_finishing = false
	_tutorial_paused = false
	_tutorial_stage = 0
	_tutorial_independent_intro_pending = false
	GameState.start_tutorial()
	await get_tree().process_frame
	if not is_instance_valid(_tutorial_restart_layer):
		return
	var layer: ColorRect = _tutorial_restart_layer
	var cover_out: Tween = create_tween()
	cover_out.tween_property(layer, "modulate:a", 0.0, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await cover_out.finished
	if is_instance_valid(layer):
		layer.queue_free()
	if _tutorial_restart_layer == layer:
		_tutorial_restart_layer = null

func _show_tutorial_completion_screen() -> void:
	if is_instance_valid(_tutorial_completion_layer):
		return
	_tutorial_completion_layer = Control.new()
	_tutorial_completion_layer.name = "TutorialCompletion"
	_tutorial_completion_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_completion_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_completion_layer.z_index = 40
	_tutorial_completion_layer.modulate.a = 0.0
	add_child(_tutorial_completion_layer)
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(1.0, 0.992, 0.961, 0.96)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tutorial_completion_layer.add_child(backdrop)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 22)
	_tutorial_completion_layer.add_child(center)
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(clampf(size.x - 44.0, 300.0, 390.0), 0)
	card.add_theme_stylebox_override("panel", _tutorial_completion_style())
	center.add_child(card)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	card.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margin.add_child(content)
	var success_mark: Label = Label.new()
	success_mark.text = "✓"
	success_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	success_mark.add_theme_font_override("font", _font_fredoka_bold)
	success_mark.add_theme_font_size_override("font_size", 48)
	success_mark.add_theme_color_override("font_color", UI_TEAL)
	content.add_child(success_mark)
	var title: Label = Label.new()
	title.text = SaveManager.text("tutorial_complete_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font_fredoka_bold)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", UI_TEXT)
	content.add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = SaveManager.text("tutorial_complete_subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_override("font", FONT_DM_SANS)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", UI_MUTED_TEXT)
	content.add_child(subtitle)
	var continue_button: Button = _action_button(SaveManager.text("tutorial_continue_daily"), true)
	continue_button.custom_minimum_size = Vector2(0, 56)
	continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	continue_button.add_theme_font_size_override("font_size", 17)
	continue_button.add_theme_color_override("font_color", UI_PRIMARY)
	continue_button.add_theme_color_override("font_hover_color", UI_PRIMARY)
	continue_button.add_theme_color_override("font_pressed_color", UI_PRIMARY)
	continue_button.add_theme_stylebox_override("normal", _button_style(UI_YELLOW, UI_PRIMARY))
	continue_button.add_theme_stylebox_override("hover", _button_style(Color("ffe23d"), UI_PRIMARY))
	continue_button.add_theme_stylebox_override("pressed", _button_style(Color("e9c400"), UI_PRIMARY))
	continue_button.pressed.connect(_on_tutorial_continue_pressed.bind(continue_button))
	content.add_child(continue_button)
	await get_tree().process_frame
	if not is_instance_valid(card):
		return
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.94, 0.94)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_tutorial_completion_layer, "modulate:a", 1.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_tutorial_continue_pressed(button: Button) -> void:
	if button.disabled:
		return
	button.disabled = true
	button.pivot_offset = button.size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(button, "scale", Vector2(0.97, 0.97), 0.08)
	tween.tween_property(button, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: request_tutorial_exit.emit(true))

func _on_rewarded_hint_required() -> void:
	_set_hint_button_text(SaveManager.text("ad_hint"), true)
	_show_board_message(SaveManager.text("rewarded_hint_required"))
	_hint.disabled = false

func _on_rewarded_ad_unavailable(message: String) -> void:
	_show_board_message(message)
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
	if is_instance_valid(_instructions_layer):
		return
	_instructions_layer = INSTRUCTIONS_STYLE_DEMO_SCENE.instantiate() as Control
	_instructions_layer.z_index = 60
	_instructions_layer.connect("dismiss_requested", _on_instructions_dismissed)
	add_child(_instructions_layer)

func _on_instructions_dismissed() -> void:
	if not is_instance_valid(_instructions_layer):
		return
	_instructions_layer.queue_free()
	_instructions_layer = null

func _action_button(label_text: String, filled: bool = false) -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(110, 52)
	button.add_theme_font_override("font", _font_fredoka_semibold)
	button.add_theme_font_size_override("font_size", 15)
	var normal_color: Color = UI_YELLOW if filled else Color.WHITE
	var normal_border: Color = UI_YELLOW if filled else Color(1, 1, 1, 0.32)
	button.add_theme_stylebox_override("normal", _button_style(normal_color, normal_border))
	button.add_theme_stylebox_override("hover", _button_style(Color("ffe23d") if filled else Color("f5f1ff"), UI_YELLOW if filled else Color.WHITE))
	button.add_theme_stylebox_override("pressed", _button_style(Color("e9c400") if filled else Color("e7e0f7"), Color("e9c400") if filled else Color("d8cff0")))
	button.add_theme_stylebox_override("disabled", _button_style(Color("d8d1e8"), Color("d8d1e8")))
	button.add_theme_color_override("font_color", UI_PRIMARY)
	button.add_theme_color_override("font_hover_color", UI_PRIMARY)
	button.add_theme_color_override("font_pressed_color", UI_PRIMARY)
	button.add_theme_color_override("font_hover_pressed_color", UI_PRIMARY)
	button.add_theme_color_override("font_disabled_color", Color("81759f"))
	return button

func _hint_button_label(label_text: String) -> String:
	return label_text

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

func _add_aftermath_background_decor(parent: Control) -> void:
	var decor: Control = Control.new()
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	decor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(decor)
	_add_game_decor_shape(decor, Vector2(-50, 78), Vector2(118, 118), UI_YELLOW, 0.30, 59)
	_add_game_decor_shape(decor, Vector2(size.x - 70, 122), Vector2(112, 150), Color("c9b8ff"), 0.34, 26, 12.0)
	_add_game_decor_shape(decor, Vector2(-24, size.y - 110), Vector2(74, 62), UI_TEAL, 0.16, 20, -10.0)

func _build_aftermath_result_pyramid() -> VBoxContainer:
	var component: VBoxContainer = VBoxContainer.new()
	component.name = "ResultPyramid"
	component.alignment = BoxContainer.ALIGNMENT_CENTER
	component.add_theme_constant_override("separation", 7)
	var pyramid: VBoxContainer = VBoxContainer.new()
	pyramid.alignment = BoxContainer.ALIGNMENT_CENTER
	pyramid.add_theme_constant_override("separation", 3)
	component.add_child(pyramid)
	# Mirror the full game board: one top-word block followed by all four word
	# groups. This keeps every result in the exact same visual row as gameplay.
	for layer_index: int in 5:
		var row_length: int = layer_index + 1
		var row: HBoxContainer = HBoxContainer.new()
		row.name = "Layer%d" % (layer_index + 1)
		row.set_meta("row_length", row_length)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4)
		pyramid.add_child(row)
		var found: bool = GameState.result_top_solved if row_length == 1 else _aftermath_group_found_for_size(row_length)
		var fill: Color = _row_fill(row_length) if found else Color("3a267c")
		var border: Color = _row_border(row_length) if found else Color("ff8066")
		var mark_text: String = "✓" if found else "×"
		var mark_color: Color = _row_text(row_length) if found else Color("ff9a86")
		for _tile_index: int in row_length:
			var tile: PanelContainer = PanelContainer.new()
			tile.custom_minimum_size = Vector2(42, 25)
			tile.add_theme_stylebox_override("panel", _aftermath_pyramid_tile_style(fill, border, not found))
			row.add_child(tile)
			var mark: Label = _aftermath_label(mark_text, 13, mark_color, _font_fredoka_bold)
			mark.add_theme_constant_override("outline_size", 0)
			tile.add_child(mark)
	var legend: HBoxContainer = HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 14)
	component.add_child(legend)
	legend.add_child(_aftermath_legend_item(UI_TEAL, "✓", SaveManager.text("aftermath_group_found"), "LegendFoundIcon"))
	legend.add_child(_aftermath_legend_item(Color("ff8066"), "×", SaveManager.text("aftermath_group_missed"), "LegendMissedIcon"))
	return component

func _aftermath_group_found_for_size(group_size: int) -> bool:
	var groups: Array = GameState.puzzle.get("groups", [])
	for index: int in groups.size():
		var group_value: Variant = groups[index]
		if group_value is Dictionary and int((group_value as Dictionary).get("size", 0)) == group_size:
			return GameState.result_solved_groups.has(index)
	return false

func _aftermath_legend_item(color: Color, mark_text: String, text_value: String, icon_name: String) -> HBoxContainer:
	var item: HBoxContainer = HBoxContainer.new()
	item.add_theme_constant_override("separation", 5)
	var icon: PanelContainer = PanelContainer.new()
	icon.name = icon_name
	icon.custom_minimum_size = Vector2(18, 18)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_style: StyleBoxFlat = StyleBoxFlat.new()
	icon_style.bg_color = color
	icon_style.border_color = Color(0.0, 0.0, 0.0, 0.38)
	icon_style.set_border_width_all(1)
	icon_style.set_corner_radius_all(4)
	icon.add_theme_stylebox_override("panel", icon_style)
	item.add_child(icon)
	var mark: Label = _aftermath_label(mark_text, 12, Color.WHITE, _font_fredoka_bold)
	mark.name = "%sMark" % icon_name
	mark.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.28))
	mark.add_theme_constant_override("outline_size", 1)
	icon.add_child(mark)
	var label: Label = _aftermath_label(text_value, 10, Color(1, 1, 1, 0.62), _font_dm_sans_semibold)
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	item.add_child(label)
	return item

func _set_aftermath_button_icon(button: Button, icon_texture: Texture2D) -> void:
	button.icon = icon_texture
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 19)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

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
	var fill: Color = UI_YELLOW
	if filled:
		button.add_theme_stylebox_override("normal", _aftermath_button_style(fill, fill))
		button.add_theme_stylebox_override("hover", _aftermath_button_style(fill.lightened(0.08), fill.lightened(0.08)))
		button.add_theme_stylebox_override("pressed", _aftermath_button_style(fill.darkened(0.08), fill.darkened(0.08)))
		button.add_theme_color_override("font_color", UI_PRIMARY)
		button.add_theme_color_override("font_hover_color", UI_PRIMARY)
		button.add_theme_color_override("font_pressed_color", UI_PRIMARY)
	else:
		button.add_theme_stylebox_override("normal", _aftermath_button_style(UI_BACKGROUND, UI_BORDER))
		button.add_theme_stylebox_override("hover", _aftermath_button_style(UI_SURFACE_TINT, UI_BORDER))
		button.add_theme_stylebox_override("pressed", _aftermath_button_style(Color("e3dcf3"), UI_BORDER))
		button.add_theme_color_override("font_color", UI_PRIMARY)
		button.add_theme_color_override("font_hover_color", UI_PRIMARY)
		button.add_theme_color_override("font_pressed_color", UI_PRIMARY)
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

func _create_game_decor() -> Control:
	var layer: Control = Control.new()
	layer.name = "GameDecor"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var base: ColorRect = ColorRect.new()
	base.color = UI_PRIMARY
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(base)
	# Half of the circle sits outside the left edge, slightly above the screen's
	# midpoint. The opposite rectangle is clipped by the right edge.
	_add_game_decor_shape(layer, Vector2(-62, size.y * 0.36), Vector2(124, 124), UI_YELLOW, 0.92, 62)
	_add_game_decor_shape(layer, Vector2(size.x - 58, size.y * 0.52), Vector2(156, 84), Color("c9b8ff"), 0.78, 20, 12.0)
	return layer

func _add_game_decor_shape(parent: Control, position: Vector2, shape_size: Vector2, color: Color, alpha: float, radius: int, rotation_value: float = 0.0) -> void:
	var shape: Panel = Panel.new()
	shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shape.position = position
	shape.size = shape_size
	shape.custom_minimum_size = shape_size
	shape.pivot_offset = shape_size * 0.5
	shape.rotation_degrees = rotation_value
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var fill: Color = color
	fill.a = alpha
	style.bg_color = fill
	style.border_color = Color.TRANSPARENT
	style.set_corner_radius_all(radius)
	shape.add_theme_stylebox_override("panel", style)
	parent.add_child(shape)

func _header_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UI_PRIMARY
	style.border_color = Color("3a2874")
	style.set_border_width_all(1)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.10, 0.04, 0.37, 0.20)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	return style

func _header_button_style(fill: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(1, 1, 1, 0.14)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _small_pill_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style

func _card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
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

func _row_band_style(_row_length: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	return style

func _action_dock_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UI_PRIMARY
	style.border_color = Color("3a2874")
	style.set_border_width_all(1)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.102, 0.039, 0.369, 0.20)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 5)
	return style

func _tile_style(color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
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
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
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

func _aftermath_fullscreen_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	return style

func _aftermath_result_card_style(won: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UI_PRIMARY
	style.border_color = UI_PRIMARY
	style.set_corner_radius_all(28)
	style.shadow_color = UI_MAGENTA if won else UI_RED
	style.shadow_size = 2
	style.shadow_offset = Vector2(7, 7)
	return style

func _aftermath_mode_chip_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UI_YELLOW
	style.set_corner_radius_all(14)
	return style

func _aftermath_score_badge_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UI_YELLOW
	style.set_corner_radius_all(22)
	return style

func _aftermath_streak_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("382181")
	style.border_color = Color("523a9c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(20)
	return style

func _aftermath_pyramid_tile_style(fill: Color, border: Color, outlined: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2 if outlined else 0)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.02, 0.01, 0.10, 0.24)
	style.shadow_size = 2
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
