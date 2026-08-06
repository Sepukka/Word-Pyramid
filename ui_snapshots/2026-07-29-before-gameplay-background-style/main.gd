extends Control

const GameBoardScene: PackedScene = preload("res://scenes/game_board.tscn")
const FONT_FREDOKA: Font = preload("res://assets/fonts/Fredoka.ttf")
const FONT_DM_SANS: Font = preload("res://assets/fonts/DMSans.ttf")
const SETTINGS_TOGGLE_ON: Texture2D = preload("res://assets/toggle_on.svg")
const SETTINGS_TOGGLE_OFF: Texture2D = preload("res://assets/toggle_off.svg")
const TROPHY_ICON: Texture2D = preload("res://assets/icons/trophy.svg")
const ACHIEVEMENT_STAR: Texture2D = preload("res://assets/icons/achievement_star.svg")
const ACHIEVEMENT_STAR_LOCKED: Texture2D = preload("res://assets/icons/achievement_star_locked.svg")
const LOCK_ICON: Texture2D = preload("res://assets/icons/lock.svg")
const HEART_ICON: Texture2D = preload("res://assets/heart.svg")
const STREAK_FLAME_ICON: Texture2D = preload("res://assets/icons/flame_streak.svg")
const PRIVACY_POLICY_URL: String = "https://sepukka.github.io/Word-Pyramid/"
const PALETTE = preload("res://scripts/ui/ui_palette.gd")

const UI_BACKGROUND: Color = PALETTE.BACKGROUND
const UI_SURFACE: Color = PALETTE.SURFACE
const UI_PRIMARY: Color = PALETTE.PRIMARY
const UI_PRIMARY_HOVER: Color = PALETTE.PRIMARY_HOVER
const UI_PRIMARY_PRESSED: Color = PALETTE.PRIMARY_PRESSED
const UI_TEXT: Color = PALETTE.TEXT
const UI_MUTED_TEXT: Color = PALETTE.MUTED_TEXT
const UI_MUTED_ON_PRIMARY: Color = PALETTE.MUTED_ON_PRIMARY
const UI_BORDER: Color = PALETTE.BORDER
const UI_SURFACE_TINT: Color = PALETTE.SURFACE_TINT
const UI_YELLOW: Color = PALETTE.ACCENT
const UI_ACCENT_HOVER: Color = PALETTE.ACCENT_HOVER
const UI_ACCENT_PRESSED: Color = PALETTE.ACCENT_PRESSED
const UI_MAGENTA: Color = PALETTE.HINT
const UI_RED: Color = PALETTE.ERROR
const UI_TEAL: Color = PALETTE.SUCCESS
const UI_DISABLED_FILL: Color = PALETTE.DISABLED_FILL
const UI_DISABLED_TEXT: Color = PALETTE.DISABLED_TEXT
const STREAK_GREEN: Color = PALETTE.STREAK_SUCCESS
const STREAK_EMPTY: Color = PALETTE.STREAK_EMPTY

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
@onready var _achievements_button: Button = get_node_or_null("HomeLayer/Content/Header/AchievementsButton") as Button
@onready var _daily_card: PanelContainer = get_node_or_null("HomeLayer/Content/DailyCard") as PanelContainer
@onready var _brand_title: RichTextLabel = get_node_or_null("HomeLayer/Content/BrandBlock/Title") as RichTextLabel
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
var _achievement_mouse_drag_start_y: float = 0.0
var _achievement_mouse_drag_start_scroll: int = 0
var _achievement_mouse_dragging: bool = false
var _settings_dismissing: bool = false
var _settings_snap_tween: Tween
var _endless_countdown_timer: Timer
var _font_fredoka_semibold: FontVariation
var _font_fredoka_bold: FontVariation
var _font_dm_sans_semibold: FontVariation
var _font_dm_sans_bold: FontVariation
var _font_dm_sans_black: FontVariation
var _font_dm_sans_spaced: FontVariation
var _achievement_unlock_queue: Array[Dictionary] = []
var _achievement_banner_showing: bool = false
var _heart_reward_overlay: Control
var _home_streak_calendar: VBoxContainer

func _ready() -> void:
	if _home_layer == null or _play_button == null or _unlimited_card == null or _unlimited_button == null or _endless_hearts_row == null or _endless_status == null or _endless_heart_label == null or _reward_heart_button == null or _settings_button == null or _achievements_button == null or _daily_card == null:
		# The editor can keep an older Main scene in memory after its .tscn file
		# changes externally. Reload once so the editable scene tree is used.
		call_deferred("_reload_editable_home_scene")
		return
	_setup_font_variations()
	_home_decor = _create_home_decor()
	add_child(_home_decor)
	move_child(_home_decor, 0)
	_theme_setup()
	_apply_home_card_style()
	_install_home_streak_calendar()
	_apply_play_button_style()
	_apply_unlimited_button_style()
	_apply_endless_status_style()
	_apply_settings_button_style()
	_apply_achievements_button_style()
	_play_button.button_down.connect(func() -> void: _animate_play_button(0.97))
	_play_button.button_up.connect(func() -> void: _animate_play_button(1.0))
	_unlimited_button.pressed.connect(_on_unlimited_pressed)
	_reward_heart_button.pressed.connect(_on_rewarded_heart_pressed)
	_settings_button.pressed.connect(show_settings)
	_achievements_button.pressed.connect(show_achievements)
	if not SaveManager.achievement_unlocked.is_connected(_on_achievement_unlocked):
		SaveManager.achievement_unlocked.connect(_on_achievement_unlocked)
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
	_font_dm_sans_black = _font_variation(FONT_DM_SANS, 900, 0.72)
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
	var heart_state_before: Dictionary = _capture_endless_heart_state()
	_clear_content()
	_apply_home_texts()
	_refresh_achievement_badge()
	_show_home()
	_layout_home_layout()
	var refill_amount: int = _daily_heart_refill_amount(heart_state_before)
	if refill_amount > 0:
		call_deferred("_play_heart_reward_event", refill_amount, true, int(heart_state_before.get("hearts", 0)))

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
	if not SaveManager.is_daily_unlocked():
		_apply_home_texts()
		return
	if SaveManager.is_daily_challenge_completed():
		if GameState.view_daily_result():
			show_game()
			return
	if GameState.has_resumable_game(GameState.DAILY_MODE):
		# Continue today's Daily exactly where the player left it. restore_game()
		# rejects and clears an expired save, after which the current Daily starts.
		if GameState.restore_game():
			show_game()
			return
	if GameState.start_new_game("daily"):
		show_game()

func _on_unlimited_pressed() -> void:
	if _is_transitioning:
		return
	if GameState.is_puzzle_pool_completed(GameState.UNLIMITED_MODE):
		_apply_home_texts()
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
	var hearts_before: int = int(SaveManager.endless_state.get("hearts", 0))
	if SaveManager.grant_rewarded_endless_heart():
		var hearts_after: int = SaveManager.get_endless_hearts()
		_apply_home_texts()
		_endless_heart_label.text = SaveManager.text("endless_heart_earned")
		_play_heart_reward_event(maxi(hearts_after - hearts_before, 1), false, hearts_before)

func _on_home_rewarded_ad_unavailable(message: String) -> void:
	if _home_layer.visible and not is_instance_valid(_active_view):
		_apply_home_texts()
		_endless_heart_label.text = message

func _on_puzzle_pool_completed(mode: String) -> void:
	if is_instance_valid(_active_view):
		return
	_apply_home_texts()
	var old_notice: Node = _home_layer.find_child("PoolCompleteNotice", true, false)
	if is_instance_valid(old_notice):
		old_notice.queue_free()
	if mode == GameState.UNLIMITED_MODE:
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
	_play_button.add_theme_stylebox_override("hover", _play_style(UI_ACCENT_HOVER, 1))
	_play_button.add_theme_stylebox_override("pressed", _play_style(UI_ACCENT_PRESSED, 0))
	_play_button.add_theme_color_override("font_color", UI_PRIMARY)
	_play_button.add_theme_color_override("font_hover_color", UI_PRIMARY)
	_play_button.add_theme_color_override("font_pressed_color", UI_PRIMARY)
	_play_button.add_theme_font_size_override("font_size", 18)
	_play_button.add_theme_constant_override("outline_size", 0)
	_apply_daily_unlock_visuals(SaveManager.is_daily_unlocked())

func _apply_daily_unlock_visuals(unlocked: bool) -> void:
	if _daily_card == null or _play_button == null:
		return
	if unlocked:
		_daily_card.add_theme_stylebox_override("panel", _daily_card_style())
		_play_button.add_theme_stylebox_override("normal", _play_style(UI_YELLOW, 1))
		_play_button.add_theme_stylebox_override("hover", _play_style(UI_ACCENT_HOVER, 1))
		_play_button.add_theme_stylebox_override("pressed", _play_style(UI_ACCENT_PRESSED, 0))
		_play_button.add_theme_stylebox_override("disabled", _play_style(UI_DISABLED_FILL, 0))
		_play_button.add_theme_color_override("font_color", UI_PRIMARY)
		_play_button.add_theme_color_override("font_hover_color", UI_PRIMARY)
		_play_button.add_theme_color_override("font_pressed_color", UI_PRIMARY)
		_play_button.add_theme_color_override("font_disabled_color", Color("81759f"))
		if _date_pill != null:
			_date_pill.add_theme_stylebox_override("normal", _date_pill_style())
			_date_pill.add_theme_color_override("font_color", UI_PRIMARY)
		if _card_title != null:
			_card_title.add_theme_color_override("font_color", Color.WHITE)
		if _card_meta != null:
			_card_meta.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
		if _card_streak != null:
			_card_streak.add_theme_color_override("font_color", UI_YELLOW)
		return
	_daily_card.add_theme_stylebox_override("panel", _daily_locked_card_style())
	_play_button.add_theme_stylebox_override("disabled", _play_style(Color("c9c3d3"), 0))
	_play_button.add_theme_color_override("font_disabled_color", UI_DISABLED_TEXT)
	if _date_pill != null:
		_date_pill.add_theme_stylebox_override("normal", _round_style(Color("e5e1ea"), Color("c9c3d3"), 20))
		_date_pill.add_theme_color_override("font_color", UI_DISABLED_TEXT)
	if _card_title != null:
		_card_title.add_theme_color_override("font_color", Color("372e49"))
	if _card_meta != null:
		_card_meta.add_theme_color_override("font_color", Color("71677f"))
	if _card_streak != null:
		_card_streak.add_theme_color_override("font_color", UI_DISABLED_TEXT)

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
	_unlimited_button.add_theme_stylebox_override("disabled", _play_style(UI_DISABLED_FILL, 0))
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

func _apply_achievements_button_style() -> void:
	_achievements_button.text = ""
	_achievements_button.icon = TROPHY_ICON
	_achievements_button.expand_icon = true
	_achievements_button.custom_minimum_size = Vector2(40, 40)
	_achievements_button.add_theme_stylebox_override("normal", _settings_icon_style(Color.WHITE, UI_BORDER))
	_achievements_button.add_theme_stylebox_override("hover", _settings_icon_style(Color("fff8ce"), UI_YELLOW))
	_achievements_button.add_theme_stylebox_override("pressed", _settings_icon_style(Color("ffef92"), UI_PRIMARY))
	_achievements_button.tooltip_text = SaveManager.text("achievements")
	_refresh_achievement_badge()

func _refresh_achievement_badge() -> void:
	if not is_instance_valid(_achievements_button):
		return
	var old_badge: Node = _achievements_button.get_node_or_null("NewStarsBadge")
	if old_badge != null:
		old_badge.queue_free()

func _on_achievement_unlocked(unlock: Dictionary) -> void:
	_achievement_unlock_queue.append(unlock.duplicate(true))
	if not _achievement_banner_showing:
		call_deferred("_show_next_achievement_banner")

func _show_next_achievement_banner() -> void:
	if _achievement_banner_showing or _achievement_unlock_queue.is_empty():
		return
	_achievement_banner_showing = true
	var unlock: Dictionary = _achievement_unlock_queue.pop_front()
	var host := Control.new()
	host.name = "AchievementUnlockHost"
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.z_index = 180
	add_child(host)
	var banner_width: float = clampf(size.x - 56.0, 280.0, 330.0)
	var banner_height: float = 68.0
	var target_y: float = 62.0
	var banner := PanelContainer.new()
	banner.name = "AchievementUnlockBanner"
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.position = Vector2((size.x - banner_width) * 0.5, -banner_height - 12.0)
	banner.size = Vector2(banner_width, banner_height)
	banner.custom_minimum_size = Vector2(banner_width, banner_height)
	banner.add_theme_stylebox_override("panel", _achievement_unlock_style())
	host.add_child(banner)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	banner.add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	var icon_plate := PanelContainer.new()
	icon_plate.custom_minimum_size = Vector2(42, 42)
	icon_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_plate.add_theme_stylebox_override("panel", _achievement_badge_style(UI_YELLOW, UI_YELLOW, 13))
	row.add_child(icon_plate)
	var trophy := TextureRect.new()
	trophy.texture = TROPHY_ICON
	trophy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trophy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	trophy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_plate.add_child(trophy)
	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.custom_minimum_size.x = 0
	text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_stack.add_theme_constant_override("separation", -2)
	row.add_child(text_stack)
	var kicker := Label.new()
	kicker.text = SaveManager.text("achievement_unlocked")
	kicker.clip_text = true
	kicker.add_theme_font_override("font", _font_dm_sans_spaced)
	kicker.add_theme_font_size_override("font_size", 8)
	kicker.add_theme_color_override("font_color", UI_YELLOW)
	text_stack.add_child(kicker)
	var title := Label.new()
	title.text = str(unlock.get("title", "Achievement"))
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_override("font", _font_fredoka_bold)
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color.WHITE)
	text_stack.add_child(title)
	var description := Label.new()
	description.text = str(unlock.get("description", ""))
	description.clip_text = true
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.add_theme_font_override("font", FONT_DM_SANS)
	description.add_theme_font_size_override("font_size", 9)
	description.add_theme_color_override("font_color", UI_MUTED_ON_PRIMARY)
	text_stack.add_child(description)
	var tier_stack := VBoxContainer.new()
	tier_stack.custom_minimum_size.x = 34
	tier_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tier_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(tier_stack)
	var star := TextureRect.new()
	star.custom_minimum_size = Vector2(26, 26)
	star.texture = ACHIEVEMENT_STAR
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tier_stack.add_child(star)
	var tier := Label.new()
	tier.text = SaveManager.text("achievement_star_tier") % [int(unlock.get("unlocked_star", 1)), int(unlock.get("max_stars", 1))]
	tier.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier.clip_text = true
	tier.add_theme_font_override("font", _font_dm_sans_bold)
	tier.add_theme_font_size_override("font_size", 7)
	tier.add_theme_color_override("font_color", Color.WHITE)
	tier_stack.add_child(tier)

	SoundManager.achievement_unlock()
	var enter_tween := create_tween()
	enter_tween.tween_property(banner, "position:y", target_y, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await enter_tween.finished
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(banner):
		var exit_tween := create_tween()
		exit_tween.tween_property(banner, "position:y", -banner_height - 12.0, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		await exit_tween.finished
	if is_instance_valid(host):
		host.queue_free()
	_achievement_banner_showing = false
	if not _achievement_unlock_queue.is_empty():
		await get_tree().create_timer(0.16).timeout
		_show_next_achievement_banner()

func _apply_home_texts() -> void:
	var is_finnish: bool = PuzzleLoader.get_language() == "fi"
	var daily_puzzle: Dictionary = PuzzleLoader.get_daily_puzzle(Time.get_date_string_from_system())
	var daily_unlocked: bool = SaveManager.is_daily_unlocked()
	if not daily_unlocked:
		_play_button.disabled = true
		_play_button.text = SaveManager.text("daily_unlock_button") % SaveManager.DAILY_UNLOCK_LEVEL
		_play_button.icon = LOCK_ICON
		_play_button.expand_icon = true
		_play_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_play_button.add_theme_constant_override("icon_max_width", 23)
	elif SaveManager.is_daily_challenge_completed():
		_play_button.disabled = false
		_play_button.text = SaveManager.text("view_result")
	else:
		_play_button.disabled = false
		_play_button.text = "Pelaa päivän haaste →" if is_finnish else "Play Today's Challenge →"
	if daily_unlocked:
		_play_button.icon = null
	_unlimited_title.text = "∞ %s" % SaveManager.text("unlimited_button")
	_unlimited_subtitle.text = "%s · %s" % [
		SaveManager.text("endless_subtitle"),
		SaveManager.text("level_short") % SaveManager.get_player_level()
	]
	var hearts: int = SaveManager.get_endless_hearts()
	var can_claim_heart: bool = SaveManager.can_claim_rewarded_endless_heart()
	var unlimited_pool_complete: bool = GameState.is_puzzle_pool_completed(GameState.UNLIMITED_MODE)
	if unlimited_pool_complete:
		_unlimited_button.disabled = true
		_unlimited_button.text = SaveManager.text("all_played")
		_unlimited_subtitle.text = "%s · %s" % [
			SaveManager.text("unlimited_pool_complete_short"),
			SaveManager.text("level_short") % SaveManager.get_player_level()
		]
	elif hearts > 0:
		_unlimited_button.disabled = false
		_unlimited_button.text = SaveManager.text("endless_play_button")
	else:
		_unlimited_button.disabled = not can_claim_heart
		_unlimited_button.text = SaveManager.text("endless_watch_ad") if can_claim_heart else SaveManager.text("endless_play_locked")
	_update_home_heart_icons(hearts)
	_endless_heart_label.text = SaveManager.text("unlimited_pool_complete_body") if unlimited_pool_complete else SaveManager.endless_reset_countdown_text()
	var heart_is_full: bool = hearts >= SaveManager.ENDLESS_DAILY_HEARTS
	_endless_status.visible = unlimited_pool_complete or not heart_is_full
	_reward_heart_button.visible = not unlimited_pool_complete and hearts > 0 and not heart_is_full
	_reward_heart_button.disabled = not can_claim_heart
	_reward_heart_button.text = SaveManager.text("endless_watch_ad") if can_claim_heart else SaveManager.text("endless_ad_claimed")
	if _brand_title != null:
		_brand_title.text = "[center][color=#17075D]WORD[/color] [color=#7040ED]ASCENT[/color][/center]"
	if _brand_subtitle != null:
		_brand_subtitle.text = SaveManager.text("home_subtitle")
	if _date_pill != null:
		_date_pill.text = SaveManager.text("daily_unlock_button") % SaveManager.DAILY_UNLOCK_LEVEL if not daily_unlocked else "📅 %s" % _home_date_text(is_finnish)
	if _card_title != null:
		_card_title.text = SaveManager.text("daily_locked_title") if not daily_unlocked else str(daily_puzzle.get("title", SaveManager.text("home_daily_title")))
	if _card_meta != null:
		_card_meta.text = SaveManager.text("daily_locked_body") % SaveManager.DAILY_UNLOCK_LEVEL if not daily_unlocked else _daily_card_meta(daily_puzzle, is_finnish)
	if _card_streak != null:
		_card_streak.text = SaveManager.text("daily_locked_progress") % [SaveManager.get_player_level(), SaveManager.DAILY_UNLOCK_LEVEL] if not daily_unlocked else SaveManager.daily_streak_text()
	_refresh_home_streak_calendar(daily_unlocked)
	if _home_hint != null:
		_home_hint.text = "[center]%s[/center]" % SaveManager.text("home_hint_markup")
	if _achievements_button != null:
		_achievements_button.tooltip_text = SaveManager.text("achievements")
	_apply_daily_unlock_visuals(daily_unlocked)

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
		var heart_state_before: Dictionary = _capture_endless_heart_state()
		_apply_home_texts()
		var refill_amount: int = _daily_heart_refill_amount(heart_state_before)
		if refill_amount > 0:
			_play_heart_reward_event(refill_amount, true, int(heart_state_before.get("hearts", 0)))

func _capture_endless_heart_state() -> Dictionary:
	return {
		"date": str(SaveManager.endless_state.get("date", "")),
		"hearts": clampi(int(SaveManager.endless_state.get("hearts", SaveManager.ENDLESS_DAILY_HEARTS)), 0, SaveManager.ENDLESS_DAILY_HEARTS),
	}

func _daily_heart_refill_amount(previous_state: Dictionary) -> int:
	var previous_date: String = str(previous_state.get("date", ""))
	var current_date: String = Time.get_date_string_from_system()
	if previous_date.is_empty() or previous_date == current_date:
		return 0
	if str(SaveManager.endless_state.get("date", "")) != current_date:
		return 0
	var previous_hearts: int = int(previous_state.get("hearts", SaveManager.ENDLESS_DAILY_HEARTS))
	var current_hearts: int = int(SaveManager.endless_state.get("hearts", SaveManager.ENDLESS_DAILY_HEARTS))
	return maxi(current_hearts - previous_hearts, 0)

func _play_heart_reward_event(amount: int, daily_refill: bool = false, previous_hearts: int = -1) -> void:
	if amount <= 0:
		return
	if daily_refill and (not _home_layer.visible or is_instance_valid(_active_view)):
		return
	if is_instance_valid(_heart_reward_overlay):
		_heart_reward_overlay.queue_free()
	SoundManager.heart_gain()
	var overlay: Control = Control.new()
	overlay.name = "HeartRewardOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 500
	add_child(overlay)
	_heart_reward_overlay = overlay

	var dim: ColorRect = ColorRect.new()
	dim.color = Color(UI_PRIMARY, 0.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var card: PanelContainer = PanelContainer.new()
	card.name = "HeartRewardCard"
	card.custom_minimum_size = Vector2(252, 214)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _heart_reward_card_style())
	card.modulate.a = 0.0
	card.scale = Vector2(0.68, 0.68)
	center.add_child(card)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 4)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)
	var heart: TextureRect = TextureRect.new()
	heart.name = "HeartRewardIcon"
	heart.texture = HEART_ICON
	heart.custom_minimum_size = Vector2(92, 82)
	heart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart.modulate = UI_RED
	heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(heart)
	var title: Label = Label.new()
	title.name = "HeartRewardTitle"
	title.text = SaveManager.text("daily_hearts_refilled") if daily_refill else SaveManager.text("endless_heart_earned")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", _font_fredoka_bold)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color.WHITE)
	content.add_child(title)
	var reward_amount: Label = Label.new()
	reward_amount.name = "HeartRewardAmount"
	reward_amount.text = "+%d" % amount
	reward_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_amount.add_theme_font_override("font", _font_fredoka_bold)
	reward_amount.add_theme_font_size_override("font_size", 30)
	reward_amount.add_theme_color_override("font_color", UI_YELLOW)
	content.add_child(reward_amount)

	await get_tree().process_frame
	if not is_instance_valid(overlay) or overlay != _heart_reward_overlay:
		return
	card.pivot_offset = card.size * 0.5
	heart.pivot_offset = heart.size * 0.5
	reward_amount.pivot_offset = reward_amount.size * 0.5
	heart.scale = Vector2(0.42, 0.42)
	var entrance: Tween = overlay.create_tween().set_parallel(true)
	entrance.tween_property(dim, "color:a", 0.13, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	entrance.tween_property(card, "modulate:a", 1.0, 0.14)
	entrance.tween_property(card, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property(heart, "scale", Vector2(1.16, 1.16), 0.30).set_delay(0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entrance.tween_property(reward_amount, "scale", Vector2(1.10, 1.10), 0.24).set_delay(0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await entrance.finished
	await get_tree().create_timer(0.32).timeout
	if not is_instance_valid(overlay) or overlay != _heart_reward_overlay:
		return
	var target_hearts: Array[Control] = _heart_reward_targets(previous_hearts, amount)
	if not target_hearts.is_empty():
		await _fly_reward_hearts_to_row(overlay, card, dim, heart, target_hearts)
	else:
		var hold: Tween = overlay.create_tween()
		hold.tween_interval(0.52)
		hold.tween_property(overlay, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await hold.finished
	_finish_heart_reward_event(overlay)

func _heart_reward_targets(previous_hearts: int, amount: int) -> Array[Control]:
	var result: Array[Control] = []
	if previous_hearts < 0:
		return result
	var row: Control = null
	if _home_layer.visible and not is_instance_valid(_active_view):
		row = _endless_hearts_row
	elif is_instance_valid(_active_view):
		row = _active_view.find_child("AftermathHearts", true, false) as Control
	if row == null:
		return result
	var target_end: int = mini(previous_hearts + amount, SaveManager.ENDLESS_DAILY_HEARTS)
	var heart_index: int = 0
	for child: Node in row.get_children():
		var target: Control = child as Control
		if target == null:
			continue
		if heart_index >= previous_hearts and heart_index < target_end:
			result.append(target)
		heart_index += 1
	return result

func _fly_reward_hearts_to_row(overlay: Control, card: Control, dim: ColorRect, source_heart: TextureRect, targets: Array[Control]) -> void:
	var source_rect: Rect2 = source_heart.get_global_rect()
	var source_center: Vector2 = source_rect.get_center() - overlay.global_position
	source_heart.visible = false
	var dismiss_card: Tween = overlay.create_tween().set_parallel(true)
	dismiss_card.tween_property(card, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	dismiss_card.tween_property(card, "scale", Vector2(0.90, 0.90), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	dismiss_card.tween_property(dim, "color:a", 0.04, 0.24)
	for index: int in range(targets.size()):
		var target: Control = targets[index]
		if not is_instance_valid(target):
			continue
		var target_modulate: Color = target.modulate
		target.modulate = Color(target_modulate.r, target_modulate.g, target_modulate.b, 0.22)
		var flyer: TextureRect = TextureRect.new()
		flyer.name = "FlyingHeart%d" % index
		flyer.texture = HEART_ICON
		flyer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		flyer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flyer.modulate = UI_RED
		flyer.size = Vector2(72, 64)
		flyer.position = source_center - flyer.size * 0.5
		flyer.pivot_offset = flyer.size * 0.5
		overlay.add_child(flyer)
		var target_center: Vector2 = target.get_global_rect().get_center() - overlay.global_position
		var target_position: Vector2 = target_center - flyer.size * 0.5
		var flight: Tween = overlay.create_tween().set_parallel(true)
		flight.tween_property(flyer, "position", target_position, 0.52).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		flight.tween_property(flyer, "scale", Vector2(0.34, 0.34), 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		flight.tween_property(flyer, "rotation_degrees", 12.0 if index % 2 == 0 else -12.0, 0.52).set_trans(Tween.TRANS_SINE)
		await flight.finished
		if is_instance_valid(flyer):
			flyer.queue_free()
		if is_instance_valid(target):
			target.modulate = target_modulate
			target.pivot_offset = target.size * 0.5
			target.scale = Vector2(0.72, 0.72)
			var pulse: Tween = target.create_tween()
			pulse.tween_property(target, "scale", Vector2(1.28, 1.28), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pulse.tween_property(target, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			await pulse.finished
		if index < targets.size() - 1:
			await get_tree().create_timer(0.06).timeout
	var finish: Tween = overlay.create_tween()
	finish.tween_property(dim, "color:a", 0.0, 0.16)
	await finish.finished

func _finish_heart_reward_event(overlay: Control) -> void:
	if _heart_reward_overlay == overlay:
		_heart_reward_overlay = null
	if is_instance_valid(overlay):
		overlay.queue_free()

func _heart_reward_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UI_PRIMARY
	style.border_color = UI_YELLOW
	style.set_border_width_all(3)
	style.set_corner_radius_all(30)
	style.shadow_color = Color(0.04, 0.01, 0.17, 0.36)
	style.shadow_size = 22
	style.shadow_offset = Vector2(0, 10)
	return style

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
		_brand_title.bbcode_enabled = true
		_brand_title.fit_content = true
		_brand_title.scroll_active = false
		_brand_title.add_theme_font_override("normal_font", _font_dm_sans_black)
		_brand_title.add_theme_font_size_override("normal_font_size", 40)
		_brand_title.add_theme_color_override("default_color", UI_PRIMARY)
		_brand_title.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.20))
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
		_card_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_card_title.custom_minimum_size.x = 0
		_card_title.add_theme_font_override("font", _font_fredoka_bold)
		_card_title.add_theme_font_size_override("font_size", 25)
		_card_title.add_theme_color_override("font_color", Color.WHITE)
		_card_title.add_theme_constant_override("outline_size", 0)
	if _card_meta != null:
		_card_meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_card_meta.custom_minimum_size.x = 0
		_card_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_card_meta.max_lines_visible = 2
		_card_meta.add_theme_font_override("font", _font_dm_sans_semibold)
		_card_meta.add_theme_font_size_override("font_size", 13)
		_card_meta.add_theme_color_override("font_color", UI_MUTED_ON_PRIMARY)
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
		_home_hint.add_theme_stylebox_override("normal", _home_hint_style())

func _install_home_streak_calendar() -> void:
	if _card_streak == null or is_instance_valid(_home_streak_calendar):
		return
	var card_content: VBoxContainer = _card_streak.get_parent() as VBoxContainer
	if card_content == null:
		return
	_home_streak_calendar = VBoxContainer.new()
	_home_streak_calendar.name = "HomeStreakCalendar"
	_home_streak_calendar.add_theme_constant_override("separation", 3)
	_home_streak_calendar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_content.add_child(_home_streak_calendar)
	card_content.move_child(_home_streak_calendar, _card_streak.get_index() + 1)

func _refresh_home_streak_calendar(daily_unlocked: bool) -> void:
	if not is_instance_valid(_home_streak_calendar):
		return
	_card_streak.visible = not daily_unlocked
	_home_streak_calendar.visible = daily_unlocked
	for child: Node in _home_streak_calendar.get_children():
		child.free()
	if not daily_unlocked:
		return
	var today_key: String = Time.get_date_string_from_system()
	var monday_key: String = _home_daily_week_monday(today_key)
	var header: HBoxContainer = HBoxContainer.new()
	header.name = "HomeStreakHeader"
	header.add_theme_constant_override("separation", 6)
	_home_streak_calendar.add_child(header)
	var flame: TextureRect = TextureRect.new()
	flame.name = "HomeStreakFlame"
	flame.texture = STREAK_FLAME_ICON
	flame.custom_minimum_size = Vector2(18, 22)
	flame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(flame)
	var streak: Label = Label.new()
	streak.name = "HomeStreakCount"
	streak.text = SaveManager.daily_streak_text(today_key)
	streak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	streak.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	streak.add_theme_font_override("font", _font_fredoka_semibold)
	streak.add_theme_font_size_override("font_size", 14)
	streak.add_theme_color_override("font_color", UI_YELLOW)
	header.add_child(streak)
	_home_streak_calendar.add_child(_build_home_streak_week(_home_date_key_offset(monday_key, -7), today_key, false))
	_home_streak_calendar.add_child(_build_home_streak_week(monday_key, today_key, true))

func _build_home_streak_week(monday_key: String, today_key: String, current_week: bool) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "HomeStreakCurrentWeek" if current_week else "HomeStreakPreviousWeek"
	row.add_theme_constant_override("separation", 2)
	var dates: Array[String] = []
	var states: Array[String] = []
	for day_offset: int in 7:
		var date_key: String = _home_date_key_offset(monday_key, day_offset)
		var result: Dictionary = SaveManager.get_daily_result(date_key)
		var state: String = "empty"
		if bool(result.get("completed", false)):
			state = "correct" if bool(result.get("won", false)) else "wrong"
		dates.append(date_key)
		states.append(state)
	for day_offset: int in 7:
		var date_key: String = dates[day_offset]
		var state: String = states[day_offset]
		var fill: Color = STREAK_GREEN if state == "correct" else UI_RED if state == "wrong" else STREAK_EMPTY
		var joins_left: bool = state == "correct" and day_offset > 0 and states[day_offset - 1] == "correct"
		var joins_right: bool = state == "correct" and day_offset < states.size() - 1 and states[day_offset + 1] == "correct"
		var cell: PanelContainer = PanelContainer.new()
		cell.name = "HomeStreakDay%s" % date_key.replace("-", "")
		cell.set_meta("date_key", date_key)
		cell.set_meta("calendar_state", state)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.custom_minimum_size = Vector2(26, 23)
		cell.add_theme_stylebox_override("panel", _home_streak_day_style(fill, date_key == today_key, joins_left, joins_right))
		var parts: PackedStringArray = date_key.split("-")
		var date_label: Label = Label.new()
		date_label.text = str(int(parts[2])) if parts.size() == 3 else date_key
		date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		date_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		date_label.add_theme_font_override("font", _font_fredoka_bold)
		date_label.add_theme_font_size_override("font_size", 9)
		date_label.add_theme_color_override("font_color", Color.WHITE)
		cell.add_child(date_label)
		row.add_child(cell)
	return row

func _home_streak_day_style(fill: Color, today: bool, joins_left: bool, joins_right: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = UI_YELLOW if today else Color("d6cfef")
	style.set_border_width_all(2 if today else 1)
	style.set_corner_radius_all(7)
	if joins_left:
		style.corner_radius_top_left = 0
		style.corner_radius_bottom_left = 0
		style.expand_margin_left = 1.0
	if joins_right:
		style.corner_radius_top_right = 0
		style.corner_radius_bottom_right = 0
		style.expand_margin_right = 1.0
	return style

func _home_daily_week_monday(day_key: String) -> String:
	var unix_time: int = Time.get_unix_time_from_datetime_string("%sT00:00:00" % day_key)
	var weekday: int = int(Time.get_date_dict_from_unix_time(unix_time).get("weekday", 1))
	return _home_date_key_offset(day_key, -posmod(weekday - 1, 7))

func _home_date_key_offset(day_key: String, offset_days: int) -> String:
	var unix_time: int = Time.get_unix_time_from_datetime_string("%sT00:00:00" % day_key)
	var date_data: Dictionary = Time.get_date_dict_from_unix_time(unix_time + offset_days * 86400)
	return "%04d-%02d-%02d" % [int(date_data.get("year", 1970)), int(date_data.get("month", 1)), int(date_data.get("day", 1))]

func _thicken_label(label: Label, color: Color, outline_size: int) -> void:
	label.add_theme_color_override("font_outline_color", color)
	label.add_theme_constant_override("outline_size", outline_size)

func _thicken_button(button: Button, color: Color, outline_size: int) -> void:
	button.add_theme_color_override("font_outline_color", color)
	button.add_theme_constant_override("outline_size", outline_size)

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
	_connect_game_board(board)
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

func _connect_game_board(board: GameBoard) -> void:
	board.request_menu.connect(show_main_menu)
	board.request_new_game.connect(_start_next_game)
	board.request_tutorial_exit.connect(_on_tutorial_exit)
	board.request_mode_transition.connect(_transition_from_board_to_mode)

func show_achievements() -> void:
	_hide_home()
	_clear_content()
	var overlay := Control.new()
	overlay.name = "AchievementsOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_active_view = overlay

	var background := ColorRect.new()
	background.color = UI_BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(background)
	_add_decor_shape(overlay, Vector2(-54, 72), Vector2(128, 128), UI_YELLOW, 0.22, 64)
	_add_decor_shape(overlay, Vector2(size.x - 52, 154), Vector2(92, 72), UI_MAGENTA, 0.11, 20, 12.0)
	_add_decor_shape(overlay, Vector2(-18, size.y - 118), Vector2(82, 82), UI_TEAL, 0.12, 22, -9.0)

	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override("margin_left", 14)
	safe_margin.add_theme_constant_override("margin_right", 14)
	safe_margin.add_theme_constant_override("margin_top", 18)
	safe_margin.add_theme_constant_override("margin_bottom", 20)
	overlay.add_child(safe_margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 11)
	safe_margin.add_child(page)
	page.add_child(_achievement_header())

	var snapshots: Array[Dictionary] = SaveManager.get_achievement_snapshots()
	page.add_child(_achievement_summary())
	var scroll := ScrollContainer.new()
	scroll.name = "AchievementScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Keep the achievement list mobile-first: dragging anywhere over a card
	# scrolls the content, while the platform scrollbar stays out of the layout.
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.scroll_deadzone = 6
	scroll.gui_input.connect(_on_achievement_scroll_input.bind(scroll))
	page.add_child(scroll)
	var list_margin := MarginContainer.new()
	list_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_margin.add_theme_constant_override("margin_bottom", 10)
	scroll.add_child(list_margin)
	var list := VBoxContainer.new()
	list.name = "AchievementList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	list_margin.add_child(list)
	var delay: float = 0.02
	for snapshot: Dictionary in snapshots:
		var card := _achievement_card(snapshot)
		list.add_child(card)
		card.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(delay)
		tween.tween_property(card, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		delay += 0.025
	SaveManager.mark_achievements_seen()
	_refresh_achievement_badge()

func _achievement_header() -> Control:
	var row := HBoxContainer.new()
	row.name = "AchievementHeader"
	row.add_theme_constant_override("separation", 9)
	var back := Button.new()
	back.text = "<"
	back.custom_minimum_size = Vector2(42, 42)
	back.add_theme_font_override("font", _font_fredoka_bold)
	back.add_theme_font_size_override("font_size", 20)
	back.add_theme_color_override("font_color", UI_PRIMARY)
	back.add_theme_color_override("font_hover_color", UI_PRIMARY)
	back.add_theme_stylebox_override("normal", _achievement_badge_style(UI_YELLOW, UI_PRIMARY, 13))
	back.add_theme_stylebox_override("hover", _achievement_badge_style(Color("ffe33d"), UI_PRIMARY, 13))
	back.add_theme_stylebox_override("pressed", _achievement_badge_style(UI_ACCENT_PRESSED, UI_PRIMARY, 13))
	back.pressed.connect(show_main_menu)
	row.add_child(back)
	var trophy_plate := PanelContainer.new()
	trophy_plate.custom_minimum_size = Vector2(44, 44)
	trophy_plate.add_theme_stylebox_override("panel", _achievement_badge_style(Color.WHITE, UI_BORDER, 14))
	row.add_child(trophy_plate)
	var trophy := TextureRect.new()
	trophy.texture = TROPHY_ICON
	trophy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trophy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	trophy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trophy_plate.add_child(trophy)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", -2)
	row.add_child(title_stack)
	var title := Label.new()
	title.text = SaveManager.text("achievements_title")
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.add_theme_font_override("font", _font_fredoka_bold)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UI_TEXT)
	title_stack.add_child(title)
	var subtitle := Label.new()
	subtitle.text = SaveManager.text("achievements_subtitle")
	subtitle.clip_text = true
	subtitle.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	subtitle.add_theme_font_override("font", FONT_DM_SANS)
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", UI_MUTED_TEXT)
	title_stack.add_child(subtitle)
	return row

func _achievement_summary() -> Control:
	var total: int = SaveManager.get_total_achievement_stars()
	var maximum: int = SaveManager.get_max_achievement_stars()
	var card := PanelContainer.new()
	card.name = "AchievementSummary"
	var style := _round_style(UI_PRIMARY, UI_PRIMARY, 22)
	style.shadow_color = Color(0.12, 0.04, 0.35, 0.22)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	card.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	card.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)
	var top := HBoxContainer.new()
	content.add_child(top)
	var label := Label.new()
	label.text = SaveManager.text("achievement_collection")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.add_theme_font_override("font", _font_dm_sans_spaced)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", UI_YELLOW)
	top.add_child(label)
	var count := Label.new()
	count.text = SaveManager.text("achievement_stars") % [total, maximum]
	count.clip_text = true
	count.add_theme_font_override("font", _font_fredoka_bold)
	count.add_theme_font_size_override("font_size", 15)
	count.add_theme_color_override("font_color", Color.WHITE)
	top.add_child(count)
	var progress := ProgressBar.new()
	progress.name = "CollectionProgress"
	progress.custom_minimum_size.y = 9
	progress.min_value = 0
	progress.max_value = maxi(maximum, 1)
	progress.value = total
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background", _achievement_progress_style(Color("3f2b80"), 5))
	progress.add_theme_stylebox_override("fill", _achievement_progress_style(UI_YELLOW, 5))
	content.add_child(progress)
	return card

func _achievement_card(snapshot: Dictionary) -> Control:
	var accent := _achievement_accent(str(snapshot.get("accent", "purple")))
	var completed := bool(snapshot.get("completed", false))
	var card := PanelContainer.new()
	card.name = "AchievementCard_%s" % str(snapshot.get("id", "unknown"))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _achievement_card_style(accent, completed))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 13)
	margin.add_theme_constant_override("margin_right", 13)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	content.add_child(top)
	var emblem := PanelContainer.new()
	emblem.custom_minimum_size = Vector2(48, 48)
	emblem.add_theme_stylebox_override("panel", _achievement_badge_style(Color(accent, 0.14), accent, 15))
	top.add_child(emblem)
	var icon := TextureRect.new()
	icon.texture = TROPHY_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = Color.WHITE if completed else Color(1, 1, 1, 0.86)
	emblem.add_child(icon)
	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.custom_minimum_size.x = 0
	title_stack.add_theme_constant_override("separation", 1)
	top.add_child(title_stack)
	var title := Label.new()
	title.text = str(snapshot.get("title", "Achievement"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = 0
	title.add_theme_font_override("font", _font_fredoka_bold)
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", UI_TEXT)
	title_stack.add_child(title)
	var description := Label.new()
	description.text = str(snapshot.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 0
	description.add_theme_font_override("font", FONT_DM_SANS)
	description.add_theme_font_size_override("font_size", 11)
	description.add_theme_color_override("font_color", UI_MUTED_TEXT)
	title_stack.add_child(description)
	if bool(snapshot.get("special", false)):
		var special := Label.new()
		special.text = SaveManager.text("achievement_special")
		special.add_theme_font_override("font", _font_dm_sans_spaced)
		special.add_theme_font_size_override("font_size", 8)
		special.add_theme_color_override("font_color", UI_PRIMARY)
		special.add_theme_stylebox_override("normal", _achievement_badge_style(Color("fff3a8"), UI_YELLOW, 9))
		special.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		title_stack.add_child(special)

	var stars_and_progress := HBoxContainer.new()
	stars_and_progress.add_theme_constant_override("separation", 7)
	content.add_child(stars_and_progress)
	var star_row := HBoxContainer.new()
	star_row.add_theme_constant_override("separation", 2)
	stars_and_progress.add_child(star_row)
	var earned_stars := int(snapshot.get("stars", 0))
	var max_stars := int(snapshot.get("max_stars", 1))
	for star_index: int in max_stars:
		var star := TextureRect.new()
		star.custom_minimum_size = Vector2(25, 25)
		star.texture = ACHIEVEMENT_STAR if star_index < earned_stars else ACHIEVEMENT_STAR_LOCKED
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star_row.add_child(star)
	var progress_label := Label.new()
	progress_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label.custom_minimum_size.x = 0
	progress_label.clip_text = true
	progress_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_label.add_theme_font_override("font", _font_dm_sans_semibold)
	progress_label.add_theme_font_size_override("font_size", 11)
	progress_label.add_theme_color_override("font_color", accent if not completed else UI_TEAL)
	var current := int(snapshot.get("progress", 0))
	var target := int(snapshot.get("next_target", 0))
	if completed:
		progress_label.text = SaveManager.text("achievement_complete")
	else:
		progress_label.text = "%s  %d / %d" % [SaveManager.text("achievement_next"), current, target]
	stars_and_progress.add_child(progress_label)
	var thresholds: Array = snapshot.get("thresholds", []) as Array
	var final_target: int = int(thresholds.back()) if not thresholds.is_empty() else 1
	var bar_target: int = final_target if completed else maxi(target, 1)
	var progress_bar := ProgressBar.new()
	progress_bar.custom_minimum_size.y = 7
	progress_bar.min_value = 0
	progress_bar.max_value = maxi(bar_target, 1)
	progress_bar.value = mini(current, bar_target)
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", _achievement_progress_style(Color("e9e4f5"), 4))
	progress_bar.add_theme_stylebox_override("fill", _achievement_progress_style(UI_YELLOW if completed else accent, 4))
	content.add_child(progress_bar)
	_make_achievement_card_scroll_transparent(card)
	return card

func _make_achievement_card_scroll_transparent(root: Control) -> void:
	# Achievement cards contain no actions. Ignoring pointer input throughout
	# their visual tree lets the ScrollContainer receive the complete swipe even
	# when it begins on a title, star, emblem, or progress bar.
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in root.get_children():
		if child is Control:
			_make_achievement_card_scroll_transparent(child as Control)

func _on_achievement_scroll_input(event: InputEvent, scroll: ScrollContainer) -> void:
	# ScrollContainer already handles native touch drags. Add matching mouse
	# dragging for desktop testing without showing or depending on a scrollbar.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_achievement_mouse_dragging = event.pressed
		if event.pressed:
			_achievement_mouse_drag_start_y = event.position.y
			_achievement_mouse_drag_start_scroll = scroll.scroll_vertical
	elif event is InputEventMouseMotion and _achievement_mouse_dragging and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		var drag_distance: float = event.position.y - _achievement_mouse_drag_start_y
		scroll.scroll_vertical = _achievement_mouse_drag_start_scroll - roundi(drag_distance)
		accept_event()

func _start_next_game() -> void:
	if GameState.game_mode == "unlimited" and not SaveManager.can_start_endless():
		show_main_menu()
		return
	if not GameState.start_new_game(GameState.game_mode):
		show_main_menu()

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
	_add_stat(panel, SaveManager.text("player_level"), str(SaveManager.get_player_level()))
	_add_stat(panel, SaveManager.text("total_xp"), str(SaveManager.get_total_xp()))
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
	var privacy_button: Button = Button.new()
	var analytics_status_key: String = "analytics_status_on" if bool(SaveManager.settings.get("analytics_enabled", false)) else "analytics_status_off"
	privacy_button.text = "%s  ·  %s" % [SaveManager.text("privacy_and_data"), SaveManager.text(analytics_status_key)]
	privacy_button.custom_minimum_size = Vector2(0, 38)
	privacy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	privacy_button.add_theme_font_override("font", _font_dm_sans_semibold)
	privacy_button.add_theme_font_size_override("font_size", 13)
	privacy_button.add_theme_color_override("font_color", UI_MUTED_TEXT)
	privacy_button.add_theme_color_override("font_hover_color", UI_TEXT)
	privacy_button.add_theme_color_override("font_pressed_color", UI_TEXT)
	privacy_button.add_theme_stylebox_override("normal", _mode_button_style(Color.TRANSPARENT, UI_BORDER, 1))
	privacy_button.add_theme_stylebox_override("hover", _mode_button_style(UI_SURFACE_TINT, UI_BORDER, 1))
	privacy_button.add_theme_stylebox_override("pressed", _mode_button_style(Color("e4dcf6"), UI_PRIMARY, 1))
	privacy_button.pressed.connect(_show_analytics_consent.bind(true))
	panel.add_child(privacy_button)
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
	elif not bool(SaveManager.settings.get("analytics_consent_answered", false)):
		_show_analytics_consent(false)
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
	_show_analytics_consent(false)

func _show_analytics_consent(from_settings: bool = false) -> void:
	_show_home()
	_clear_content()
	var overlay: Control = Control.new()
	overlay.name = "AnalyticsConsent"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	_active_view = overlay
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.10, 0.04, 0.37, 0.64)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	overlay.add_child(center)
	var card: PanelContainer = PanelContainer.new()
	card.name = "AnalyticsConsentCard"
	card.custom_minimum_size = Vector2(clampf(size.x - 40.0, 300.0, 390.0), 0)
	var card_style: StyleBoxFlat = _round_style(UI_SURFACE, UI_YELLOW, 26)
	card_style.set_border_width_all(2)
	card_style.shadow_color = Color(0.10, 0.04, 0.37, 0.24)
	card_style.shadow_size = 14
	card_style.shadow_offset = Vector2(0, 7)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	margin.add_child(content)
	var eyebrow: Label = Label.new()
	eyebrow.text = SaveManager.text("analytics_consent_eyebrow")
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_override("font", _font_dm_sans_spaced)
	eyebrow.add_theme_font_size_override("font_size", 10)
	eyebrow.add_theme_color_override("font_color", UI_MAGENTA)
	content.add_child(eyebrow)
	var title: Label = Label.new()
	title.text = SaveManager.text("analytics_consent_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", _font_fredoka_bold)
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", UI_TEXT)
	content.add_child(title)
	var benefit: Label = Label.new()
	benefit.text = SaveManager.text("analytics_consent_body")
	benefit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	benefit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	benefit.add_theme_font_override("font", _font_dm_sans_semibold)
	benefit.add_theme_font_size_override("font_size", 15)
	benefit.add_theme_color_override("font_color", UI_TEXT)
	content.add_child(benefit)
	var detail_panel: PanelContainer = PanelContainer.new()
	detail_panel.add_theme_stylebox_override("panel", _mode_button_style(UI_SURFACE_TINT, UI_BORDER, 1))
	content.add_child(detail_panel)
	var detail: Label = Label.new()
	detail.text = SaveManager.text("analytics_consent_detail")
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_override("font", FONT_DM_SANS)
	detail.add_theme_font_size_override("font_size", 12)
	detail.add_theme_color_override("font_color", UI_MUTED_TEXT)
	detail_panel.add_child(detail)
	var accept_button: Button = Button.new()
	accept_button.text = SaveManager.text("analytics_consent_accept")
	accept_button.custom_minimum_size = Vector2(0, 54)
	accept_button.add_theme_font_override("font", _font_fredoka_bold)
	accept_button.add_theme_font_size_override("font_size", 17)
	accept_button.add_theme_color_override("font_color", UI_PRIMARY)
	accept_button.add_theme_color_override("font_hover_color", UI_PRIMARY)
	accept_button.add_theme_color_override("font_pressed_color", UI_PRIMARY)
	accept_button.add_theme_stylebox_override("normal", _play_style(UI_YELLOW, 4))
	accept_button.add_theme_stylebox_override("hover", _play_style(UI_ACCENT_HOVER, 3))
	accept_button.add_theme_stylebox_override("pressed", _play_style(Color("f3ca00"), 1))
	accept_button.pressed.connect(_apply_analytics_choice.bind(true, from_settings))
	content.add_child(accept_button)
	var decline_button: Button = Button.new()
	decline_button.text = SaveManager.text("analytics_consent_decline")
	decline_button.custom_minimum_size = Vector2(0, 40)
	decline_button.add_theme_font_override("font", _font_dm_sans_semibold)
	decline_button.add_theme_font_size_override("font_size", 14)
	decline_button.add_theme_color_override("font_color", UI_MUTED_TEXT)
	decline_button.add_theme_color_override("font_hover_color", UI_TEXT)
	decline_button.add_theme_stylebox_override("normal", _mode_button_style(Color.TRANSPARENT, Color.TRANSPARENT, 0))
	decline_button.add_theme_stylebox_override("hover", _mode_button_style(UI_SURFACE_TINT, Color.TRANSPARENT, 0))
	decline_button.pressed.connect(_apply_analytics_choice.bind(false, from_settings))
	content.add_child(decline_button)
	var policy_button: Button = Button.new()
	policy_button.text = SaveManager.text("privacy_policy")
	policy_button.flat = true
	policy_button.add_theme_font_override("font", FONT_DM_SANS)
	policy_button.add_theme_font_size_override("font_size", 12)
	policy_button.add_theme_color_override("font_color", UI_MUTED_TEXT)
	policy_button.add_theme_color_override("font_hover_color", UI_PRIMARY)
	policy_button.pressed.connect(func() -> void: OS.shell_open(PRIVACY_POLICY_URL))
	content.add_child(policy_button)
	card.modulate.a = 0.0
	card.scale = Vector2(0.96, 0.96)
	card.pivot_offset = card.size * 0.5
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(card, "modulate:a", 1.0, 0.20)
	tween.tween_property(card, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _apply_analytics_choice(enabled: bool, from_settings: bool) -> void:
	SaveManager.settings["analytics_consent_answered"] = true
	SaveManager.settings["analytics_enabled"] = enabled
	SaveManager.save_data()
	var analytics: Node = get_node_or_null("/root/AnalyticsManager")
	if analytics != null and analytics.has_method("set_collection_enabled"):
		analytics.call("set_collection_enabled", enabled)
	if from_settings:
		show_settings()
	elif SaveManager.needs_tutorial_onboarding():
		_start_tutorial()
	else:
		show_main_menu()

func _start_tutorial() -> void:
	if _is_transitioning:
		return
	_clear_content()
	if GameState.start_tutorial():
		_log_analytics("tutorial_started", {"language": PuzzleLoader.get_language()})
		show_game()

func _on_tutorial_exit(completed: bool) -> void:
	_log_analytics("tutorial_completed" if completed else "tutorial_skipped", {
		"language": PuzzleLoader.get_language()
	})
	SaveManager.complete_onboarding()
	if completed:
		_transition_from_board_to_mode(GameState.UNLIMITED_MODE)
		return
	GameState.reset_debug_state()
	show_main_menu()

func _log_analytics(event_name: String, parameters: Dictionary = {}) -> void:
	var analytics: Node = get_node_or_null("/root/AnalyticsManager")
	if analytics != null and analytics.has_method("log_event"):
		analytics.call("log_event", event_name, parameters)

func _transition_from_board_to_mode(mode: String) -> void:
	if _is_transitioning:
		return
	if mode != GameState.DAILY_MODE and mode != GameState.UNLIMITED_MODE:
		return
	if mode == GameState.DAILY_MODE and not SaveManager.is_daily_unlocked():
		show_main_menu()
		return
	if mode == GameState.UNLIMITED_MODE and not SaveManager.can_start_endless():
		show_main_menu()
		return
	_is_transitioning = true
	_play_button.disabled = true
	_unlimited_button.disabled = true
	var cover: ColorRect = ColorRect.new()
	cover.color = UI_BACKGROUND
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.modulate.a = 0.0
	cover.z_index = 100
	add_child(cover)
	var cover_in: Tween = create_tween()
	cover_in.tween_property(cover, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await cover_in.finished
	var previous_view: Control = _active_view
	_active_view = null
	if is_instance_valid(previous_view):
		previous_view.queue_free()
	await get_tree().process_frame
	GameState.reset_debug_state()
	var opened_mode: bool
	if mode == GameState.DAILY_MODE:
		opened_mode = GameState.view_daily_result() if SaveManager.is_daily_challenge_completed() else GameState.start_new_game(GameState.DAILY_MODE)
	else:
		opened_mode = GameState.start_new_game(GameState.UNLIMITED_MODE)
	if not opened_mode:
		cover.queue_free()
		_is_transitioning = false
		_play_button.disabled = false
		_unlimited_button.disabled = false
		show_main_menu()
		return
	var board: GameBoard = GameBoardScene.instantiate()
	_connect_game_board(board)
	board.modulate.a = 0.0
	board.scale = Vector2(1.015, 1.015)
	add_child(board)
	_active_view = board
	await get_tree().process_frame
	board.pivot_offset = board.size * 0.5
	board.refresh()
	var reveal: Tween = create_tween().set_parallel(true)
	reveal.tween_property(board, "modulate:a", 1.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(board, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(cover, "modulate:a", 0.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await reveal.finished
	cover.queue_free()
	_play_button.disabled = false
	_unlimited_button.disabled = false
	_is_transitioning = false

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
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color("fffaf3"))
	gradient.add_point(0.58, Color("fff7f1"))
	gradient.set_color(2, Color("f6efff"))
	var gradient_texture: GradientTexture2D = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 64
	gradient_texture.height = 256
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)
	var base: TextureRect = TextureRect.new()
	base.texture = gradient_texture
	base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base.stretch_mode = TextureRect.STRETCH_SCALE
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(base)

	# The home screen now shares the loading screen's soft alpine depth:
	# three misty ridges, quiet edge decorations, and warm diffused light.
	_add_home_mountain_range(layer, size.y + 8.0, size.y * 0.55, Color("ded1ff"), 0.34, 0.0)
	_add_home_mountain_range(layer, size.y + 12.0, size.y * 0.66, Color("bca6f6"), 0.25, 0.12)
	_add_home_mountain_range(layer, size.y + 18.0, size.y * 0.78, Color("7144d8"), 0.15, -0.08)
	_add_home_pine(layer, Vector2(18, size.y - 48), 64.0, Color("2c1a91"), 0.30)
	_add_home_pine(layer, Vector2(size.x - 24, size.y - 38), 76.0, Color("2c1a91"), 0.28)

	_add_decor_shape(layer, Vector2(-76, -70), Vector2(184, 184), Color("ffd45c"), 0.38, 92)
	_add_decor_shape(layer, Vector2(size.x - 52, 18), Vector2(82, 82), Color("8c66ea"), 0.13, 18, 13.0)
	_add_decor_shape(layer, Vector2(-46, size.y * 0.42), Vector2(88, 88), Color("08b7b3"), 0.13, 44)
	_add_decor_shape(layer, Vector2(size.x - 74, size.y - 56), Vector2(118, 118), Color("ff6257"), 0.12, 59)
	_add_home_dot_cluster(layer, Vector2(size.x - 54, 106), 4, 5, 8.0, Color("7445dd"), 0.27)
	_add_home_dot_cluster(layer, Vector2(8, size.y - 86), 4, 4, 8.0, Color("7445dd"), 0.16)
	_add_home_sparkle(layer, Vector2(42, 176), 13.0, Color("ffd13d"), 0.75)
	_add_home_sparkle(layer, Vector2(size.x - 36, size.y * 0.39), 8.0, Color("08b7b3"), 0.55)
	return layer

func _add_home_mountain_range(
	parent: Control,
	base_y: float,
	peak_y: float,
	color: Color,
	alpha: float,
	phase: float
) -> void:
	var mountain: Polygon2D = Polygon2D.new()
	mountain.polygon = PackedVector2Array([
		Vector2(-28, base_y),
		Vector2(size.x * (0.10 + phase), base_y - 58),
		Vector2(size.x * (0.23 + phase * 0.3), base_y - 26),
		Vector2(size.x * 0.39, peak_y + 52),
		Vector2(size.x * 0.53, peak_y),
		Vector2(size.x * 0.68, peak_y + 78),
		Vector2(size.x * (0.84 - phase * 0.2), base_y - 62),
		Vector2(size.x + 28, base_y - 10),
		Vector2(size.x + 28, base_y + 30),
		Vector2(-28, base_y + 30),
	])
	var fill: Color = color
	fill.a = alpha
	mountain.color = fill
	parent.add_child(mountain)

func _add_home_pine(parent: Control, base: Vector2, height: float, color: Color, alpha: float) -> void:
	var half_width: float = height * 0.24
	var pine: Polygon2D = Polygon2D.new()
	pine.polygon = PackedVector2Array([
		base + Vector2(0, -height),
		base + Vector2(-half_width * 0.58, -height * 0.62),
		base + Vector2(-half_width * 0.27, -height * 0.64),
		base + Vector2(-half_width, -height * 0.28),
		base + Vector2(-half_width * 0.38, -height * 0.34),
		base + Vector2(-half_width * 1.18, -2),
		base + Vector2(half_width * 1.18, -2),
		base + Vector2(half_width * 0.38, -height * 0.34),
		base + Vector2(half_width, -height * 0.28),
		base + Vector2(half_width * 0.27, -height * 0.64),
		base + Vector2(half_width * 0.58, -height * 0.62),
	])
	var fill: Color = color
	fill.a = alpha
	pine.color = fill
	parent.add_child(pine)

func _add_home_mountain_silhouette(parent: Control, base_y: float, color: Color, alpha: float) -> void:
	var mountain: Polygon2D = Polygon2D.new()
	mountain.polygon = PackedVector2Array([
		Vector2(-20, base_y),
		Vector2(size.x * 0.15, base_y - 58),
		Vector2(size.x * 0.30, base_y - 22),
		Vector2(size.x * 0.48, base_y - 92),
		Vector2(size.x * 0.66, base_y - 30),
		Vector2(size.x * 0.82, base_y - 68),
		Vector2(size.x + 20, base_y),
	])
	var fill: Color = color
	fill.a = alpha
	mountain.color = fill
	parent.add_child(mountain)

func _add_home_dot_cluster(parent: Control, origin: Vector2, columns: int, rows: int, spacing: float, color: Color, alpha: float) -> void:
	for row: int in rows:
		for column: int in columns:
			var dot: Panel = Panel.new()
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dot.position = origin + Vector2(column * spacing, row * spacing)
			dot.size = Vector2(3.5, 3.5)
			var style: StyleBoxFlat = StyleBoxFlat.new()
			var fill: Color = color
			fill.a = alpha
			style.bg_color = fill
			style.set_corner_radius_all(2)
			dot.add_theme_stylebox_override("panel", style)
			parent.add_child(dot)

func _add_home_sparkle(parent: Control, center: Vector2, radius: float, color: Color, alpha: float) -> void:
	var sparkle: Polygon2D = Polygon2D.new()
	sparkle.polygon = PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius * 0.24, -radius * 0.24),
		center + Vector2(radius, 0),
		center + Vector2(radius * 0.24, radius * 0.24),
		center + Vector2(0, radius),
		center + Vector2(-radius * 0.24, radius * 0.24),
		center + Vector2(-radius, 0),
		center + Vector2(-radius * 0.24, -radius * 0.24),
	])
	var fill: Color = color
	fill.a = alpha
	sparkle.color = fill
	parent.add_child(sparkle)

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

func _date_pill_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(UI_YELLOW, UI_YELLOW, 20)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style

func _daily_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color("17075d"), Color("4c2da5"), 26)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.20, 0.08, 0.50, 0.26)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 7)
	return style

func _daily_locked_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color("eeebf1"), Color("c9c3d3"), 22)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.06, 0.03, 0.12, 0.10)
	style.shadow_size = 4
	style.shadow_offset = Vector2(4, 5)
	return style

func _infinity_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color("fffaf3"), Color("c5b6ef"), 22)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.10, 0.04, 0.37, 0.15)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 5)
	return style

func _home_hint_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color(1, 0.985, 0.96, 0.78), Color(0.77, 0.70, 0.93, 0.62), 16)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	style.shadow_color = Color(0.10, 0.04, 0.37, 0.08)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
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
	var style: StyleBoxFlat = _round_style(fill, fill, 17)
	style.set_border_width_all(0)
	style.shadow_color = Color(0.10, 0.04, 0.37, 0.24)
	style.shadow_size = maxi(shadow_size, 3)
	style.shadow_offset = Vector2(0, 4)
	return style

func _mode_button_style(fill: Color, border: Color, border_width: int = 1) -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(fill, border, 13)
	style.set_border_width_all(border_width)
	style.shadow_color = Color(0, 0, 0, 0.05)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 1)
	return style

func _settings_icon_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(fill, border, 14)
	style.set_border_width_all(2)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 1.0
	style.shadow_color = Color(0.10, 0.04, 0.37, 0.14)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 4)
	return style

func _achievement_accent(accent_name: String) -> Color:
	match accent_name:
		"yellow":
			return Color("d3a900")
		"teal":
			return UI_TEAL
		"coral":
			return UI_RED
		_:
			return Color("6d45d7")

func _achievement_card_style(accent: Color, completed: bool) -> StyleBoxFlat:
	var fill := Color("fffbea") if completed else Color.WHITE
	var border := UI_YELLOW if completed else Color(accent, 0.58)
	var style := _round_style(fill, border, 20)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.10, 0.04, 0.37, 0.11)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	return style

func _achievement_unlock_style() -> StyleBoxFlat:
	var style := _round_style(UI_PRIMARY, UI_YELLOW, 18)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.10, 0.04, 0.37, 0.28)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 5)
	return style

func _achievement_badge_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := _round_style(fill, border, radius)
	style.set_border_width_all(2)
	style.content_margin_left = 7.0
	style.content_margin_right = 7.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style

func _achievement_progress_style(fill: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color.TRANSPARENT
	style.set_corner_radius_all(radius)
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
