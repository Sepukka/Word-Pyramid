extends Control

const FONT_FREDOKA: Font = preload("res://assets/fonts/Fredoka.ttf")
const FONT_DM_SANS: Font = preload("res://assets/fonts/DMSans.ttf")

const SOUND_GROUPS: Array[Dictionary] = [
	{
		"tab": "XP",
		"title": "XP:n kasvu",
		"icon": "+XP",
		"subtitle": "Testi simuloi XP-palkin nousevaa animaatiota.",
		"option_notes": ["pehmeä", "napakka", "kirkas"],
		"streams": [
			preload("res://assets/audio/sfx/sound_lab/xp_1.wav"),
			preload("res://assets/audio/sfx/sound_lab/xp_2.wav"),
			preload("res://assets/audio/sfx/sound_lab/xp_3.wav"),
		],
	},
	{
		"tab": "Liike",
		"title": "Sanojen liikkuminen",
		"icon": "↗",
		"subtitle": "Testi simuloi kolmen sanapalikan siirtymistä.",
		"option_notes": ["pehmeä", "kevyt", "selkeä"],
		"streams": [
			preload("res://assets/audio/sfx/sound_lab/move_1.wav"),
			preload("res://assets/audio/sfx/sound_lab/move_2.wav"),
			preload("res://assets/audio/sfx/sound_lab/move_3.wav"),
		],
	},
]

const PURPLE: Color = Color("1a0a5e")
const PURPLE_LIGHT: Color = Color("eee9fa")
const YELLOW: Color = Color("ffd600")
const OFF_WHITE: Color = Color("fffdf5")
const BORDER: Color = Color("d6cfef")
const MUTED: Color = Color("7868ac")

var _player: AudioStreamPlayer
var _badge: Label
var _title: Label
var _subtitle: Label
var _status: Label
var _tab_buttons: Array[Button] = []
var _option_buttons: Array[Button] = []
var _category_index: int = 0
var _play_generation: int = 0
var _restore_music: bool = true

func _ready() -> void:
	_restore_music = SoundManager.music_enabled
	SoundManager.set_music_enabled(false)
	_build_screen()
	_select_category(0)

func _exit_tree() -> void:
	SoundManager.set_music_enabled(_restore_music)

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = PURPLE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_add_circle(Vector2(-72, 150), 180.0, Color(YELLOW, 0.92))
	_add_circle(Vector2(size.x - 60, size.y - 128), 150.0, Color("cbbdf5"))

	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override("margin_left", 18)
	safe_margin.add_theme_constant_override("margin_right", 18)
	safe_margin.add_theme_constant_override("margin_top", 22)
	safe_margin.add_theme_constant_override("margin_bottom", 26)
	add_child(safe_margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	safe_margin.add_child(column)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	column.add_child(header)
	var back := _make_button("‹  Takaisin", 15, 48)
	back.custom_minimum_size.x = 116
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.add_theme_stylebox_override("normal", _button_style(YELLOW, Color("d9b900"), 18, 2))
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main.tscn"))
	header.add_child(back)
	var header_title := Label.new()
	header_title.text = "ÄÄNILABORATORIO"
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_title.add_theme_font_override("font", FONT_DM_SANS)
	header_title.add_theme_font_size_override("font_size", 11)
	header_title.add_theme_color_override("font_color", Color(1, 1, 1, 0.68))
	header.add_child(header_title)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 540)
	card.add_theme_stylebox_override("panel", _card_style())
	column.add_child(card)
	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 20)
	card_margin.add_theme_constant_override("margin_right", 20)
	card_margin.add_theme_constant_override("margin_top", 24)
	card_margin.add_theme_constant_override("margin_bottom", 24)
	card.add_child(card_margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	card_margin.add_child(content)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 5)
	content.add_child(tabs)
	for index: int in SOUND_GROUPS.size():
		var tab := _make_button(str(SOUND_GROUPS[index]["tab"]), 12, 38)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.set_meta(&"skip_ui_click_sound", true)
		tab.pressed.connect(_select_category.bind(index))
		tabs.add_child(tab)
		_tab_buttons.append(tab)

	_badge = Label.new()
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge.custom_minimum_size = Vector2(60, 60)
	_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_badge.add_theme_font_override("font", FONT_FREDOKA)
	_badge.add_theme_font_size_override("font_size", 23)
	_badge.add_theme_color_override("font_color", PURPLE)
	_badge.add_theme_stylebox_override("normal", _button_style(YELLOW, PURPLE, 18, 2))
	content.add_child(_badge)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", FONT_FREDOKA)
	_title.add_theme_font_size_override("font_size", 27)
	_title.add_theme_color_override("font_color", PURPLE)
	content.add_child(_title)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.custom_minimum_size.y = 42
	_subtitle.add_theme_font_override("font", FONT_DM_SANS)
	_subtitle.add_theme_font_size_override("font_size", 13)
	_subtitle.add_theme_color_override("font_color", MUTED)
	content.add_child(_subtitle)

	for index: int in 3:
		var option := _make_button("Vaihtoehto %d" % (index + 1), 16, 58)
		option.set_meta(&"skip_ui_click_sound", true)
		option.add_theme_stylebox_override("normal", _button_style(PURPLE_LIGHT, BORDER, 18, 2))
		option.pressed.connect(_play_option.bind(index))
		content.add_child(option)
		_option_buttons.append(option)

	_status = Label.new()
	_status.text = "Valitse osio ja kuuntele vaihtoehdot"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_override("font", FONT_DM_SANS)
	_status.add_theme_font_size_override("font_size", 12)
	_status.add_theme_color_override("font_color", MUTED)
	content.add_child(_status)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(bottom_spacer)
	_player = AudioStreamPlayer.new()
	_player.volume_db = -8.5
	add_child(_player)

func _select_category(index: int) -> void:
	_play_generation += 1
	if is_instance_valid(_player):
		_player.stop()
	_category_index = index
	var group: Dictionary = SOUND_GROUPS[index]
	_badge.text = str(group["icon"])
	_title.text = str(group["title"])
	_subtitle.text = str(group["subtitle"])
	_status.text = "Kuuntele vaihtoehdot 1–3"
	var notes: Array = group["option_notes"]
	for option_index: int in _option_buttons.size():
		_option_buttons[option_index].text = "Vaihtoehto %d  ·  %s" % [option_index + 1, str(notes[option_index])]
		_option_buttons[option_index].add_theme_stylebox_override("normal", _button_style(PURPLE_LIGHT, BORDER, 18, 2))
	for tab_index: int in _tab_buttons.size():
		var selected: bool = tab_index == index
		_tab_buttons[tab_index].add_theme_stylebox_override("normal", _button_style(YELLOW if selected else PURPLE_LIGHT, PURPLE if selected else BORDER, 14, 1))

func _play_option(option_index: int) -> void:
	_play_generation += 1
	var generation: int = _play_generation
	_player.stop()
	_player.pitch_scale = 1.0
	var streams: Array = SOUND_GROUPS[_category_index]["streams"]
	var stream: AudioStream = streams[option_index] as AudioStream
	_status.text = "%s · vaihtoehto %d" % [str(SOUND_GROUPS[_category_index]["title"]), option_index + 1]
	for button_index: int in _option_buttons.size():
		_option_buttons[button_index].add_theme_stylebox_override(
			"normal",
			_button_style(Color("fff3bd") if button_index == option_index else PURPLE_LIGHT, YELLOW if button_index == option_index else BORDER, 18, 2)
		)
	if _category_index == 0:
		await _play_xp_sequence(stream, generation)
	elif _category_index == 1:
		await _play_move_sequence(stream, generation)
	else:
		_player.stream = stream
		_player.play()

func _play_xp_sequence(stream: AudioStream, generation: int) -> void:
	for step: int in 7:
		if generation != _play_generation:
			return
		_player.stream = stream
		_player.pitch_scale = 0.88 + float(step) * 0.055
		_player.play()
		await get_tree().create_timer(0.105).timeout
	_player.pitch_scale = 1.0

func _play_move_sequence(stream: AudioStream, generation: int) -> void:
	for _step: int in 3:
		if generation != _play_generation:
			return
		_player.stream = stream
		_player.pitch_scale = 1.0
		_player.play()
		await get_tree().create_timer(0.14).timeout

func _make_button(label_text: String, font_size: int, height: float) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size.y = height
	button.add_theme_font_override("font", FONT_FREDOKA)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", PURPLE)
	button.add_theme_color_override("font_hover_color", PURPLE)
	button.add_theme_color_override("font_pressed_color", PURPLE)
	button.add_theme_stylebox_override("normal", _button_style(PURPLE_LIGHT, BORDER, 16, 1))
	button.add_theme_stylebox_override("hover", _button_style(Color("e2d8fa"), PURPLE, 16, 2))
	button.add_theme_stylebox_override("pressed", _button_style(YELLOW, PURPLE, 16, 1))
	return button

func _add_circle(circle_position: Vector2, diameter: float, color: Color) -> void:
	var circle := Panel.new()
	circle.position = circle_position
	circle.size = Vector2.ONE * diameter
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(diameter * 0.5))
	circle.add_theme_stylebox_override("panel", style)
	add_child(circle)

func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = OFF_WHITE
	style.set_corner_radius_all(28)
	style.shadow_color = Color(0.03, 0.01, 0.16, 0.28)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	return style

func _button_style(fill: Color, border: Color, radius: int, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.shadow_color = Color(0.03, 0.01, 0.16, 0.16)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, shadow_size)
	return style
