class_name InstructionsStyleDemo
extends Control

signal dismiss_requested

const FONT_FREDOKA: Font = preload("res://assets/fonts/Fredoka.ttf")
const FONT_DM_SANS: Font = preload("res://assets/fonts/DMSans.ttf")

const PURPLE := Color("1a0a5e")
const PURPLE_LIGHT := Color("382181")
const PURPLE_SOFT := Color("eee9fa")
const CREAM := Color("fffaf0")
const WHITE := Color("ffffff")
const YELLOW := Color("ffd600")
const CORAL := Color("ff6f61")
const TEAL := Color("39c6b4")
const LAVENDER := Color("cdb9ff")
const MUTED := Color("8b80b6")
const DARK_MUTED := Color("5d5286")

var _fredoka_semibold: FontVariation
var _fredoka_bold: FontVariation
var _dm_sans_semibold: FontVariation
var _variant_host: Control
var _variant_buttons: Array[Button] = []
var _variant_names: Array[String] = []
var _current_variant: int = 0
var _closing: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fredoka_semibold = _font_variation(FONT_FREDOKA, 600, 0.16)
	_fredoka_bold = _font_variation(FONT_FREDOKA, 700, 0.35)
	_dm_sans_semibold = _font_variation(FONT_DM_SANS, 600, 0.08)
	_variant_names = [_t("instructions_variant_a"), _t("instructions_variant_b"), _t("instructions_variant_c")]
	_build_comparison_screen()
	_show_variant(0)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		_close()
	elif event.keycode == KEY_LEFT:
		_show_variant(posmod(_current_variant - 1, _variant_names.size()))
	elif event.keycode == KEY_RIGHT:
		_show_variant((_current_variant + 1) % _variant_names.size())

func _build_comparison_screen() -> void:
	var background := ColorRect.new()
	background.color = CREAM
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_variant_host = Control.new()
	_variant_host.name = "VariantHost"
	_variant_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_variant_host.offset_top = 58.0
	add_child(_variant_host)

	var comparison_bar := PanelContainer.new()
	comparison_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	comparison_bar.offset_bottom = 58.0
	comparison_bar.add_theme_stylebox_override("panel", _style(CREAM, CREAM, 0, 0))
	add_child(comparison_bar)
	var bar_margin := _margin(8, 8, 8, 8)
	comparison_bar.add_child(bar_margin)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	bar_margin.add_child(tabs)
	for index: int in _variant_names.size():
		var tab := Button.new()
		tab.text = _variant_names[index]
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size.y = 42.0
		tab.focus_mode = Control.FOCUS_NONE
		tab.add_theme_font_override("font", _dm_sans_semibold)
		tab.add_theme_font_size_override("font_size", 11)
		tab.pressed.connect(_show_variant.bind(index))
		tabs.add_child(tab)
		_variant_buttons.append(tab)

func _show_variant(index: int) -> void:
	_current_variant = clampi(index, 0, _variant_names.size() - 1)
	for child: Node in _variant_host.get_children():
		child.queue_free()
	for button_index: int in _variant_buttons.size():
		_style_tab(_variant_buttons[button_index], button_index == _current_variant)
	var variant: Control
	match _current_variant:
		0: variant = _build_pyramid_journey()
		1: variant = _build_lesson_cards()
		_: variant = _build_quick_reference()
	_variant_host.add_child(variant)
	variant.modulate.a = 0.0
	variant.position.y = 8.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(variant, "modulate:a", 1.0, 0.18)
	tween.tween_property(variant, "position:y", 0.0, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _build_pyramid_journey() -> Control:
	var root := _full_root(CREAM)
	_add_circle(root, Vector2(-46, 64), 122.0, YELLOW, 0.46)
	_add_tilted_shape(root, Vector2(335, 88), Vector2(92, 136), LAVENDER.lightened(0.10), 13.0, 0.55)
	var page_margin := _full_margin(14, 14, 14, 14)
	root.add_child(page_margin)
	var page := _vbox(9)
	page.name = "VariantPage"
	page_margin.add_child(page)

	page.add_child(_screen_heading(_t("instructions_title"), _t("instructions_subtitle"), PURPLE, DARK_MUTED))
	var example_card := _panel(PURPLE, PURPLE, 27, 0, true)
	example_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(example_card)
	var example_margin := _margin(15, 15, 14, 14)
	example_card.add_child(example_margin)
	var example := _vbox(8)
	example_margin.add_child(example)
	var example_title := _label(_t("instructions_example"), 13, YELLOW, _dm_sans_semibold)
	example_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	example.add_child(example_title)
	example.add_child(_word_pool_example())
	var connection := _label(_t("instructions_same_group"), 14, WHITE, _fredoka_semibold)
	connection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	connection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	example.add_child(connection)
	example.add_child(_mini_check_button())
	var correct_band := _panel(PURPLE_LIGHT, Color("5942a2"), 16, 1)
	example.add_child(correct_band)
	var correct_margin := _margin(10, 10, 8, 8)
	correct_band.add_child(correct_margin)
	var correct_label := _label(_t("instructions_correct_row"), 12, WHITE, _dm_sans_semibold)
	correct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	correct_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	correct_margin.add_child(correct_label)
	example.add_child(_locked_group_example())
	var next := _label(_t("instructions_top_body"), 12, Color(1, 1, 1, 0.72), FONT_DM_SANS)
	next.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	example.add_child(next)
	example.add_child(_instruction_pyramid())
	page.add_child(_back_button())
	page.add_child(_concept_note(_t("instructions_concept_a")))
	return root

func _build_lesson_cards() -> Control:
	var root := _full_root(PURPLE)
	_add_circle(root, Vector2(304, -60), 148.0, YELLOW, 0.82)
	_add_tilted_shape(root, Vector2(-48, 530), Vector2(102, 118), Color("a9e8df"), -14.0, 0.30)
	var page_margin := _full_margin(14, 14, 13, 14)
	root.add_child(page_margin)
	var page := _vbox(8)
	page.name = "VariantPage"
	page_margin.add_child(page)
	page.add_child(_screen_heading(_t("instructions_title"), _t("instructions_subtitle"), WHITE, Color(1, 1, 1, 0.66)))

	var lesson_stack := _vbox(8)
	lesson_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(lesson_stack)
	lesson_stack.add_child(_clear_step_card("1", _t("instructions_find_title"), _t("instructions_find_body"), TEAL, _word_pool_example(true)))
	lesson_stack.add_child(_clear_step_card("2", _t("instructions_check_title"), _t("instructions_check_body"), YELLOW, _check_and_lock_example()))
	lesson_stack.add_child(_clear_step_card("3", _t("instructions_top_title"), _t("instructions_top_body"), CORAL, _top_example()))
	var tools := HBoxContainer.new()
	tools.add_theme_constant_override("separation", 8)
	lesson_stack.add_child(tools)
	tools.add_child(_tool_card(SaveManager.text("hint").to_upper(), _t("instructions_hint_body"), LAVENDER))
	tools.add_child(_tool_card("!", _t("instructions_mistake_body"), CORAL))
	page.add_child(_back_button())
	page.add_child(_concept_note(_t("instructions_concept_b"), Color(1, 1, 1, 0.58)))
	return root

func _build_quick_reference() -> Control:
	var root := _full_root(CREAM)
	var hero := PanelContainer.new()
	hero.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hero.offset_bottom = 185.0
	hero.add_theme_stylebox_override("panel", _style(PURPLE, PURPLE, 0, 0))
	root.add_child(hero)
	_add_circle(root, Vector2(-38, 88), 104.0, YELLOW, 0.74)
	_add_tilted_shape(root, Vector2(332, 68), Vector2(86, 112), Color("efb9dd"), 14.0, 0.62)
	var page_margin := _full_margin(14, 14, 13, 14)
	root.add_child(page_margin)
	var page := _vbox(9)
	page.name = "VariantPage"
	page_margin.add_child(page)
	page.add_child(_screen_heading(_t("instructions_title"), _t("instructions_subtitle"), WHITE, Color(1, 1, 1, 0.66)))

	var reference := _panel(WHITE, Color("e3dcf2"), 27, 1, true)
	reference.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(reference)
	var reference_margin := _margin(14, 14, 13, 13)
	reference.add_child(reference_margin)
	var content := _vbox(8)
	reference_margin.add_child(content)
	var goal := _label(_t("instructions_top_title").to_upper(), 12, MUTED, _dm_sans_semibold)
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(goal)
	content.add_child(_labeled_pyramid())
	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", Color("e9e3f5"))
	content.add_child(divider)
	content.add_child(_compact_rule("1", _t("instructions_find_title"), _t("instructions_find_body"), TEAL))
	content.add_child(_compact_rule("2", _t("instructions_check_title"), _t("instructions_check_body"), YELLOW))
	var reminders := HBoxContainer.new()
	reminders.add_theme_constant_override("separation", 8)
	content.add_child(reminders)
	reminders.add_child(_tool_card(SaveManager.text("hint").to_upper(), _t("instructions_hint_body"), LAVENDER))
	reminders.add_child(_tool_card("!", _t("instructions_mistake_body"), CORAL))
	var tip_band := _panel(Color("fff7cc"), YELLOW, 17, 1)
	content.add_child(tip_band)
	var tip_margin := _margin(12, 12, 9, 9)
	tip_band.add_child(tip_margin)
	var tip := _label(_t("instructions_quick_tip"), 11, PURPLE, _dm_sans_semibold)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_margin.add_child(tip)
	page.add_child(_back_button())
	page.add_child(_concept_note(_t("instructions_concept_c"), DARK_MUTED))
	return root

func _word_pool_example(compact: bool = false) -> VBoxContainer:
	var stack := _vbox(4)
	stack.name = "WordPoolExample"
	if not compact:
		var pool_label := _label(_t("instructions_pool"), 10, Color(1, 1, 1, 0.58), _dm_sans_semibold)
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
