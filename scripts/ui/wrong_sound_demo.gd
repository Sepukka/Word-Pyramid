extends Control

const FONT_FREDOKA: Font = preload("res://assets/fonts/Fredoka.ttf")
const FONT_DM_SANS: Font = preload("res://assets/fonts/DMSans.ttf")
const COMPLETION_SOUNDS: Array[AudioStream] = [
	preload("res://assets/audio/sfx/kenney_interface/game_complete_a.wav"),
	preload("res://assets/audio/sfx/kenney_interface/game_complete_b.wav"),
	preload("res://assets/audio/sfx/kenney_interface/game_complete_c.wav"),
]

const PURPLE: Color = Color("1a0a5e")
const PURPLE_LIGHT: Color = Color("eee9fa")
const YELLOW: Color = Color("ffd600")
const OFF_WHITE: Color = Color("fffdf5")
const BORDER: Color = Color("d6cfef")

var _player: AudioStreamPlayer
var _status: Label
var _buttons: Array[Button] = []

func _ready() -> void:
	_build_screen()

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = PURPLE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	_add_circle(Vector2(-68, 170), 190.0, Color(YELLOW, 0.92))
	_add_circle(Vector2(size.x - 54, size.y - 130), 150.0, Color("cbbdf5"))

	var safe_margin := MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override("margin_left", 20)
	safe_margin.add_theme_constant_override("margin_right", 20)
	safe_margin.add_theme_constant_override("margin_top", 24)
	safe_margin.add_theme_constant_override("margin_bottom", 30)
	add_child(safe_margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	safe_margin.add_child(column)

	var back := Button.new()
	back.text = "‹  Takaisin"
	back.custom_minimum_size = Vector2(116, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.add_theme_font_override("font", FONT_FREDOKA)
	back.add_theme_font_size_override("font_size", 16)
	back.add_theme_color_override("font_color", PURPLE)
	back.add_theme_color_override("font_hover_color", PURPLE)
	back.add_theme_color_override("font_pressed_color", PURPLE)
	back.add_theme_stylebox_override("normal", _button_style(YELLOW, Color("d9b900"), 18, 2))
	back.add_theme_stylebox_override("hover", _button_style(Color("ffe23d"), PURPLE, 18, 2))
	back.add_theme_stylebox_override("pressed", _button_style(Color("e9c400"), PURPLE, 18, 1))
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main.tscn"))
	column.add_child(back)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 470)
	card.add_theme_stylebox_override("panel", _card_style())
	column.add_child(card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 24)
	card_margin.add_theme_constant_override("margin_right", 24)
	card_margin.add_theme_constant_override("margin_top", 28)
	card_margin.add_theme_constant_override("margin_bottom", 28)
	card.add_child(card_margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 15)
	card_margin.add_child(content)

	var badge := Label.new()
	badge.text = "★"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(58, 58)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.add_theme_font_override("font", FONT_FREDOKA)
	badge.add_theme_font_size_override("font_size", 28)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_stylebox_override("normal", _button_style(YELLOW, PURPLE, 18, 2))
	content.add_child(badge)

	var title := Label.new()
	title.text = "Valitse läpäisyääni"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT_FREDOKA)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", PURPLE)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Tämä ääni soi, kun koko pyramidi valmistuu."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_font_override("font", FONT_DM_SANS)
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("7868ac"))
	content.add_child(subtitle)

	for index: int in COMPLETION_SOUNDS.size():
		var button := Button.new()
		button.text = "Vaihtoehto %d" % (index + 1)
		button.custom_minimum_size = Vector2(0, 58)
		button.set_meta(&"skip_ui_click_sound", true)
		button.add_theme_font_override("font", FONT_FREDOKA)
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", PURPLE)
		button.add_theme_color_override("font_hover_color", PURPLE)
		button.add_theme_color_override("font_pressed_color", PURPLE)
		button.add_theme_stylebox_override("normal", _button_style(PURPLE_LIGHT, BORDER, 18, 2))
		button.add_theme_stylebox_override("hover", _button_style(Color("e2d8fa"), PURPLE, 18, 2))
		button.add_theme_stylebox_override("pressed", _button_style(YELLOW, PURPLE, 18, 1))
		button.pressed.connect(_play_option.bind(index))
		content.add_child(button)
		_buttons.append(button)

	_status = Label.new()
	_status.text = "Paina nappia kuunnellaksesi"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_override("font", FONT_DM_SANS)
	_status.add_theme_font_size_override("font_size", 13)
	_status.add_theme_color_override("font_color", Color("7868ac"))
	content.add_child(_status)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(bottom_spacer)

	_player = AudioStreamPlayer.new()
	_player.volume_db = -8.5
	add_child(_player)

func _play_option(index: int) -> void:
	_player.stop()
	_player.stream = COMPLETION_SOUNDS[index]
	_player.play()
	_status.text = "Kuuntelet vaihtoehtoa %d" % (index + 1)
	for button_index: int in _buttons.size():
		var button: Button = _buttons[button_index]
		button.add_theme_stylebox_override(
			"normal",
			_button_style(Color("fff3bd") if button_index == index else PURPLE_LIGHT, YELLOW if button_index == index else BORDER, 18, 2)
		)

func _add_circle(circle_position: Vector2, diameter: float, color: Color) -> void:
	var circle := Panel.new()
	circle.position = circle_position
	circle.size = Vector2.ONE * diameter
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = int(diameter * 0.5)
	style.corner_radius_top_right = int(diameter * 0.5)
	style.corner_radius_bottom_left = int(diameter * 0.5)
	style.corner_radius_bottom_right = int(diameter * 0.5)
	circle.add_theme_stylebox_override("panel", style)
	add_child(circle)

func _card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = OFF_WHITE
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color(0.03, 0.01, 0.16, 0.28)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 6)
	return style

func _button_style(fill: Color, border: Color, radius: int, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.shadow_color = Color(0.03, 0.01, 0.16, 0.18)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, shadow_size)
	return style
