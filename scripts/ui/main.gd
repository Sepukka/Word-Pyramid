extends Control

const GameBoardScene: PackedScene = preload("res://scenes/game_board.tscn")

@onready var _home_background: TextureRect = get_node_or_null("HomeBackground") as TextureRect
@onready var _home_layer: MarginContainer = get_node_or_null("HomeLayer") as MarginContainer
@onready var _logo_spacer: Control = get_node_or_null("HomeLayer/Content/LogoSpacer") as Control
@onready var _bottom_spacer: Control = get_node_or_null("HomeLayer/Content/BottomSpacer") as Control
@onready var _play_button: Button = get_node_or_null("HomeLayer/Content/ModeButtons/PlayButton") as Button
@onready var _unlimited_button: Button = get_node_or_null("HomeLayer/Content/ModeButtons/UnlimitedButton") as Button
@onready var _settings_button: Button = get_node_or_null("HomeLayer/Content/Header/SettingsButton") as Button

var _active_view: Control
var _is_transitioning: bool = false

func _ready() -> void:
	if _home_background == null or _home_layer == null or _play_button == null or _unlimited_button == null or _settings_button == null:
		# The editor can keep an older Main scene in memory after its .tscn file
		# changes externally. Reload once so the editable scene tree is used.
		call_deferred("_reload_editable_home_scene")
		return
	_theme_setup()
	_apply_play_button_style()
	_apply_unlimited_button_style()
	_apply_settings_button_style()
	_play_button.button_down.connect(func() -> void: _animate_play_button(0.97))
	_play_button.button_up.connect(func() -> void: _animate_play_button(1.0))
	_unlimited_button.pressed.connect(_on_unlimited_pressed)
	_settings_button.pressed.connect(show_settings)
	GameState.puzzle_pool_completed.connect(_on_puzzle_pool_completed)
	resized.connect(_layout_home_layout)
	show_main_menu()

func _reload_editable_home_scene() -> void:
	get_tree().reload_current_scene()

func show_main_menu() -> void:
	_clear_content()
	_show_home()
	_layout_home_layout()

func _show_home() -> void:
	_home_background.visible = true
	_home_layer.visible = true
	_home_background.modulate.a = 1.0
	_home_layer.modulate.a = 1.0
	_home_layer.scale = Vector2.ONE

func _hide_home() -> void:
	_home_background.visible = false
	_home_layer.visible = false

func _on_play_pressed() -> void:
	if _is_transitioning:
		return
	if GameState.start_new_game("daily"):
		show_game()

func _on_unlimited_pressed() -> void:
	if _is_transitioning:
		return
	if GameState.start_new_game("unlimited"):
		show_game()

func _on_puzzle_pool_completed(mode: String) -> void:
	if is_instance_valid(_active_view):
		return
	var label: String = "päivittäiset haasteet" if mode == "daily" else "rajattomat haasteet"
	_play_button.disabled = mode == "daily"
	_unlimited_button.disabled = mode == "unlimited"
	_unlimited_button.text = "✓ KAIKKI PELATTU" if mode == "unlimited" else "UNLIMITED"
	_play_button.text = "✓ KAIKKI PELATTU\nPäivittäiset haasteet" if mode == "daily" else "▶  PLAY\nToday's Puzzle"
	# A short, visible confirmation on the home screen without adding a new scene.
	var notice: Label = Label.new()
	notice.name = "PoolCompleteNotice"
	notice.text = "Onneksi olkoon! Olet pelannut kaikki %s." % label
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	# Explicit node overrides ensure this stays dark violet even if an editor
	# theme resource later overrides the custom Theme variation.
	_play_button.add_theme_stylebox_override("normal", _play_style(Color("633fe0"), 12))
	_play_button.add_theme_stylebox_override("hover", _play_style(Color("6e4ae8"), 14))
	_play_button.add_theme_stylebox_override("pressed", _play_style(Color("4f29d4"), 6))
	_play_button.add_theme_color_override("font_color", Color.WHITE)
	_play_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_play_button.add_theme_color_override("font_pressed_color", Color.WHITE)

func _apply_unlimited_button_style() -> void:
	_unlimited_button.add_theme_stylebox_override("normal", _mode_button_style(Color("f5f0ff"), Color("6a45d8")))
	_unlimited_button.add_theme_stylebox_override("hover", _mode_button_style(Color("ebe2ff"), Color("5933c8")))
	_unlimited_button.add_theme_stylebox_override("pressed", _mode_button_style(Color("ded0ff"), Color("4b27af")))
	_unlimited_button.add_theme_color_override("font_color", Color("4c2f9f"))
	_unlimited_button.add_theme_color_override("font_hover_color", Color("3e2587"))
	_unlimited_button.add_theme_color_override("font_pressed_color", Color("352071"))

func _apply_settings_button_style() -> void:
	_settings_button.add_theme_stylebox_override("normal", _mode_button_style(Color(1.0, 1.0, 1.0, 0.92), Color("e5ddf3")))
	_settings_button.add_theme_stylebox_override("hover", _mode_button_style(Color("f5f0ff"), Color("6a45d8")))
	_settings_button.add_theme_color_override("font_color", Color("5a38bc"))
	_settings_button.add_theme_font_size_override("font_size", 22)

func _layout_home_layout() -> void:
	# The supplied background already contains the logo and full pyramid. The
	# container spacer reserves that artwork area before the challenge controls.
	_logo_spacer.custom_minimum_size = Vector2(0, clampf(size.y * 0.72, 610.0, 720.0))
	_bottom_spacer.custom_minimum_size = Vector2(0, clampf(size.y * 0.020, 14.0, 24.0))

func show_game() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_play_button.disabled = true
	_unlimited_button.disabled = true
	var home_tween: Tween = create_tween().set_parallel(true)
	home_tween.tween_property(_home_background, "modulate:a", 0.0, 0.20)
	home_tween.tween_property(_home_layer, "modulate:a", 0.0, 0.20)
	home_tween.tween_property(_home_layer, "scale", Vector2(0.985, 0.985), 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await home_tween.finished
	_hide_home()
	_clear_content()
	var board: GameBoard = GameBoardScene.instantiate()
	board.request_menu.connect(show_main_menu)
	board.request_new_game.connect(_start_next_game)
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
	GameState.start_new_game(GameState.game_mode)

func show_statistics() -> void:
	_hide_home()
	_clear_content()
	var panel: VBoxContainer = _make_panel()
	_add_title(panel, "STATISTICS", "Your Word Pyramid record")
	var wins: int = int(SaveManager.statistics.get("wins", 0))
	var losses: int = int(SaveManager.statistics.get("losses", 0))
	var total: int = wins + losses
	var rate: int = roundi(float(wins) / float(total) * 100.0) if total > 0 else 0
	_add_stat(panel, "Wins", str(wins))
	_add_stat(panel, "Losses", str(losses))
	_add_stat(panel, "Win rate", "%d%%" % rate)
	_add_stat(panel, "Current streak", str(SaveManager.statistics.get("streak", 0)))
	_add_stat(panel, "Best streak", str(SaveManager.statistics.get("best_streak", 0)))
	var back: Button = _make_button("Back")
	back.pressed.connect(show_main_menu)
	panel.add_child(back)

func show_settings() -> void:
	_hide_home()
	_clear_content()
	var panel: VBoxContainer = _make_panel()
	_add_title(panel, "SETTINGS", "Personalize the challenge")
	var language_row: HBoxContainer = HBoxContainer.new()
	var language_label: Label = Label.new()
	language_label.text = "Language"
	language_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_row.add_child(language_label)
	var language: OptionButton = OptionButton.new()
	language.add_item("English", 0)
	language.add_item("Suomi", 1)
	language.select(0 if PuzzleLoader.get_language() == "en" else 1)
	language.item_selected.connect(func(index: int) -> void:
		if PuzzleLoader.set_language("en" if index == 0 else "fi"):
			panel.pivot_offset = panel.size * 0.5
			var language_tween: Tween = create_tween()
			language_tween.tween_property(panel, "scale", Vector2(0.98, 0.98), 0.08)
			language_tween.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	language_row.add_child(language)
	panel.add_child(language_row)
	var attempts_row: HBoxContainer = HBoxContainer.new()
	var attempts_label: Label = Label.new()
	attempts_label.text = "Attempts per puzzle"
	attempts_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attempts_row.add_child(attempts_label)
	var attempts: OptionButton = OptionButton.new()
	for value: int in [3, 4, 5]:
		attempts.add_item(str(value), value)
		if value == int(SaveManager.settings.get("attempts", 4)):
			attempts.select(attempts.item_count - 1)
	attempts.item_selected.connect(func(index: int) -> void:
		SaveManager.settings["attempts"] = attempts.get_item_id(index)
		SaveManager.save_data()
	)
	attempts_row.add_child(attempts)
	panel.add_child(attempts_row)
	var sound: CheckButton = CheckButton.new()
	sound.text = "Sound effects"
	sound.button_pressed = bool(SaveManager.settings.get("sound_enabled", true))
	sound.toggled.connect(func(value: bool) -> void:
		SaveManager.settings["sound_enabled"] = value
		SoundManager.enabled = value
		SaveManager.save_data()
	)
	panel.add_child(sound)
	var note: Label = Label.new()
	note.text = "New attempt settings are applied when a new puzzle starts."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("766c88"))
	panel.add_child(note)
	var back: Button = _make_button("Back")
	back.pressed.connect(show_main_menu)
	panel.add_child(back)

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
	backdrop.color = Color("f2f3f2")
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
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("31264a"))
	panel.add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = subheading
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("766c88"))
	panel.add_child(subtitle)

func _add_stat(panel: VBoxContainer, label_text: String, value_text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value: Label = Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", Color("7046d8"))
	row.add_child(value)
	panel.add_child(row)

func _make_button(text_value: String) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(280, 54)
	button.add_theme_font_size_override("font_size", 18)
	return button

func _round_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _pill_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color(1.0, 1.0, 1.0, 0.88), Color("eee9f5"), 26)
	style.shadow_color = Color(0.16, 0.09, 0.30, 0.10)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	return style

func _preview_block_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color("a784ee"), Color("c5acf7"), 12)
	style.shadow_color = Color(0.23, 0.11, 0.52, 0.34)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	return style

func _ground_shadow_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color(0.25, 0.15, 0.55, 0.12), Color.TRANSPARENT, 100)
	style.shadow_color = Color(0.25, 0.15, 0.55, 0.06)
	style.shadow_size = 10
	return style

func _play_style(fill: Color, shadow_size: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(fill, Color("3a18b0"), 16)
	style.set_border_width(SIDE_BOTTOM, 4)
	style.shadow_color = Color(0.23, 0.09, 0.54, 0.30)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 8)
	return style

func _mode_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(fill, border, 16)
	style.set_border_width_all(2)
	style.shadow_color = Color(0.23, 0.09, 0.54, 0.12)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style

func _theme_setup() -> void:
	var theme: Theme = Theme.new()
	var button_style: StyleBoxFlat = _round_style(Color("e6e8e7"), Color("d8dcda"), 12)
	button_style.content_margin_left = 14.0
	button_style.content_margin_right = 14.0
	button_style.content_margin_top = 8.0
	button_style.content_margin_bottom = 8.0
	var hover_style: StyleBoxFlat = button_style.duplicate()
	hover_style.bg_color = Color("d8dcda")
	var pressed_style: StyleBoxFlat = button_style.duplicate()
	pressed_style.bg_color = Color("bcc4c0")
	theme.set_stylebox("normal", "Button", button_style)
	theme.set_stylebox("hover", "Button", hover_style)
	theme.set_stylebox("pressed", "Button", pressed_style)
	theme.set_color("font_color", "Button", Color("292d2e"))
	theme.set_color("font_hover_color", "Button", Color("292d2e"))
	theme.set_color("font_pressed_color", "Button", Color("292d2e"))
	theme.set_color("font_color", "Label", Color("292d2e"))
	theme.set_font_size("font_size", "Label", 17)
	theme.set_font_size("font_size", "Button", 16)
	theme.set_stylebox("panel", "Panel", button_style)
	theme.set_stylebox("normal", "HomePill", _pill_style())
	theme.set_color("font_color", "HomePill", Color("30334d"))
	theme.set_font_size("font_size", "HomePill", 15)
	theme.set_stylebox("normal", "HomeMenuButton", _round_style(Color.WHITE, Color("e7e1f1"), 23))
	theme.set_stylebox("hover", "HomeMenuButton", _round_style(Color("f4effc"), Color("d5c9e7"), 23))
	theme.set_color("font_color", "HomeMenuButton", Color("7046d8"))
	theme.set_font_size("font_size", "HomeMenuButton", 23)
	theme.set_stylebox("normal", "SideActionButton", _side_action_style(Color.WHITE, 10))
	theme.set_stylebox("hover", "SideActionButton", _side_action_style(Color("f7f2ff"), 10))
	theme.set_color("font_color", "SideActionButton", Color("7046d8"))
	theme.set_font_size("font_size", "SideActionButton", 32)
	theme.set_stylebox("panel", "PreviewTile", _preview_block_style())
	theme.set_stylebox("panel", "GroundShadow", _ground_shadow_style())
	theme.set_stylebox("panel", "BottomCard", _bottom_card_style())
	theme.set_stylebox("normal", "PrimaryPlayButton", _play_style(Color("633fe0"), 12))
	theme.set_stylebox("hover", "PrimaryPlayButton", _play_style(Color("6e4ae8"), 14))
	theme.set_stylebox("pressed", "PrimaryPlayButton", _play_style(Color("4f29d4"), 6))
	theme.set_color("font_color", "PrimaryPlayButton", Color.WHITE)
	theme.set_color("font_hover_color", "PrimaryPlayButton", Color.WHITE)
	theme.set_color("font_pressed_color", "PrimaryPlayButton", Color.WHITE)
	theme.set_font_size("font_size", "PrimaryPlayButton", 25)
	self.theme = theme

func _side_action_style(fill: Color, shadow_size: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(fill, Color("eee9f5"), 38)
	style.shadow_color = Color(0.16, 0.09, 0.30, 0.12)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 4)
	return style

func _bottom_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _round_style(Color(1.0, 1.0, 1.0, 0.90), Color("eee9f5"), 20)
	style.shadow_color = Color(0.16, 0.09, 0.30, 0.12)
	style.shadow_size = 9
	style.shadow_offset = Vector2(0, 4)
	return style
