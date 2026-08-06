class_name InstructionsStyleDemo
extends Control

signal dismiss_requested
const FONT_FREDOKA: Font = preload("res://assets/fonts/Fredoka.ttf")
const FONT_DM_SANS: Font = preload("res://assets/fonts/DMSans.ttf")
const ICON_LIGHTBULB: Texture2D = preload("res://assets/icons/lightbulb.svg")
const PALETTE = preload("res://scripts/ui/ui_palette.gd")

const PURPLE: Color = PALETTE.PRIMARY
const PURPLE_LIGHT := Color("382181")
const PURPLE_SOFT: Color = PALETTE.SURFACE_TINT
const CREAM: Color = PALETTE.BACKGROUND
const WHITE: Color = PALETTE.SURFACE
const YELLOW: Color = PALETTE.ACCENT
const CORAL: Color = PALETTE.ERROR
const TEAL: Color = PALETTE.SUCCESS
const LAVENDER := Color("cdb9ff")
const MUTED: Color = PALETTE.MUTED_TEXT
const DARK_MUTED := Color("5d5286")

var _fredoka_semibold: FontVariation
var _fredoka_bold: FontVariation
var _dm_sans_semibold: FontVariation
var _closing: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fredoka_semibold = _font_variation(FONT_FREDOKA, 600, 0.16)
	_fredoka_bold = _font_variation(FONT_FREDOKA, 700, 0.35)
	_dm_sans_semibold = _font_variation(FONT_DM_SANS, 600, 0.08)
	var instructions_page := _build_three_step_variant(2)
	add_child(instructions_page)
	instructions_page.modulate.a = 0.0
	instructions_page.position.y = 8.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(instructions_page, "modulate:a", 1.0, 0.18)
	tween.tween_property(instructions_page, "position:y", 0.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		_close()

func _build_three_step_variant(style_index: int) -> Control:
	var root := _full_root(PURPLE)
	if style_index == 0:
		_add_circle(root, Vector2(304, -60), 148.0, YELLOW, 0.82)
		_add_tilted_shape(root, Vector2(-48, 548), Vector2(102, 118), Color("a9e8df"), -14.0, 0.28)
	elif style_index == 1:
		_add_circle(root, Vector2(-56, 96), 116.0, YELLOW, 0.50)
		_add_tilted_shape(root, Vector2(330, 72), Vector2(92, 124), Color("efb9dd"), 14.0, 0.54)
	else:
		_add_circle(root, Vector2(310, 498), 132.0, YELLOW, 0.34)
		_add_tilted_shape(root, Vector2(-42, 84), Vector2(90, 116), LAVENDER, -12.0, 0.42)
	var page_margin := _full_margin(14, 14, 13, 14)
	root.add_child(page_margin)
	var page := _vbox(8)
	page.name = "VariantPage"
	page_margin.add_child(page)
	var top_navigation := HBoxContainer.new()
	top_navigation.name = "TopNavigation"
	page.add_child(top_navigation)
	top_navigation.add_child(_top_back_button())
	var navigation_spacer := Control.new()
	navigation_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_navigation.add_child(navigation_spacer)
	page.add_child(_screen_heading(_t("instructions_title"), _t("instructions_subtitle"), WHITE, Color(1, 1, 1, 0.66)))

	var lesson_stack := _vbox(7)
	lesson_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(lesson_stack)
	if style_index == 1:
		var guide := _panel(WHITE, Color(1, 1, 1, 0.16), 24, 0, true)
		guide.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lesson_stack.add_child(guide)
		var guide_margin := _margin(10, 10, 9, 9)
		guide.add_child(guide_margin)
		var guide_steps := _vbox(5)
		guide_margin.add_child(guide_steps)
		guide_steps.add_child(_connected_step("1", _t("instructions_find_title"), _t("instructions_find_body"), TEAL, _word_pool_example(true)))
		guide_steps.add_child(_step_divider())
		guide_steps.add_child(_connected_step("2", _t("instructions_check_title"), _t("instructions_check_body"), YELLOW, _check_and_lock_example()))
		guide_steps.add_child(_step_divider())
		guide_steps.add_child(_connected_step("3", _t("instructions_top_title"), _t("instructions_top_body"), CORAL, _any_order_example()))
	else:
		lesson_stack.add_child(_variant_step_card(style_index, "1", _t("instructions_find_title"), _t("instructions_find_body"), TEAL, _word_pool_example(true)))
		lesson_stack.add_child(_variant_step_card(style_index, "2", _t("instructions_check_title"), _t("instructions_check_body"), YELLOW, _check_and_lock_example()))
		lesson_stack.add_child(_variant_step_card(style_index, "3", _t("instructions_top_title"), _t("instructions_top_body"), CORAL, _any_order_example()))
	lesson_stack.add_child(_prominent_hint_card(style_index))
	var mistake := _label("!  %s" % _t("instructions_mistake_body"), 11, Color("ffb5a9"), _dm_sans_semibold)
	mistake.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lesson_stack.add_child(mistake)
	page.add_child(_back_button())
	return root

func _word_pool_example(compact: bool = false, dark_background: bool = true) -> VBoxContainer:
	var stack := _vbox(4)
	stack.name = "WordPoolExample"
	if not compact:
		var pool_color := Color(1, 1, 1, 0.58) if dark_background else MUTED
		var pool_label := _label(_t("instructions_pool"), 10, pool_color, _dm_sans_semibold)
		pool_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stack.add_child(pool_label)
	var selected_words: Array[String] = [
		_t("instructions_word_apple"),
		_t("instructions_word_pear"),
		_t("instructions_word_banana"),
	]
	var selected_row := HBoxContainer.new()
	selected_row.alignment = BoxContainer.ALIGNMENT_CENTER
	selected_row.add_theme_constant_override("separation", 4)
	stack.add_child(selected_row)
	for word: String in selected_words:
		selected_row.add_child(_example_word_tile(word, true, compact))
	var other_row := HBoxContainer.new()
	other_row.alignment = BoxContainer.ALIGNMENT_CENTER
	other_row.add_theme_constant_override("separation", 4)
	stack.add_child(other_row)
	other_row.add_child(_example_word_tile(_t("instructions_word_hammer"), false, compact))
	other_row.add_child(_example_word_tile(_t("instructions_word_train"), false, compact))
	return stack

func _example_word_tile(word: String, selected: bool, compact: bool) -> PanelContainer:
	var fill := LAVENDER if selected else WHITE
	var border := YELLOW if selected else Color("d8d0e9")
	var tile := _panel(fill, border, 10, 2 if selected else 1)
	tile.custom_minimum_size = Vector2(74 if compact else 86, 30 if compact else 34)
	var label := _label(word, 10 if compact else 11, PURPLE, _fredoka_semibold)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tile.add_child(label)
	return tile

func _mini_check_button() -> PanelContainer:
	var button := _panel(YELLOW, YELLOW, 12, 0, true)
	button.custom_minimum_size = Vector2(160, 34)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var label := _label(SaveManager.text("check"), 13, PURPLE, _fredoka_semibold)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(label)
	return button

func _locked_group_example() -> PanelContainer:
	var band := _panel(TEAL, TEAL, 12, 0)
	band.custom_minimum_size.y = 37.0
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 9)
	band.add_child(row)
	for key: String in ["instructions_word_apple", "instructions_word_pear", "instructions_word_banana"]:
		var word := _label(_t(key), 11, PURPLE, _fredoka_semibold)
		word.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(word)
	return band

func _clear_step_card(number: String, title: String, body: String, accent: Color, example: Control) -> PanelContainer:
	var card := _panel(WHITE, Color(1, 1, 1, 0.16), 20, 0, true)
	card.name = "StepCard_%s" % number
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := _margin(11, 11, 9, 9)
	card.add_child(margin)
	var content := _vbox(5)
	margin.add_child(content)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 9)
	content.add_child(heading)
	heading.add_child(_number_badge(number, accent, PURPLE))
	var copy := _vbox(1)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(copy)
	copy.add_child(_label(title, 17, PURPLE, _fredoka_semibold))
	var description := _label(body, 12, DARK_MUTED, FONT_DM_SANS)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	example.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(example)
	return card

func _variant_step_card(style_index: int, number: String, title: String, body: String, accent: Color, example: Control) -> PanelContainer:
	if style_index == 0:
		return _clear_step_card(number, title, body, accent, example)
	var fill := accent.lightened(0.72)
	var card := _panel(fill, accent, 20, 2, true)
	card.name = "StepCard_%s" % number
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := _margin(11, 11, 9, 9)
	card.add_child(margin)
	var content := _vbox(5)
	margin.add_child(content)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 9)
	content.add_child(heading)
	heading.add_child(_number_badge(number, accent, PURPLE))
	var copy := _vbox(1)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(copy)
	copy.add_child(_label(title, 17, PURPLE, _fredoka_semibold))
	var description := _label(body, 12, DARK_MUTED, FONT_DM_SANS)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	example.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(example)
	return card

func _connected_step(number: String, title: String, body: String, accent: Color, example: Control) -> VBoxContainer:
	var section := _vbox(4)
	section.name = "StepCard_%s" % number
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 9)
	section.add_child(heading)
	heading.add_child(_number_badge(number, accent, PURPLE))
	var copy := _vbox(0)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(copy)
	copy.add_child(_label(title, 16, PURPLE, _fredoka_semibold))
	var description := _label(body, 11, DARK_MUTED, FONT_DM_SANS)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	example.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	section.add_child(example)
	return section

func _step_divider() -> HSeparator:
	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", Color("e7e0f3"))
	return divider

func _prominent_hint_card(style_index: int) -> PanelContainer:
	var fill := YELLOW
	var border := YELLOW
	var title_color := PURPLE
	var body_color := PURPLE
	if style_index == 1:
		fill = PURPLE_LIGHT
		border = YELLOW
		title_color = YELLOW
		body_color = WHITE
	elif style_index == 2:
		fill = Color("efe5ff")
		border = YELLOW
	var card := _panel(fill, border, 18, 2, true)
	card.name = "HintCallout"
	card.custom_minimum_size.y = 104.0
	var margin := _margin(12, 12, 9, 9)
	card.add_child(margin)
	var stack := _vbox(7)
	margin.add_child(stack)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 11)
	stack.add_child(row)
	var badge := _number_badge("H", YELLOW if style_index == 1 else PURPLE, PURPLE if style_index == 1 else YELLOW)
	badge.custom_minimum_size = Vector2(42, 42)
	row.add_child(badge)
	var copy := _vbox(0)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label(SaveManager.text("hint").to_upper(), 17, title_color, _fredoka_bold))
	var description := _label(_t("instructions_hint_note"), 11, body_color, _dm_sans_semibold)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	var hint_button := Button.new()
	hint_button.name = "HintAction"
	var hint_limit: int = int(GameState.call("_get_hint_limit"))
	var hints_remaining: int = maxi(hint_limit - GameState.hints_used, 0)
	hint_button.text = SaveManager.text("hint_count") % hints_remaining
	hint_button.icon = ICON_LIGHTBULB
	hint_button.expand_icon = true
	hint_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint_button.add_theme_constant_override("icon_max_width", 20)
	hint_button.custom_minimum_size.y = 38.0
	hint_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_button.focus_mode = Control.FOCUS_NONE
	hint_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_button.add_theme_font_override("font", _fredoka_semibold)
	hint_button.add_theme_font_size_override("font_size", 14)
	hint_button.add_theme_color_override("font_color", PURPLE)
	hint_button.add_theme_color_override("font_hover_color", PURPLE)
	hint_button.add_theme_color_override("font_pressed_color", PURPLE)
	hint_button.add_theme_stylebox_override("normal", _style(YELLOW, YELLOW, 13, 0, true))
	hint_button.add_theme_stylebox_override("hover", _style(Color("ffe23d"), YELLOW, 13, 0, true))
	hint_button.add_theme_stylebox_override("pressed", _style(Color("e9c400"), Color("e9c400"), 13, 0))
	stack.add_child(hint_button)
	return card

func _check_and_lock_example() -> HBoxContainer:
	var flow := HBoxContainer.new()
	flow.alignment = BoxContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("separation", 8)
	var check := _panel(YELLOW, YELLOW, 10, 0)
	check.custom_minimum_size = Vector2(82, 30)
	var check_label := _label(SaveManager.text("check"), 11, PURPLE, _fredoka_semibold)
	check_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	check.add_child(check_label)
	flow.add_child(check)
	var arrow := _label(">", 18, MUTED, _fredoka_bold)
	flow.add_child(arrow)
	var locked := _panel(TEAL, TEAL, 10, 0)
	locked.custom_minimum_size = Vector2(126, 30)
	var locked_label := _label(_t("instructions_correct_row"), 9, PURPLE, _dm_sans_semibold)
	locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	locked.add_child(locked_label)
	flow.add_child(locked)
	return flow

func _tool_card(mark: String, body: String, accent: Color) -> PanelContainer:
	var card := _panel(PURPLE_SOFT, PURPLE_SOFT, 16, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := _margin(8, 8, 8, 8)
	card.add_child(margin)
	var stack := _vbox(3)
	margin.add_child(stack)
	var mark_label := _label(mark, 13, accent.darkened(0.22), _fredoka_bold)
	mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(mark_label)
	var description := _label(body, 10, DARK_MUTED, FONT_DM_SANS)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(description)
	return card

func _any_order_example() -> VBoxContainer:
	var stack := _vbox(3)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	var rows := HBoxContainer.new()
	rows.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_theme_constant_override("separation", 5)
	stack.add_child(rows)
	var colors: Array[Color] = [LAVENDER, CORAL, TEAL, Color("7edbcf"), YELLOW]
	for row_size: int in [1, 2, 3, 4, 5]:
		rows.add_child(_number_badge(str(row_size), colors[row_size - 1], PURPLE))
	var order := _label(_t("instructions_choose_top"), 10, MUTED, _dm_sans_semibold)
	order.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(order)
	return stack

func _labeled_pyramid() -> VBoxContainer:
	var component := _vbox(5)
	component.name = "LabeledPyramid"
	component.alignment = BoxContainer.ALIGNMENT_CENTER
	var colors: Array[Color] = [LAVENDER, CORAL, TEAL, Color("7edbcf"), YELLOW]
	var labels: Array[String] = [
		_t("instructions_top_tile"),
		"2",
		"3",
		"4",
		"5",
	]
	for row_size: int in [1, 2, 3, 4, 5]:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4)
		component.add_child(row)
		for tile_index: int in row_size:
			var tile := _panel(colors[row_size - 1], colors[row_size - 1], 8, 0)
			tile.custom_minimum_size = Vector2(48, 25)
			row.add_child(tile)
			var text_value := labels[row_size - 1] if row_size == 1 else str(row_size)
			var tile_label := _label(text_value, 8 if row_size == 1 else 11, PURPLE, _fredoka_semibold)
			tile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			tile.add_child(tile_label)
	var completion := _label("%s  >  %s" % [_t("instructions_completed_rows"), _t("instructions_choose_top")], 9, MUTED, _dm_sans_semibold)
	completion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	component.add_child(completion)
	return component

func _instruction_pyramid() -> VBoxContainer:
	var pyramid := _vbox(4)
	pyramid.alignment = BoxContainer.ALIGNMENT_CENTER
	var colors: Array[Color] = [LAVENDER, CORAL, TEAL, Color("7edbcf"), YELLOW]
	for row_size: int in [1, 2, 3, 4, 5]:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4)
		pyramid.add_child(row)
		for tile_index: int in row_size:
			var tile := _panel(colors[row_size - 1], colors[row_size - 1], 8, 0)
			tile.custom_minimum_size = Vector2(38, 22)
			row.add_child(tile)
	return pyramid

func _journey_row(number: String, title: String, body: String, accent: Color) -> PanelContainer:
	var card := _panel(PURPLE_LIGHT, Color("523a9c"), 17, 1)
	var margin := _margin(10, 10, 8, 8)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)
	var badge := _number_badge(number, accent, PURPLE)
	row.add_child(badge)
	var copy := _vbox(1)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label(title, 15, WHITE, _fredoka_semibold))
	var description := _label(body, 10, Color(1, 1, 1, 0.66), FONT_DM_SANS)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	return card

func _lesson_card(number: String, title: String, body: String, accent: Color, example: Control) -> PanelContainer:
	var card := _panel(WHITE, Color(1, 1, 1, 0.12), 20, 0, true)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := _margin(11, 11, 9, 9)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)
	row.add_child(_number_badge(number, accent, PURPLE))
	var copy := _vbox(1)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label(title, 15, PURPLE, _fredoka_semibold))
	var description := _label(body, 10, DARK_MUTED, FONT_DM_SANS)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	example.custom_minimum_size.x = 72.0
	row.add_child(example)
	return card

func _compact_rule(number: String, title: String, body: String, accent: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(_number_badge(number, accent, PURPLE))
	var copy := _vbox(1)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(copy)
	copy.add_child(_label(title, 16, PURPLE, _fredoka_semibold))
	var description := _label(body, 11, DARK_MUTED, FONT_DM_SANS)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(description)
	return row

func _reminder_card(mark: String, body: String, accent: Color) -> PanelContainer:
	var card := _panel(PURPLE_SOFT, PURPLE_SOFT, 17, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := _margin(8, 8, 9, 9)
	card.add_child(margin)
	var stack := _vbox(4)
	margin.add_child(stack)
	var mark_label := _label(mark, 16, accent.darkened(0.18), _fredoka_bold)
	mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(mark_label)
	var description := _label(body, 10, DARK_MUTED, FONT_DM_SANS)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(description)
	return card

func _selection_example() -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	for index: int in 3:
		var fill := LAVENDER if index < 2 else PURPLE_SOFT
		var tile := _panel(fill, fill, 7, 0)
		tile.custom_minimum_size = Vector2(20, 28)
		row.add_child(tile)
	return row

func _check_example() -> Control:
	var button := _panel(YELLOW, YELLOW, 10, 0)
	button.custom_minimum_size = Vector2(70, 32)
	var label := _label(SaveManager.text("check"), 10, PURPLE, _fredoka_semibold)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(label)
	return button

func _hint_example() -> Control:
	var tile := _panel(LAVENDER, Color("a78ee6"), 10, 1)
	tile.custom_minimum_size = Vector2(48, 34)
	var label := _label(SaveManager.text("hint"), 10, PURPLE, _fredoka_semibold)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tile.add_child(label)
	return tile

func _top_example() -> Control:
	var stack := _vbox(3)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	for row_size: int in [1, 2]:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 3)
		stack.add_child(row)
		for index: int in row_size:
			var fill := CORAL if row_size == 1 else TEAL
			var tile := _panel(fill, fill, 6, 0)
			tile.custom_minimum_size = Vector2(21, 15)
			row.add_child(tile)
	return stack

func _screen_heading(title: String, subtitle: String, title_color: Color, subtitle_color: Color) -> VBoxContainer:
	var heading := _vbox(1)
	var title_label := _label(title, 29, title_color, _fredoka_bold)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_child(title_label)
	var subtitle_label := _label(subtitle, 12, subtitle_color, FONT_DM_SANS)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(subtitle_label)
	return heading

func _back_button() -> Button:
	var button := Button.new()
	button.name = "BackToGame"
	button.text = "←  %s" % _t("instructions_back_game")
	button.custom_minimum_size.y = 50.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", _fredoka_semibold)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", PURPLE)
	button.add_theme_color_override("font_hover_color", PURPLE)
	button.add_theme_color_override("font_pressed_color", PURPLE)
	button.add_theme_stylebox_override("normal", _style(YELLOW, YELLOW, 18, 0, true))
	button.add_theme_stylebox_override("hover", _style(Color("ffe23d"), YELLOW, 18, 0, true))
	button.add_theme_stylebox_override("pressed", _style(Color("e9c400"), Color("e9c400"), 18, 0))
	button.pressed.connect(_close)
	return button

func _top_back_button() -> Button:
	var button := Button.new()
	button.name = "TopBackToGame"
	button.text = "←  %s" % SaveManager.text("back")
	button.custom_minimum_size = Vector2(106, 40)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", _fredoka_semibold)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", PURPLE)
	button.add_theme_color_override("font_hover_color", PURPLE)
	button.add_theme_color_override("font_pressed_color", PURPLE)
	button.add_theme_stylebox_override("normal", _style(YELLOW, YELLOW, 15, 0, true))
	button.add_theme_stylebox_override("hover", _style(Color("ffe23d"), YELLOW, 15, 0, true))
	button.add_theme_stylebox_override("pressed", _style(Color("e9c400"), Color("e9c400"), 15, 0))
	button.pressed.connect(_close)
	return button

func _close() -> void:
	if _closing:
		return
	_closing = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	tween.tween_callback(func() -> void: dismiss_requested.emit())

func _number_badge(text_value: String, fill: Color, text_color: Color) -> PanelContainer:
	var badge := _panel(fill, fill, 15, 0)
	badge.custom_minimum_size = Vector2(34, 34)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := _label(text_value, 13, text_color, _fredoka_bold)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(label)
	return badge

func _concept_note(text_value: String, color: Color = MUTED) -> Label:
	var note := _label(text_value, 10, color, _dm_sans_semibold)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return note

func _style_tab(button: Button, active: bool) -> void:
	var fill := PURPLE if active else PURPLE_SOFT
	var text_color := WHITE if active else DARK_MUTED
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_stylebox_override("normal", _style(fill, fill, 15, 0))
	button.add_theme_stylebox_override("hover", _style(fill.lightened(0.06), fill, 15, 0))
	button.add_theme_stylebox_override("pressed", _style(fill.darkened(0.06), fill, 15, 0))

func _chip(text_value: String, text_color: Color, fill: Color) -> PanelContainer:
	var chip := _panel(fill, fill, 14, 0)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var margin := _margin(10, 10, 5, 5)
	chip.add_child(margin)
	margin.add_child(_label(text_value, 10, text_color, _dm_sans_semibold))
	return chip

func _panel(fill: Color, border: Color, radius: int, border_width: int, shadow: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(fill, border, radius, border_width, shadow))
	return panel

func _style(fill: Color, border: Color, radius: int, border_width: int, shadow: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	if shadow:
		style.shadow_color = Color(0.035, 0.012, 0.16, 0.20)
		style.shadow_size = 7
		style.shadow_offset = Vector2(0, 4)
	return style

func _label(text_value: String, font_size: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _vbox(separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box

func _margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin

func _full_margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin := _margin(left, right, top, bottom)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return margin

func _full_root(color: Color) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	return root

func _add_circle(parent: Control, position_value: Vector2, diameter: float, color: Color, alpha: float) -> void:
	var circle := Panel.new()
	circle.position = position_value
	circle.size = Vector2.ONE * diameter
	circle.modulate.a = alpha
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_theme_stylebox_override("panel", _style(color, color, int(diameter * 0.5), 0))
	parent.add_child(circle)

func _add_tilted_shape(parent: Control, position_value: Vector2, size_value: Vector2, color: Color, rotation_value: float, alpha: float) -> void:
	var shape := Panel.new()
	shape.position = position_value
	shape.size = size_value
	shape.rotation_degrees = rotation_value
	shape.modulate.a = alpha
	shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shape.add_theme_stylebox_override("panel", _style(color, color, 26, 0))
	parent.add_child(shape)

func _font_variation(base_font: Font, weight: int, embolden: float) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = base_font
	font.variation_opentype = {"wght": weight}
	font.variation_embolden = embolden
	return font

func _t(key: String) -> String:
	return SaveManager.text(key)
