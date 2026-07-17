extends Control

const GameBoardScene: PackedScene = preload("res://scenes/game_board.tscn")
const FONT_FREDOKA: Font = preload("res://assets/fonts/Fredoka.ttf")
const FONT_DM_SANS: Font = preload("res://assets/fonts/DMSans.ttf")
const SETTINGS_TOGGLE_ON: Texture2D = preload("res://assets/toggle_on.svg")
const SETTINGS_TOGGLE_OFF: Texture2D = preload("res://assets/toggle_off.svg")

const UI_BACKGROUND: Color = Color("fffdf5")
const UI_SURFACE: Color = Color.WHITE
const UI_PRIMARY: Color = Color("1a0a5e")
const UI_PRIMARY_HOVER: Color = Color("2a167c")
const UI_PRIMARY_PRESSED: Color = Color("120742")
const UI_TEXT: Color = Color("1a0a5e")
const UI_MUTED_TEXT: Color = Color("9b8cd4")
const UI_BORDER: Color = Color("d6cfef")
const UI_SURFACE_TINT: Color = Color("eee9fa")
const UI_YELLOW: Color = Color("ffd600")
const UI_MAGENTA: Color = Color("b939ff")
const UI_RED: Color = Color("ff5533")
const UI_TEAL: Color = Color("00bfa5")

@onready var _home_background: TextureRect = get_node_or_null("HomeBackground") as TextureRect
@onready var _home_layer: MarginContainer = get_node_or_null("HomeLayer") as MarginContainer
@onready var _logo_spacer: Control = get_node_or_null("HomeLayer/Content/LogoSpacer") as Control
@onready var _bottom_spacer: Control = get_node_or_null("HomeLayer/Content/BottomSpacer") as Control
@onready var _play_button: Button = _find_play_button()
@onready var _unlimited_card: PanelContainer = get_node_or_null("HomeLayer/Content/ModeButtons/UnlimitedCard") as PanelContainer
@onready var _unlimited_title: Label = get_node_or_null("HomeLayer/Content/ModeButtons/UnlimitedCard/CardMargin/CardContent/Header/TitleStack/Title") as Label
@onready var _unlimited_subtitle: Label = get_node_or_null("HomeLayer/Content/ModeButtons/UnlimitedCard/CardMargin/CardContent/Header/TitleStack/Subtitle") as Label
@onready var _endless_hearts_row: HBoxContainer = get_node_or_null("HomeLayer/Content/ModeButtons/UnlimitedCard/CardMargin/CardContent/Header/Hearts") as HBoxContainer
@onready var _unlimited_button: Button = get_node_or_null("HomeLayer/Content/ModeButtons/UnlimitedCard/CardMargin/CardContent/UnlimitedButton") as Button
@onready var _endless_status: HBoxContainer = get_node_or_null("HomeLayer/Content/ModeButtons/UnlimitedCard/CardMargin/CardContent/EndlessStatus") as HBoxContainer
@onready var _endless_heart_label: Label = get_node_or_null("HomeLayer/Content/ModeButtons/UnlimitedCard/CardMargin/CardContent/EndlessStatus/HeartLabel") as Label
@onready var _reward_heart_button: Button = get_node_or_null("HomeLayer/Content/ModeButtons/UnlimitedCard/CardMargin/CardContent/EndlessStatus/RewardHeartButton") as Button
@onready var _settings_button: Button = get_node_or_null("HomeLayer/Content/Header/SettingsButton") as Button
@onready var _daily_card: PanelContainer = get_node_or_null("HomeLayer/Content/DailyCard") as PanelContainer
@onready var _brand_title: Label = get_node_or_null("HomeLayer/Content/BrandBlock/Title") as Label
@onready var _brand_subtitle: Label = get_node_or_null("HomeLayer/Content/BrandBlock/Subtitle") as Label
@onready var _date_pill: Label = get_node_or_null("HomeLayer/Content/DailyCard/CardMargin/CardContent/DatePill") as Label
@onready var _card_title: Label = get_node_or_null("HomeLayer/Content/DailyCard/CardMargin/CardContent/CardTitle") as Label
@onready var _card_meta: Label = get_node_or_null("HomeLayer/Content/DailyCard/CardMargin/CardContent/CardMeta") as Label
@onready var _card_streak: Label = get_node_or_null("HomeLayer/Content/DailyCard/CardMargin/CardContent/CardStreak") as Label
@onready var _home_hint: RichTextLabel = get_node_or_null("HomeLayer/Content/HomeHint") as RichTextLabel

var _active_view: Control
var _home_decor: Control
var _is_transitioning: bool = false
var _settings_sheet: PanelContainer
var _settings_motion_target: VBoxContainer
var _settings_drag_start_y: float = 0.0
var _settings_dragging: bool = false
var _settings_dismissing: bool = false
var _settings_snap_tween: Tween
var _endless_countdown_timer: Timer
var _font_fredoka_semibold: FontVariation
var _font_fredoka_bold: FontVariation
var _font_dm_sans_semibold: FontVariation
var _font_dm_sans_bold: FontVariation
var _font_dm_sans_spaced: FontVariation

func _ready() -> void:
	if _home_background == null or _home_layer == null or _play_button == null or _unlimited_card == null or _unlimited_button == null or _endless_hearts_row == null or _endless_status == null or _endless_heart_label == null or _reward_heart_button == null or _settings_button == null or _daily_card == null:
		# The editor can keep an older Main scene in memory after its .tscn file
		# changes externally. Reload once so the editable scene tree is used.
		call_deferred("_reload_editable_home_scene")
		return
	_setup_font_variations()
	_home_decor = _create_home_decor()
	add_child(_home_decor)
	move_child(_home_decor, 0)
	_home_background.visible = false
	_theme_setup()
	_apply_home_texts()
	_apply_home_card_style()
	_apply_mini_pyramid_style()
	_apply_play_button_style()
	_apply_unlimited_button_style()
	_apply_endless_status_style()
	_apply_settings_button_style()
	_play_button.button_down.connect(func() -> void: _animate_play_button(0.97))
	_play_button.button_up.connect(func() -> void: _animate_play_button(1.0))
	_unlimited_button.pressed.connect(_on_unlimited_pressed)
	_reward_heart_button.pressed.connect(_on_rewarded_heart_pressed)
	_settings_button.pressed.connect(show_settings)
	GameState.puzzle_pool_completed.connect(_on_puzzle_pool_completed)
	if not AdManager.rewarded_heart_earned.is_connected(_on_rewarded_heart_earned):
		AdManager.rewarded_heart_earned.connect(_on_rewarded_heart_earned)
	if not AdManager.rewarded_ad_unavailable.is_connected(_on_home_rewarded_ad_unavailable):
		AdManager.rewarded_ad_unavailable.connect(_on_home_rewarded_ad_unavailable)
	_endless_countdown_timer = Timer.new()
	_endless_countdown_timer.wait_time = 30.0
	_endless_countdown_timer.timeout.connect(_on_endless_countdown_tick)
	add_child(_endless_countdown_timer)
	_endless_countdown_timer.start()
	resized.connect(_layout_home_layout)
	show_main_menu()
	call_deferred("_continue_onboarding")

func _reload_editable_home_scene() -> void:
	get_tree().reload_current_scene()

func _find_play_button() -> Button:
	var card_button: Button = get_node_or_null("HomeLayer/Content/DailyCard/CardMargin/CardContent/PlayButton") as Button
	if card_button != null:
		return card_button
	return get_node_or_null("HomeLayer/Content/ModeButtons/PlayButton") as Button

func _setup_font_variations() -> void:
	_font_fredoka_semibold = _font_variation(FONT_FREDOKA, 600, 0.30)
	_font_fredoka_bold = _font_variation(FONT_FREDOKA, 700, 0.48)
	_font_dm_sans_semibold = _font_variation(FONT_DM_SANS, 600, 0.12)
	_font_dm_sans_bold = _font_variation(FONT_DM_SANS, 700, 0.22)
	_font_dm_sans_spaced = _font_variation(FONT_DM_SANS, 600, 0.10, 2)

func _font_variation(base_font: Font, weight: int, embolden: float, glyph_spacing: int = 0) -> FontVariation:
	var font: FontVariation = FontVariation.new()
	font.base_font = base_font
	font.variation_opentype = {"wght": weight}
	font.variation_embolden = embolden
	if glyph_spacing != 0:
		font.set_spacing(TextServer.SPACING_GLYPH, glyph_spacing)
	return font

func show_main_menu() -> void:
	_clear_content()
	_apply_home_texts()
	_show_home()
	_layout_home_layout()

func _show_home() -> void:
	_home_decor.visible = true
	_home_layer.visible = true
	_home_decor.modulate.a = 1.0
	_home_layer.modulate.a = 1.0
	_home_layer.scale = Vector2.ONE

func _hide_home() -> void:
	_home_decor.visible = false
	_home_layer.visible = false

func _on_play_pressed() -> void:
	if _is_transitioning:
		return
	if SaveManager.is_daily_challenge_completed():
		if GameState.view_daily_result():
			show_game()
		return
	if GameState.start_new_game("daily"):
		show_game()

func _on_unlimited_pressed() -> void:
	if _is_transitioning:
		return
	if not SaveManager.can_start_endless():
		if SaveManager.can_claim_rewarded_endless_heart():
			_on_rewarded_heart_pressed()
			return
		_apply_home_texts()
		return
	if GameState.has_resumable_game("unlimited"):
		if GameState.restore_game():
			show_game()
		return
	if GameState.start_new_game("unlimited"):
		show_game()

func _on_rewarded_heart_pressed() -> void:
	if not SaveManager.can_claim_rewarded_endless_heart():
		_apply_home_texts()
		return
	_unlimited_button.disabled = true
	_reward_heart_button.disabled = true
	AdManager.request_rewarded_heart()

func _on_rewarded_heart_earned() -> void:
	if SaveManager.grant_rewarded_endless_heart():
		_apply_home_texts()
		_endless_heart_label.text = SaveManager.text("endless_heart_earned")

func _on_home_rewarded_ad_unavailable(message: String) -> void:
	if _home_layer.visible and not is_instance_valid(_active_view):
		_apply_home_texts()
		_endless_heart_label.text = message

func _on_puzzle_pool_completed(mode: String) -> void:
	if is_instance_valid(_active_view):
		return
	var label: String = SaveManager.text("daily_pool") if mode == "daily" else SaveManager.text("unlimited_pool")
	_play_button.disabled = mode == "daily"
	_unlimited_button.disabled = mode == "unlimited"
	_unlimited_button.text = SaveManager.text("all_played") if mode == "unlimited" else SaveManager.text("unlimited_button")
	_play_button.text = SaveManager.text("all_played_daily") if mode == "daily" else SaveManager.text("daily_button")
	# A short, visible confirmation on the home screen without adding a new scene.
	var notice: Label = Label.new()
	notice.name = "PoolCompleteNotice"
	notice.text = SaveManager.text("pool_complete") % label
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_override("font", FONT_DM_SANS)
	notice.add_theme_color_override("font_color", Color("5734bd"))
	notice.add_theme_font_size_override("font_size", 15)
	_home_layer.get_node("Content").add_child(notice)

func _on_menu_pressed() -> void:
	show_settings()

func _animate_play_button(scale_target: float) -> void:
	_play_button.pivot_offset = _play_button.size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(_play_button, "scale", Vector2.ONE * scale_target, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _apply_play_button_style() -> void:
	_play_button.add_theme_font_override("font", _font_fredoka_bold)
	_play_button.add_theme_stylebox_override("normal", _play_style(UI_YELLOW, 1))
	_play_button.add_theme_stylebox_override("hover", _play_style(Color("ffe23d"), 1))
	_play_button.add_theme_stylebox_override("pressed", _play_style(Color("e9c400"), 0))
	_play_button.add_theme_color_override("font_color", UI_PRIMARY)
	_play_button.add_theme_color_override("font_hover_color", UI_PRIMARY)
	_play_button.add_theme_color_override("font_pressed_color", UI_PRIMARY)
	_play_button.add_theme_font_size_override("font_size", 18)
	_play_button.add_theme_constant_override("outline_size", 0)

func _apply_unlimited_button_style() -> void:
	_unlimited_card.add_theme_stylebox_override("panel", _infinity_card_style())
	var card_margin: MarginContainer = _unlimited_card.get_node("CardMargin") as MarginContainer
	card_margin.add_theme_constant_override("margin_left", 16)
	card_margin.add_theme_constant_override("margin_right", 16)
	card_margin.add_theme_constant_override("margin_top", 12)
	card_margin.add_theme_constant_override("margin_bottom", 12)
	_unlimited_title.add_theme_font_override("font", _font_fredoka_bold)
	_unlimited_title.add_theme_font_size_override("font_size", 18)
	_unlimited_title.add_theme_color_override("font_color", UI_TEXT)
	_unlimited_subtitle.add_theme_font_override("font", FONT_DM_SANS)
	_unlimited_subtitle.add_theme_font_size_override("font_size", 11)
	_unlimited_subtitle.add_theme_color_override("font_color", UI_MUTED_TEXT)
	_unlimited_button.add_theme_font_override("font", _font_fredoka_bold)
	_unlimited_button.add_theme_stylebox_override("normal", _play_style(UI_PRIMARY, 3))
	_unlimited_button.add_theme_stylebox_override("hover", _play_style(UI_PRIMARY_HOVER, 4))
	_unlimited_button.add_theme_stylebox_override("pressed", _play_style(UI_PRIMARY_PRESSED, 1))
	_unlimited_button.add_theme_stylebox_override("disabled", _play_style(Color("d9d3ea"), 0))
	_unlimited_button.add_theme_color_override("font_color", Color.WHITE)
	_unlimited_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_unlimited_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	_unlimited_button.add_theme_color_override("font_disabled_color", Color("8f80bd"))
	_unlimited_button.add_theme_font_size_override("font_size", 16)
	_unlimited_button.add_theme_constant_override("outline_size", 0)
	for heart_node: Node in _endless_hearts_row.get_children():
		var heart := heart_node as TextureRect
		if heart == null:
			continue
		heart.custom_minimum_size = Vector2(26, 24)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _apply_endless_status_style() -> void:
	_endless_heart_label.add_theme_font_override("font", _font_dm_sans_semibold)
	_endless_heart_label.add_theme_font_size_override("font_size", 13)
	_endless_heart_label.add_theme_color_override("font_color", UI_MUTED_TEXT)
	_reward_heart_button.add_theme_font_override("font", _font_fredoka_semibold)
	_reward_heart_button.add_theme_font_size_override("font_size", 13)
	_reward_heart_button.add_theme_color_override("font_color", UI_PRIMARY)
	_reward_heart_button.add_theme_color_override("font_disabled_color", UI_MUTED_TEXT)
	_reward_heart_button.add_theme_stylebox_override("normal", _mode_button_style(Color(1, 0.84, 0, 0.14), UI_YELLOW, 1))
	_reward_heart_button.add_theme_stylebox_override("hover", _mode_button_style(Color(1, 0.84, 0, 0.24), UI_YELLOW, 1))
	_reward_heart_button.add_theme_stylebox_override("pressed", _mode_button_style(Color(1, 0.84, 0, 0.32), UI_YELLOW, 1))
	_reward_heart_button.add_theme_stylebox_override("disabled", _mode_button_style(Color(0.10, 0.04, 0.37, 0.04), UI_BORDER, 1))

func _apply_settings_button_style() -> void:
	_settings_button.text = "⚙︎"
	_settings_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_settings_button.custom_minimum_size = Vector2(40, 40)
	_settings_button.add_theme_font_override("font", _font_dm_sans_bold)
	_settings_button.add_theme_stylebox_override("normal", _settings_icon_style(Color.WHITE, UI_BORDER))
	_settings_button.add_theme_stylebox_override("hover", _settings_icon_style(UI_SURFACE_TINT, UI_PRIMARY))
	_settings_button.add_theme_stylebox_override("pressed", _settings_icon_style(Color("e4dcf6"), UI_PRIMARY))
	_settings_button.add_theme_color_override("font_color", UI_TEXT)
	_settings_button.add_theme_color_override("font_hover_color", UI_TEXT)
	_settings_button.add_theme_color_override("font_pressed_color", UI_TEXT)
	_settings_button.add_theme_font_size_override("font_size", 17)
	_settings_button.add_theme_constant_override("outline_size", 0)

func _apply_home_texts() -> void:
	var is_finnish: bool = PuzzleLoader.get_language() == "fi"
	var daily_puzzle: Dictionary = PuzzleLoader.get_daily_puzzle(Time.get_date_string_from_system())
	if SaveManager.is_daily_challenge_completed():
		_play_button.text = SaveManager.text("view_result")
	else:
		_play_button.text = "Pelaa päivän haaste ->" if is_finnish else "Play Today's Challenge ->"
	_unlimited_title.text = "∞ %s" % SaveManager.text("unlimited_button")
	_unlimited_subtitle.text = SaveManager.text("endless_subtitle")
	var hearts: int = SaveManager.get_endless_hearts()
	var can_claim_heart: bool = SaveManager.can_claim_rewarded_endless_heart()
	if hearts > 0:
		_unlimited_button.disabled = false
		_unlimited_button.text = SaveManager.text("endless_play_button")
	else:
		_unlimited_button.disabled = not can_claim_heart
		_unlimited_button.text = SaveManager.text("endless_watch_ad") if can_claim_heart else SaveManager.text("endless_play_locked")
	_update_home_heart_icons(hearts)
	_endless_heart_label.text = SaveManager.endless_reset_countdown_text()
	var heart_is_full: bool = hearts >= SaveManager.ENDLESS_DAILY_HEARTS
	_endless_status.visible = not heart_is_full
	_reward_heart_button.visible = hearts > 0 and not heart_is_full
	_reward_heart_button.disabled = not can_claim_heart
	_reward_heart_button.text = SaveManager.text("endless_watch_ad") if can_claim_heart else SaveManager.text("endless_ad_claimed")
	if _brand_title != null:
		_brand_title.text = "Word Pyramid"
	if _brand_subtitle != null:
		_brand_subtitle.text = SaveManager.text("home_subtitle")
	if _date_pill != null:
		_date_pill.text = "📅  %s" % _home_date_text(is_finnish)
	if _card_title != null:
		_card_title.text = str(daily_puzzle.get("title", SaveManager.text("home_daily_title")))
	if _card_meta != null:
		_card_meta.text = _daily_card_meta(daily_puzzle, is_finnish)
	if _card_streak != null:
		_card_streak.text = SaveManager.daily_streak_text()
	if _home_hint != null:
		_home_hint.text = "[center]%s[/center]" % SaveManager.text("home_hint_markup")

func _update_home_heart_icons(hearts: int) -> void:
	var index: int = 0
	for heart_node: Node in _endless_hearts_row.get_children():
		var heart := heart_node as TextureRect
		if heart == null:
			continue
		var heart_color: Color = UI_RED if index < hearts else Color("c9c3da")
		heart_color.a = 1.0 if index < hearts else 0.48
		heart.modulate = heart_color
		index += 1

func _on_endless_countdown_tick() -> void:
	if _home_layer.visible and not is_instance_valid(_active_view):
		_apply_home_texts()

func _daily_card_meta(puzzle: Dictionary, is_finnish: bool) -> String:
	var groups: Array = []
	var groups_value: Variant = puzzle.get("groups", [])
	if groups_value is Array:
		groups = groups_value
	var word_count: int = 0
	for group_value: Variant in groups:
		if group_value is Dictionary:
			var group: Dictionary = group_value
			var words: Variant = group.get("words", [])
			if words is Array:
				word_count += words.size()
	if not str(puzzle.get("top_word", "")).is_empty():
		word_count += 1
	var category_count: int = groups.size()
	var theme: String = str(puzzle.get("theme", "")).strip_edges()
	if theme.is_empty():
		theme = str(puzzle.get("title", SaveManager.text("home_daily_title")))
	if is_finnish:
		return "%s · %d sanaa · %d kategoriaa" % [theme, word_count, category_count]
	return "%s · %d words · %d categories" % [theme, word_count, category_count]

func _home_date_text(is_finnish: bool) -> String:
	var date: Dictionary = Time.get_date_dict_from_system()
	var day: int = int(date.get("day", 1))
	var month: int = int(date.get("month", 1))
	var year: int = int(date.get("year", 2026))
	if is_finnish:
		var fi_months: Array[String] = ["tammikuuta", "helmikuuta", "maaliskuuta", "huhtikuuta", "toukokuuta", "kesäkuuta", "heinäkuuta", "elokuuta", "syyskuuta", "lokakuuta", "marraskuuta", "joulukuuta"]
		return "%d. %s %d" % [day, fi_months[clampi(month - 1, 0, 11)], year]
	var en_months: Array[String] = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
	return "%s %d, %d" % [en_months[clampi(month - 1, 0, 11)], day, year]

func _apply_home_card_style() -> void:
	_daily_card.add_theme_stylebox_override("panel", _daily_card_style())
	if _brand_title != null:
		_brand_title.add_theme_font_override("font", _font_fredoka_bold)
		_brand_title.add_theme_font_size_override("font_size", 44)
		_brand_title.add_theme_color_override("font_color", UI_PRIMARY)
		_brand_title.add_theme_constant_override("outline_size", 0)
	if _brand_subtitle != null:
		_brand_subtitle.add_theme_font_override("font", _font_dm_sans_spaced)
		_brand_subtitle.add_theme_font_size_override("font_size", 12)
		_brand_subtitle.add_theme_color_override("font_color", Color("7b6ab5"))
		_brand_subtitle.add_theme_constant_override("outline_size", 0)
	if _date_pill != null:
		_date_pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_date_pill.add_theme_font_override("font", _font_fredoka_semibold)
		_date_pill.add_theme_font_size_override("font_size", 12)
		_date_pill.add_theme_color_override("font_color", UI_PRIMARY)
		_date_pill.add_theme_stylebox_override("normal", _date_pill_style())
		_date_pill.add_theme_constant_override("outline_size", 0)
	if _card_title != null:
		_card_title.add_theme_font_override("font", _font_fredoka_semibold)
		_card_title.add_theme_font_size_override("font_size", 24)
		_card_title.add_theme_color_override("font_color", Color.WHITE)
		_card_title.add_theme_constant_override("outline_size", 0)
	if _card_meta != null:
		_card_meta.add_theme_font_override("font", FONT_DM_SANS)
		_card_meta.add_theme_font_size_override("font_size", 13)
		_card_meta.add_theme_color_override("font_color", Color("8b7dc8"))
		_card_meta.add_theme_constant_override("outline_size", 0)
	if _card_streak != null:
		_card_streak.add_theme_font_override("font", _font_fredoka_semibold)
		_card_streak.add_theme_font_size_override("font_size", 18)
		_card_streak.add_theme_color_override("font_color", UI_YELLOW)
		_card_streak.add_theme_constant_override("outline_size", 0)
	if _home_hint != null:
		_home_hint.bbcode_enabled = true
		_home_hint.fit_content = true
		_home_hint.scroll_active = false
		_home_hint.add_theme_font_override("normal_font", FONT_DM_SANS)
		_home_hint.add_theme_font_override("bold_font", _font_dm_sans_bold)
		_home_hint.add_theme_font_size_override("normal_font_size", 12)
		_home_hint.add_theme_font_size_override("bold_font_size", 12)
		_home_hint.add_theme_color_override("default_color", UI_MUTED_TEXT)

func _thicken_label(label: Label, color: Color, outline_size: int) -> void:
	label.add_theme_color_override("font_outline_color", color)
	label.add_theme_constant_override("outline_size", outline_size)

func _thicken_button(button: Button, color: Color, outline_size: int) -> void:
	button.add_theme_color_override("font_outline_color", color)
	button.add_theme_constant_override("outline_size", outline_size)

func _apply_mini_pyramid_style() -> void:
	var colors: Array[Color] = [UI_MAGENTA, UI_RED, UI_TEAL, UI_YELLOW]
	var pyramid: Node = get_node_or_null("HomeLayer/Content/BrandBlock/MiniPyramid")
	if pyramid == null:
		return
	var row_index: int = 0
	for row: Node in pyramid.get_children():
		var fill: Color = colors[min(row_index, colors.size() - 1)]
		for block: Node in row.get_children():
			if block is Panel:
				(block as Panel).add_theme_stylebox_override("panel", _mini_block_style(fill))
		row_index += 1

func _layout_home_layout() -> void:
	_logo_spacer.custom_minimum_size = Vector2(0, clampf(size.y * 0.012, 8.0, 14.0))
	_bottom_spacer.custom_minimum_size = Vector2.ZERO

func show_game() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_play_button.disabled = true
	_unlimited_button.disabled = true
	var home_tween: Tween = create_tween().set_parallel(true)
	home_tween.tween_property(_home_decor, "modulate:a", 0.0, 0.20)
	home_tween.tween_property(_home_layer, "modulate:a", 0.0, 0.20)
	home_tween.tween_property(_home_layer, "scale", Vector2(0.985, 0.985), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await home_tween.finished
	_hide_home()
	_clear_content()
	var board: GameBoard = GameBoardScene.instantiate()
	board.request_menu.connect(show_main_menu)
	board.request_new_game.connect(_start_next_game)
	board.request_tutorial_exit.connect(_on_tutorial_exit)
	board.modulate.a = 0.0
	add_child(board)
	_active_view = board
	await get_tree().process_frame
	board.refresh()
	var game_tween: Tween = create_tween()
	game_tween.tween_property(board, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await game_tween.finished
	_play_button.disabled = false
	_unlimited_button.disabled = false
	_is_transitioning = false

func _start_next_game() -> void:
	if GameState.game_mode == "unlimited" and not SaveManager.can_start_endless():
		show_main_menu()
		return
	GameState.start_new_game(GameState.game_mode)

func show_statistics() -> void:
	_hide_home()
	_clear_content()
	var panel: VBoxContainer = _make_panel()
	_add_title(panel, SaveManager.text("statistics_title"), SaveManager.text("statistics_subtitle"))
	var wins: int = int(SaveManager.statistics.get("wins", 0))
	var losses: int = int(SaveManager.statistics.get("losses", 0))
	var total: int = wins + losses
	var rate: int = roundi(float(wins) / float(total) * 100.0) if total > 0 else 0
	_add_stat(panel, SaveManager.text("wins"), str(wins))
	_add_stat(panel, SaveManager.text("losses"), str(losses))
	_add_stat(panel, SaveManager.text("win_rate"), "%d%%" % rate)
	_add_stat(panel, SaveManager.text("current_streak"), str(SaveManager.statistics.get("streak", 0)))
	_add_stat(panel, SaveManager.text("best_streak"), str(SaveManager.statistics.get("best_streak", 0)))
	var back: Button = _make_button(SaveManager.text("back"))
	back.pressed.connect(show_main_menu)
	panel.add_child(back)

func show_settings() -> void:
	_show_home()
	_clear_content()
	var overlay: Control = Control.new()
	overlay.name = "SettingsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_active_view = overlay
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.10, 0.04, 0.37, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	dim.gui_input.connect(_on_settings_backdrop_input)
	var bottom: VBoxContainer = VBoxContainer.new()
	_settings_motion_target = bottom
	bottom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bottom.alignment = BoxContainer.ALIGNMENT_END
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(bottom)
	_settings_sheet = PanelContainer.new()
	_settings_sheet.add_theme_stylebox_override("panel", _settings_sheet_style())
	_settings_sheet.gui_input.connect(_on_settings_drag_input)
	bottom.add_child(_settings_sheet)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 40)
	_settings_sheet.add_child(margin)
	var panel: VBoxContainer = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 16)
	margin.add_child(panel)
	var handle: Panel = Panel.new()
	handle.custom_minimum_size = Vector2(40, 4)
	handle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	handle.add_theme_stylebox_override("panel", _handle_style())
	panel.add_child(handle)
	var header: HBoxContainer = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(header)
	var title: Label = Label.new()
	title.text = SaveManager.text("settings_title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", _font_fredoka_semibold)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", UI_TEXT)
	header.add_child(title)
	var close: Button = Button.new()
	close.text = "×"
	close.custom_minimum_size = Vector2(34, 34)
	close.add_theme_font_override("font", _font_fredoka_semibold)
	close.add_theme_font_size_override("font_size", 18)
	close.add_theme_stylebox_override("normal", _mode_button_style(UI_SURFACE_TINT, UI_SURFACE_TINT, 0))
	close.add_theme_stylebox_override("hover", _mode_button_style(Color("e4dcf6"), UI_SURFACE_TINT, 0))
	close.add_theme_color_override("font_color", UI_TEXT)
	close.pressed.connect(show_main_menu)
	header.add_child(close)
	var sound: CheckButton = _settings_toggle(SaveManager.text("sound_effects"))
	sound.button_pressed = bool(SaveManager.settings.get("sound_enabled", true))
	sound.toggled.connect(func(value: bool) -> void:
		SaveManager.settings["sound_enabled"] = value
		SoundManager.enabled = value
		SaveManager.save_data()
	)
	panel.add_child(sound)
	var music: CheckButton = _settings_toggle(SaveManager.text("music"))
	music.button_pressed = bool(SaveManager.settings.get("music_enabled", true))
	music.toggled.connect(func(value: bool) -> void:
		SaveManager.settings["music_enabled"] = value
		SoundManager.set_music_enabled(value)
		SaveManager.save_data()
	)
	panel.add_child(music)
	var language_block: VBoxContainer = VBoxContainer.new()
	language_block.add_theme_constant_override("separation", 10)
	panel.add_child(language_block)
	var language_label: Label = Label.new()
	language_label.text = SaveManager.text("language")
	language_label.add_theme_font_override("font", _font_fredoka_semibold)
	language_label.add_theme_font_size_override("font_size", 16)
	language_label.add_theme_color_override("font_color", UI_TEXT)
	language_block.add_child(language_label)
	var language_row: HBoxContainer = HBoxContainer.new()
	language_row.add_theme_constant_override("separation", 8)
	language_block.add_child(language_row)
	_add_language_chip(language_row, "English", "en")
	_add_language_chip(language_row, "Suomi", "fi")
	var attempts_block: VBoxContainer = VBoxContainer.new()
	attempts_block.add_theme_constant_override("separation", 10)
	panel.add_child(attempts_block)
	var attempts_label: Label = Label.new()
	attempts_label.text = SaveManager.text("attempts_per_puzzle")
	attempts_label.add_theme_font_override("font", _font_fredoka_semibold)
	attempts_label.add_theme_font_size_override("font_size", 16)
	attempts_label.add_theme_color_override("font_color", UI_TEXT)
	attempts_block.add_child(attempts_label)
	var attempts_row: HBoxContainer = HBoxContainer.new()
	attempts_row.add_theme_constant_override("separation", 8)
	attempts_block.add_child(attempts_row)
	for value: int in [3, 4, 5]:
		_add_attempt_chip(attempts_row, value)
	var note: Label = Label.new()
	note.text = SaveManager.text("settings_note")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_override("font", FONT_DM_SANS)
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", UI_MUTED_TEXT)
	panel.add_child(note)
	var tutorial_button: Button = Button.new()
	tutorial_button.text = SaveManager.text("replay_tutorial")
	tutorial_button.custom_minimum_size = Vector2(0, 44)
	tutorial_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_button.add_theme_font_override("font", _font_fredoka_semibold)
	tutorial_button.add_theme_font_size_override("font_size", 14)
	tutorial_button.add_theme_color_override("font_color", UI_TEXT)
	tutorial_button.add_theme_stylebox_override("normal", _mode_button_style(UI_SURFACE_TINT, UI_BORDER))
	tutorial_button.add_theme_stylebox_override("hover", _mode_button_style(Color("e4dcf6"), UI_PRIMARY))
	tutorial_button.add_theme_stylebox_override("pressed", _mode_button_style(Color("ddd3f1"), UI_PRIMARY))
	tutorial_button.pressed.connect(_start_tutorial)
	panel.add_child(tutorial_button)
	var reset_button: Button = Button.new()
	reset_button.text = SaveManager.text("debug_reset_progress")
	reset_button.custom_minimum_size = Vector2(0, 44)
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.add_theme_font_override("font", _font_fredoka_semibold)
	reset_button.add_theme_font_size_override("font_size", 14)
	reset_button.add_theme_color_override("font_color", UI_RED)
	reset_button.add_theme_color_override("font_hover_color", Color.WHITE)
	reset_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	reset_button.add_theme_stylebox_override("normal", _debug_reset_style(false))
	reset_button.add_theme_stylebox_override("hover", _debug_reset_style(true))
	reset_button.add_theme_stylebox_override("pressed", _debug_reset_style(true))
	reset_button.pressed.connect(func() -> void: _on_debug_reset_pressed(reset_button))
	panel.add_child(reset_button)
	_settings_sheet.custom_minimum_size = Vector2(min(size.x, 390.0), 0)
	_settings_sheet.modulate.a = 0.0
	_settings_sheet.scale = Vector2(1.0, 0.96)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_settings_sheet, "modulate:a", 1.0, 0.18)
	tween.tween_property(_settings_sheet, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_settings_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		_dismiss_settings()
	elif event is InputEventScreenTouch and not event.pressed:
		accept_event()
		_dismiss_settings()

func _on_settings_drag_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_start_settings_drag(event.position.y)
		elif _settings_dragging:
			_finish_settings_drag(event.position.y)
	elif event is InputEventScreenDrag and _settings_dragging:
		_update_settings_drag(event.position.y)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_settings_drag(event.global_position.y)
		elif _settings_dragging:
			_finish_settings_drag(event.global_position.y)
	elif event is InputEventMouseMotion and _settings_dragging and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_update_settings_drag(event.global_position.y)

func _start_settings_drag(pointer_y: float) -> void:
	if not is_instance_valid(_settings_sheet) or not is_instance_valid(_settings_motion_target) or _settings_dismissing:
		return
	if _settings_snap_tween != null and _settings_snap_tween.is_running():
		_settings_snap_tween.kill()
	_settings_motion_target.position.y = 0.0
	_settings_dragging = true
	_settings_drag_start_y = pointer_y

func _update_settings_drag(pointer_y: float) -> void:
	if not is_instance_valid(_settings_motion_target):
		return
	var offset: float = max(pointer_y - _settings_drag_start_y, 0.0)
	_settings_motion_target.position.y = offset
	if offset > 8.0:
		accept_event()

func _finish_settings_drag(pointer_y: float) -> void:
	_settings_dragging = false
	var offset: float = max(pointer_y - _settings_drag_start_y, 0.0)
	if offset >= 72.0:
		_dismiss_settings()
	elif is_instance_valid(_settings_motion_target):
		_settings_snap_tween = create_tween()
		_settings_snap_tween.tween_property(_settings_motion_target, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _dismiss_settings() -> void:
	if _settings_dismissing or not is_instance_valid(_settings_sheet) or not is_instance_valid(_settings_motion_target) or not is_instance_valid(_active_view):
		return
	_settings_dismissing = true
	_settings_dragging = false
	if _settings_snap_tween != null and _settings_snap_tween.is_running():
		_settings_snap_tween.kill()
	var overlay: Control = _active_view
	var sheet: PanelContainer = _settings_sheet
	var motion_target: VBoxContainer = _settings_motion_target
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.20)
	tween.tween_property(motion_target, "position:y", motion_target.position.y + sheet.size.y + 24.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	_settings_sheet = null
	_settings_motion_target = null
	_settings_snap_tween = null
	_settings_dismissing = false
	show_main_menu()

func _continue_onboarding() -> void:
	if _is_transitioning:
		call_deferred("_continue_onboarding")
		return
	if SaveManager.needs_language_onboarding():
		_show_language_onboarding()
	elif SaveManager.needs_tutorial_onboarding():
		_start_tutorial()

func _show_language_onboarding() -> void:
	_show_home()
	_clear_content()
	var overlay: Control = Control.new()
	overlay.name = "LanguageOnboarding"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_active_view = overlay
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.10, 0.04, 0.37, 0.58)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	overlay.add_child(center)
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(clampf(size.x - 40.0, 300.0, 390.0), 0)
	card.add_theme_stylebox_override("panel", _round_style(UI_SURFACE, UI_BORDER, 26))
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
	var mark: Label = Label.new()
	mark.text = "▲"
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.add_theme_font_override("font", _font_fredoka_bold)
	mark.add_theme_font_size_override("font_size", 34)
	mark.add_theme_color_override("font_color", UI_MAGENTA)
	content.add_child(mark)
	var title: Label = Label.new()
	title.text = SaveManager.text("choose_language_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font_fredoka_bold)
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", UI_TEXT)
	content.add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = SaveManager.text("choose_language_subtitle")
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_override("font", FONT_DM_SANS)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", UI_MUTED_TEXT)
	content.add_child(subtitle)
	for language: Dictionary in [{"label": "English", "code": "en"}, {"label": "Suomi", "code": "fi"}]:
		var language_button: Button = _make_button(str(language["label"]))
		language_button.custom_minimum_size = Vector2(0, 54)
		language_button.add_theme_font_override("font", _font_fredoka_semibold)
		language_button.add_theme_font_size_override("font_size", 18)
		language_button.pressed.connect(_select_onboarding_language.bind(str(language["code"])))
		content.add_child(language_button)

func _select_onboarding_language(language_code: String) -> void:
	if not PuzzleLoader.set_language(language_code):
		return
	SaveManager.mark_onboarding_language_selected()
	_apply_home_texts()
	_start_tutorial()

func _start_tutorial() -> void:
	if _is_transitioning:
		return
	_clear_content()
	if GameState.start_tutorial():
		show_game()

func _on_tutorial_exit(_completed: bool) -> void:
	SaveManager.complete_onboarding()
	GameState.reset_debug_state()
	show_main_menu()

func _add_language_chip(row: HBoxContainer, label_text: String, language_code: String) -> void:
	var selected: bool = PuzzleLoader.get_language() == language_code
	var button: Button = _chip_button(label_text, selected)
	button.pressed.connect(func() -> void:
		if PuzzleLoader.set_language(language_code):
			SaveManager.active_game.clear()
			SaveManager.save_data()
			_apply_home_texts()
			show_settings()
	)
	row.add_child(button)

func _add_attempt_chip(row: HBoxContainer, value: int) -> void:
	var selected: bool = value == int(SaveManager.settings.get("attempts", 4))
	var button: Button = _chip_button(str(value), selected)
	button.pressed.connect(func() -> void:
		SaveManager.settings["attempts"] = value
		SaveManager.save_data()
		show_settings()
	)
	row.add_child(button)

func _on_debug_reset_pressed(button: Button) -> void:
	if not bool(button.get_meta("reset_armed", false)):
		button.set_meta("reset_armed", true)
		button.text = SaveManager.text("debug_reset_confirm")
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_stylebox_override("normal", _debug_reset_style(true))
		return
	SaveManager.reset_all_data()
	GameState.reset_debug_state()
	PuzzleLoader.load_puzzles()
	SoundManager.enabled = bool(SaveManager.settings.get("sound_enabled", true))
	SoundManager.set_music_enabled(bool(SaveManager.settings.get("music_enabled", true)))
	_play_button.disabled = false
	_unlimited_button.disabled = false
	var pool_notice: Node = _home_layer.get_node_or_null("Content/PoolCompleteNotice")
	if pool_notice != null:
		pool_notice.queue_free()
	show_main_menu()
	call_deferred("_continue_onboarding")

func _settings_toggle(label_text: String) -> CheckButton:
	var button: CheckButton = CheckButton.new()
	button.text = label_text
	button.add_theme_font_override("font", _font_fredoka_semibold)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", UI_TEXT)
	button.add_theme_color_override("font_pressed_color", UI_TEXT)
	button.add_theme_color_override("font_hover_color", UI_TEXT)
	button.add_theme_color_override("font_hover_pressed_color", UI_TEXT)
	button.add_theme_color_override("font_focus_color", UI_TEXT)
	button.add_theme_color_override("font_disabled_color", UI_MUTED_TEXT)
	var transparent_row: StyleBoxFlat = _round_style(Color.TRANSPARENT, Color.TRANSPARENT, 0)
	transparent_row.set_border_width_all(0)
	transparent_row.content_margin_left = 0.0
	transparent_row.content_margin_right = 0.0
	transparent_row.content_margin_top = 0.0
	transparent_row.content_margin_bottom = 0.0
	button.add_theme_stylebox_override("normal", transparent_row)
	button.add_theme_stylebox_override("hover", transparent_row)
	button.add_theme_stylebox_override("pressed", transparent_row)
	button.add_theme_stylebox_override("hover_pressed", transparent_row)
	button.add_theme_icon_override("checked", SETTINGS_TOGGLE_ON)
	button.add_theme_icon_override("checked_disabled", SETTINGS_TOGGLE_ON)
	button.add_theme_icon_override("unchecked", SETTINGS_TOGGLE_OFF)
	button.add_theme_icon_override("unchecked_disabled", SETTINGS_TOGGLE_OFF)
	return button

func _chip_button(label_text: String, selected: bool) -> Button:
	var button: Button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(82, 34)
	button.add_theme_font_override("font", _font_fredoka_semibold)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", _chip_style(selected))
	button.add_theme_stylebox_override("hover", _chip_style(true))
	button.add_theme_stylebox_override("pressed", _chip_style(true))
	button.add_theme_color_override("font_color", Color.WHITE if selected else UI_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	return button

func _clear_content() -> void:
	if is_instance_valid(_active_view):
		_active_view.queue_free()
	_active_view = null

func _make_panel() -> VBoxContainer:
	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_active_view = overlay
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = UI_BACKGROUND
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(backdrop)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 24)
	overlay.add_child(center)
	var panel: VBoxContainer = VBoxContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 16)
	center.add_child(panel)
	panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.22)
	return panel

func _add_title(panel: VBoxContainer, heading: String, subheading: String) -> void:
	var title: Label = Label.new()
	title.text = heading
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", UI_TEXT)
	panel.add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = subheading
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", UI_MUTED_TEXT)
	panel.add_child(subtitle)

func _add_stat(panel: VBoxContainer, label_text: String, value_text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value: Label = Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", UI_PRIMARY)
	row.add_child(value)
	panel.add_child(row)

func _make_button(text_value: String) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(280, 54)
	button.add_theme_font_size_override("font_size", 18)
	return button

func _create_home_decor() -> Control:
	var layer: Control = Control.new()
	layer.name = "HomeDecor"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var base: ColorRect = ColorRect.new()
	base.color = UI_BACKGROUND
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(base)
	_add_decor_shape(layer, Vector2(-40, -40), Vector2(160, 160), UI_YELLOW, 0.26, 80)
	_add_decor_shape(layer, Vector2(size.x - 88, 12), Vector2(76, 76), UI_MAGENTA, 0.16, 0, 18.0)
	_add_decor_shape(layer, Vector2(12, size.y - 132), Vector2(72, 56), UI_TEAL, 0.16, 0, -8.0)
	_add_decor_shape(layer, Vector2(size.x - 104, size.y - 96), Vector2(120, 120), UI_RED, 0.18, 60)
	_add_decor_shape(layer, Vector2(24, size.y * 0.46), Vector2(24, 24), UI_MAGENTA, 0.10, 12)
	_add_decor_shape(layer, Vector2(size.x - 44, size.y * 0.34), Vector2(16, 16), UI_YELLOW, 0.28, 0)
	return layer

func _add_decor_shape(parent: Control, position: Vector2, shape_size: Vector2, color: Color, alpha: float, radius: int, rotation_degrees_value: float = 0.0) -> void:
	var panel: Panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = position
	panel.custom_minimum_size = shape_size
	panel.size = shape_size
	panel.pivot_offset = shape_size * 0.5
	panel.rotation_degrees = rotation_degrees_value
	panel.add_theme_stylebox_override("panel", _decor_shape_style(color, alpha, radius))
	parent.add_child(panel)

func _round_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _decor_shape_style(fill: Color, alpha: float, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	var bg: Color = fill
	bg.a = alpha
	style.bg_color = bg
	style.border_color = Color.TRANSPARENT
	style.set_corner_radius_all(radius)
	return style

func _settings_sheet_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(UI_BACKGROUND, UI_BACKGROUND, 24)
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.shadow_color = Color(0.10, 0.04, 0.37, 0.18)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, -8)
	return style

func _debug_reset_style(armed: bool) -> StyleBoxFlat:
	var fill: Color = UI_RED if armed else Color("fff1ee")
	var style: StyleBoxFlat = _round_style(fill, UI_RED, 12)
	style.set_border_width_all(2)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _handle_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(UI_BORDER, UI_BORDER, 2)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	return style

func _chip_style(selected: bool) -> StyleBoxFlat:
	var fill: Color = UI_PRIMARY if selected else UI_SURFACE
	var border: Color = UI_PRIMARY if selected else UI_BORDER
	var style: StyleBoxFlat = _round_style(fill, border, 20)
	style.set_border_width_all(2)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 7.0
	style.content_margin_bottom = 7.0
	return style

func _mini_block_style(fill: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(fill, fill, 3)
	style.shadow_color = Color(0, 0, 0, 0.14)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	return style

func _date_pill_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(UI_YELLOW, UI_YELLOW, 20)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style

func _daily_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(UI_PRIMARY, UI_PRIMARY, 22)
	style.shadow_color = UI_MAGENTA
	style.shadow_size = 1
	style.shadow_offset = Vector2(7, 7)
	return style

func _infinity_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color(1, 1, 1, 0.96), UI_BORDER, 18)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.10, 0.04, 0.37, 0.10)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style

func _pill_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color(1.0, 1.0, 1.0, 0.92), UI_BORDER, 10)
	style.shadow_color = Color(0, 0, 0, 0.05)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style

func _preview_block_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color("dbe7ff"), Color("b8c7ea"), 10)
	style.shadow_color = Color(0, 0, 0, 0.06)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style

func _ground_shadow_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color(0, 0, 0, 0.05), Color.TRANSPARENT, 12)
	style.shadow_color = Color(0, 0, 0, 0.04)
	style.shadow_size = 6
	return style

func _play_style(fill: Color, shadow_size: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(fill, fill, 13)
	style.set_border_width_all(0)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(3, 3)
	return style

func _mode_button_style(fill: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(fill, border, 13)
	style.set_border_width_all(border_width)
	style.shadow_color = Color(0, 0, 0, 0.05)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 1)
	return style

func _settings_icon_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(fill, border, 12)
	style.set_border_width_all(2)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 1.0
	style.shadow_color = Color(0, 0, 0, 0.07)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style

func _theme_setup() -> void:
	var theme: Theme = Theme.new()
	var button_style: StyleBoxFlat = _round_style(Color("eef0f4"), UI_BORDER, 10)
	button_style.content_margin_left = 14.0
	button_style.content_margin_right = 14.0
	button_style.content_margin_top = 8.0
	button_style.content_margin_bottom = 8.0
	var hover_style: StyleBoxFlat = button_style.duplicate()
	hover_style.bg_color = Color("e1e6ef")
	var pressed_style: StyleBoxFlat = button_style.duplicate()
	pressed_style.bg_color = Color("d3dbe8")
	theme.set_stylebox("normal", "Button", button_style)
	theme.set_stylebox("hover", "Button", hover_style)
	theme.set_stylebox("pressed", "Button", pressed_style)
	theme.set_color("font_color", "Button", UI_TEXT)
	theme.set_color("font_hover_color", "Button", UI_TEXT)
	theme.set_color("font_pressed_color", "Button", UI_TEXT)
	theme.set_color("font_color", "Label", UI_TEXT)
	theme.set_font("font", "Button", _font_dm_sans_semibold)
	theme.set_font("font", "Label", _font_dm_sans_semibold)
	theme.set_font("font", "HomePill", _font_dm_sans_semibold)
	theme.set_font("font", "HomeMenuButton", _font_dm_sans_semibold)
	theme.set_font("font", "SideActionButton", _font_fredoka_semibold)
	theme.set_font("font", "PrimaryPlayButton", _font_fredoka_bold)
	theme.set_font_size("font_size", "Label", 17)
	theme.set_font_size("font_size", "Button", 16)
	theme.set_stylebox("panel", "Panel", button_style)
	theme.set_stylebox("normal", "HomePill", _pill_style())
	theme.set_color("font_color", "HomePill", UI_TEXT)
	theme.set_font_size("font_size", "HomePill", 15)
	theme.set_stylebox("normal", "HomeDatePill", _date_pill_style())
	theme.set_font("font", "HomeDatePill", _font_dm_sans_bold)
	theme.set_color("font_color", "HomeDatePill", UI_PRIMARY)
	theme.set_font_size("font_size", "HomeDatePill", 13)
	theme.set_stylebox("normal", "HomeMenuButton", _round_style(UI_SURFACE, UI_BORDER, 10))
	theme.set_stylebox("hover", "HomeMenuButton", _round_style(UI_SURFACE_TINT, Color("b8c7ea"), 10))
	theme.set_color("font_color", "HomeMenuButton", UI_TEXT)
	theme.set_font_size("font_size", "HomeMenuButton", 15)
	theme.set_stylebox("normal", "SideActionButton", _side_action_style(UI_SURFACE, 4))
	theme.set_stylebox("hover", "SideActionButton", _side_action_style(UI_SURFACE_TINT, 4))
	theme.set_color("font_color", "SideActionButton", UI_PRIMARY)
	theme.set_font_size("font_size", "SideActionButton", 22)
	theme.set_stylebox("panel", "PreviewTile", _preview_block_style())
	theme.set_stylebox("panel", "GroundShadow", _ground_shadow_style())
	theme.set_stylebox("panel", "BottomCard", _bottom_card_style())
	theme.set_stylebox("normal", "PrimaryPlayButton", _play_style(UI_PRIMARY, 5))
	theme.set_stylebox("hover", "PrimaryPlayButton", _play_style(UI_PRIMARY_HOVER, 5))
	theme.set_stylebox("pressed", "PrimaryPlayButton", _play_style(UI_PRIMARY_PRESSED, 2))
	theme.set_color("font_color", "PrimaryPlayButton", Color.WHITE)
	theme.set_color("font_hover_color", "PrimaryPlayButton", Color.WHITE)
	theme.set_color("font_pressed_color", "PrimaryPlayButton", Color.WHITE)
	theme.set_font_size("font_size", "PrimaryPlayButton", 25)
	self.theme = theme

func _side_action_style(fill: Color, shadow_size: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(fill, UI_BORDER, 10)
	style.shadow_color = Color(0, 0, 0, 0.06)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 2)
	return style

func _bottom_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color(1.0, 1.0, 1.0, 0.92), UI_BORDER, 12)
	style.shadow_color = Color(0, 0, 0, 0.06)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	return style
