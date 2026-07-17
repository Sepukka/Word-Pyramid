extends Control

const FONT_FREDOKA: Font = preload("res://assets/fonts/Fredoka.ttf")
const FONT_DM_SANS: Font = preload("res://assets/fonts/DMSans.ttf")

const PURPLE: Color = Color("1a0a5e")
const PURPLE_LIGHT: Color = Color("382181")
const PURPLE_SOFT: Color = Color("eee9fa")
const CREAM: Color = Color("fffaf0")
const WHITE: Color = Color("ffffff")
const YELLOW: Color = Color("ffd600")
const CORAL: Color = Color("ff6f61")
const TEAL: Color = Color("39c6b4")
const LAVENDER: Color = Color("cdb9ff")
const MUTED: Color = Color("8b80b6")
const DARK_MUTED: Color = Color("5d5286")

const VARIANT_NAMES: Array[String] = [
	"A  Celebration",
	"B  Pyramid recap",
	"C  Nordic scorecard",
]

var _fredoka_semibold: FontVariation
var _fredoka_bold: FontVariation
var _dm_sans_semibold: FontVariation
var _variant_host: Control
var _variant_buttons: Array[Button] = []
var _current_variant: int = 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fredoka_semibold = _font_variation(FONT_FREDOKA, 600, 0.16)
	_fredoka_bold = _font_variation(FONT_FREDOKA, 700, 0.35)
	_dm_sans_semibold = _font_variation(FONT_DM_SANS, 600, 0.08)
	_build_comparison_screen()
	_show_variant(0)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_LEFT:
		_show_variant(posmod(_current_variant - 1, VARIANT_NAMES.size()))
	elif event.keycode == KEY_RIGHT:
		_show_variant((_current_variant + 1) % VARIANT_NAMES.size())

func _build_comparison_screen() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = CREAM
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_variant_host = Control.new()
	_variant_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_variant_host.offset_top = 58.0
	add_child(_variant_host)

	var comparison_bar: PanelContainer = PanelContainer.new()
	comparison_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	comparison_bar.offset_bottom = 58.0
	comparison_bar.add_theme_stylebox_override("panel", _style(CREAM, CREAM, 0, 0))
	add_child(comparison_bar)
	var bar_margin: MarginContainer = _margin(8, 8, 8, 8)
	comparison_bar.add_child(bar_margin)
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	bar_margin.add_child(tabs)
	for index: int in VARIANT_NAMES.size():
		var tab: Button = Button.new()
		tab.text = VARIANT_NAMES[index]
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.custom_minimum_size.y = 42.0
		tab.focus_mode = Control.FOCUS_NONE
		tab.add_theme_font_override("font", _dm_sans_semibold)
		tab.add_theme_font_size_override("font_size", 11)
		tab.pressed.connect(_show_variant.bind(index))
		tabs.add_child(tab)
		_variant_buttons.append(tab)

func _show_variant(index: int) -> void:
	_current_variant = clampi(index, 0, VARIANT_NAMES.size() - 1)
	for child: Node in _variant_host.get_children():
		child.queue_free()
	for button_index: int in _variant_buttons.size():
		_style_tab(_variant_buttons[button_index], button_index == _current_variant)
	var variant: Control
	match _current_variant:
		0:
			variant = _build_celebration_dashboard()
		1:
			variant = _build_pyramid_recap()
		_:
			variant = _build_nordic_scorecard()
	_variant_host.add_child(variant)
	variant.modulate.a = 0.0
	variant.position.y = 10.0
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(variant, "modulate:a", 1.0, 0.20)
	tween.tween_property(variant, "position:y", 0.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _build_celebration_dashboard() -> Control:
	var root: Control = _full_root(PURPLE)
	_add_circle(root, Vector2(-42, 92), 128.0, YELLOW)
	_add_tilted_shape(root, Vector2(324, 126), Vector2(104, 154), LAVENDER, 12.0)

	var page_margin: MarginContainer = _full_margin(16, 16, 18, 16)
	root.add_child(page_margin)
	var page: VBoxContainer = _vbox(12)
	page_margin.add_child(page)

	var eyebrow_row: HBoxContainer = HBoxContainer.new()
	page.add_child(eyebrow_row)
	eyebrow_row.add_child(_chip("DAILY CHALLENGE", PURPLE, YELLOW))
	eyebrow_row.add_child(_spacer(true))
	var brand: Label = _label("WORD PYRAMID", 12, Color(1, 1, 1, 0.68), _dm_sans_semibold)
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eyebrow_row.add_child(brand)

	var heading: Label = _label("Puzzle complete!", 34, WHITE, _fredoka_bold)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(heading)
	var subheading: Label = _label("Beautiful work — every group found.", 14, Color(1, 1, 1, 0.72), FONT_DM_SANS)
	subheading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(subheading)

	var result_card: PanelContainer = _panel(CREAM, Color(1, 1, 1, 0.18), 28, 0, true)
	result_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(result_card)
	var card_margin: MarginContainer = _margin(18, 18, 20, 18)
	result_card.add_child(card_margin)
	var card: VBoxContainer = _vbox(14)
	card_margin.add_child(card)

	var score_badge: PanelContainer = _panel(YELLOW, YELLOW, 24, 0)
	score_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_child(score_badge)
	var score_margin: MarginContainer = _margin(22, 22, 10, 10)
	score_badge.add_child(score_margin)
	var score_row: HBoxContainer = HBoxContainer.new()
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 8)
	score_margin.add_child(score_row)
	score_row.add_child(_label("✓", 25, PURPLE, _fredoka_bold))
	score_row.add_child(_label("4 / 4 groups", 23, PURPLE, _fredoka_bold))

	var streak: PanelContainer = _panel(PURPLE_SOFT, Color("ded5f6"), 22, 1)
	card.add_child(streak)
	var streak_margin: MarginContainer = _margin(14, 14, 12, 12)
	streak.add_child(streak_margin)
	var streak_row: HBoxContainer = HBoxContainer.new()
	streak_row.add_theme_constant_override("separation", 12)
	streak_margin.add_child(streak_row)
	var streak_mark: Label = _label("7", 40, PURPLE, _fredoka_bold)
	streak_mark.custom_minimum_size.x = 52.0
	streak_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_row.add_child(streak_mark)
	var streak_copy: VBoxContainer = _vbox(1)
	streak_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	streak_row.add_child(streak_copy)
	streak_copy.add_child(_label("day streak", 20, PURPLE, _fredoka_semibold))
	streak_copy.add_child(_label("A new personal best", 12, DARK_MUTED, FONT_DM_SANS))
	streak_row.add_child(_chip("BEST", PURPLE, YELLOW))

	var stats: HBoxContainer = HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	card.add_child(stats)
	stats.add_child(_stat_card("1", "MISTAKE", CORAL, CREAM))
	stats.add_child(_stat_card("4 / 4", "GROUPS", TEAL, CREAM))
	stats.add_child(_stat_card("1", "HINT", Color("a642df"), CREAM))

	card.add_child(_spacer(false))
	card.add_child(_primary_button("Continue to unlimited", YELLOW, PURPLE))
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	card.add_child(actions)
	actions.add_child(_secondary_button("Share result", PURPLE, CREAM))
	actions.add_child(_secondary_button("Menu", PURPLE, CREAM))

	page.add_child(_concept_note("A · Strong celebration and clear next action"))
	return root

func _build_pyramid_recap() -> Control:
	var root: Control = _full_root(CREAM)
	var hero: PanelContainer = _panel(PURPLE, PURPLE, 0, 0)
	hero.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hero.offset_bottom = 236.0
	root.add_child(hero)
	_add_circle(root, Vector2(278, -52), 142.0, YELLOW)
	_add_tilted_shape(root, Vector2(-42, 104), Vector2(112, 96), TEAL.lightened(0.48), -14.0)

	var page_margin: MarginContainer = _full_margin(16, 16, 18, 16)
	root.add_child(page_margin)
	var page: VBoxContainer = _vbox(10)
	page_margin.add_child(page)

	var top_row: HBoxContainer = HBoxContainer.new()
	page.add_child(top_row)
	top_row.add_child(_chip("RESULTS", PURPLE, WHITE))
	top_row.add_child(_spacer(true))
	top_row.add_child(_label("Daily · Today", 12, Color(1, 1, 1, 0.70), _dm_sans_semibold))

	var heading: Label = _label("You solved it", 32, WHITE, _fredoka_bold)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(heading)
	var subheading: Label = _label("Your finished pyramid", 13, Color(1, 1, 1, 0.68), FONT_DM_SANS)
	subheading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(subheading)

	var pyramid_card: PanelContainer = _panel(WHITE, Color("e1d9f2"), 28, 1, true)
	pyramid_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(pyramid_card)
	var card_margin: MarginContainer = _margin(18, 18, 18, 16)
	pyramid_card.add_child(card_margin)
	var card: VBoxContainer = _vbox(11)
	card_margin.add_child(card)

	card.add_child(_mini_result_pyramid())
	var divider: HSeparator = HSeparator.new()
	divider.add_theme_color_override("separator", Color("e9e3f5"))
	card.add_child(divider)

	var score_row: HBoxContainer = HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 12)
	card.add_child(score_row)
	var score: PanelContainer = _panel(PURPLE, PURPLE, 22, 0)
	score.custom_minimum_size = Vector2(112, 100)
	score_row.add_child(score)
	var score_box: VBoxContainer = _vbox(0)
	score_box.alignment = BoxContainer.ALIGNMENT_CENTER
	score.add_child(score_box)
	var score_value: Label = _label("100%", 30, YELLOW, _fredoka_bold)
	score_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_box.add_child(score_value)
	var score_label: Label = _label("COMPLETED", 10, Color(1, 1, 1, 0.62), _dm_sans_semibold)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_box.add_child(score_label)
	var metrics: VBoxContainer = _vbox(7)
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_row.add_child(metrics)
	metrics.add_child(_metric_row("Groups", "4 / 4", TEAL))
	metrics.add_child(_metric_row("Mistakes", "1", CORAL))
	metrics.add_child(_metric_row("Hints used", "1", Color("a642df")))

	var streak_band: PanelContainer = _panel(Color("fff7cc"), YELLOW, 20, 1)
	card.add_child(streak_band)
	var streak_margin: MarginContainer = _margin(14, 14, 10, 10)
	streak_band.add_child(streak_margin)
	var streak_row: HBoxContainer = HBoxContainer.new()
	streak_margin.add_child(streak_row)
	streak_row.add_child(_label("7 day streak", 18, PURPLE, _fredoka_semibold))
	streak_row.add_child(_spacer(true))
	streak_row.add_child(_label("+1 today", 12, DARK_MUTED, _dm_sans_semibold))

	card.add_child(_spacer(false))
	card.add_child(_primary_button("Share your pyramid", PURPLE, WHITE))
	card.add_child(_secondary_button("Back to menu", PURPLE, WHITE))
	page.add_child(_concept_note("B · Makes the completed puzzle the hero", DARK_MUTED))
	return root

func _build_nordic_scorecard() -> Control:
	var root: Control = _full_root(PURPLE)
	_add_circle(root, Vector2(-68, 202), 122.0, YELLOW)
	_add_tilted_shape(root, Vector2(326, 78), Vector2(110, 140), Color("f0b9de"), 14.0)

	var page_margin: MarginContainer = _full_margin(16, 16, 18, 16)
	root.add_child(page_margin)
	var page: VBoxContainer = _vbox(11)
	page_margin.add_child(page)

	var brand_row: HBoxContainer = HBoxContainer.new()
	page.add_child(brand_row)
	brand_row.add_child(_label("WORD PYRAMID", 12, Color(1, 1, 1, 0.68), _dm_sans_semibold))
	brand_row.add_child(_spacer(true))
	brand_row.add_child(_chip("7 DAY STREAK", PURPLE, YELLOW))

	var hero_copy: VBoxContainer = _vbox(2)
	page.add_child(hero_copy)
	var overline: Label = _label("TODAY'S RESULT", 11, YELLOW, _dm_sans_semibold)
	overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_copy.add_child(overline)
	var title: Label = _label("Nicely done.", 34, WHITE, _fredoka_bold)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_copy.add_child(title)
	var subtitle: Label = _label("A calm, complete view of your run.", 13, Color(1, 1, 1, 0.66), FONT_DM_SANS)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hero_copy.add_child(subtitle)

	var scorecard: PanelContainer = _panel(CREAM, Color(1, 1, 1, 0.16), 30, 0, true)
	scorecard.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scorecard)
	var card_margin: MarginContainer = _margin(18, 18, 18, 18)
	scorecard.add_child(card_margin)
	var card: VBoxContainer = _vbox(12)
	card_margin.add_child(card)

	var summary: HBoxContainer = HBoxContainer.new()
	summary.add_theme_constant_override("separation", 14)
	card.add_child(summary)
	var grade: PanelContainer = _panel(YELLOW, YELLOW, 24, 0)
	grade.custom_minimum_size = Vector2(92, 92)
	summary.add_child(grade)
	var grade_box: VBoxContainer = _vbox(-2)
	grade_box.alignment = BoxContainer.ALIGNMENT_CENTER
	grade.add_child(grade_box)
	var grade_value: Label = _label("4/4", 32, PURPLE, _fredoka_bold)
	grade_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_box.add_child(grade_value)
	var grade_label: Label = _label("GROUPS", 10, PURPLE, _dm_sans_semibold)
	grade_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade_box.add_child(grade_label)
	var summary_copy: VBoxContainer = _vbox(3)
	summary_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_copy.alignment = BoxContainer.ALIGNMENT_CENTER
	summary.add_child(summary_copy)
	summary_copy.add_child(_label("Daily complete", 23, PURPLE, _fredoka_bold))
	summary_copy.add_child(_label("4 of 4 groups found", 13, DARK_MUTED, FONT_DM_SANS))
	summary_copy.add_child(_label("7 day streak", 12, TEAL.darkened(0.18), _dm_sans_semibold))

	card.add_child(_section_label("YOUR RUN"))
	card.add_child(_score_bar("Groups found", "4 / 4", 1.0, TEAL))
	card.add_child(_score_bar("Mistakes", "1", 0.25, CORAL))
	card.add_child(_score_bar("Hints used", "1", 0.50, Color("a642df")))

	card.add_child(_section_label("THIS WEEK"))
	var week: HBoxContainer = HBoxContainer.new()
	week.add_theme_constant_override("separation", 6)
	card.add_child(week)
	for day: String in ["M", "T", "W", "T", "F", "S", "S"]:
		var active: bool = week.get_child_count() < 7
		var day_panel: PanelContainer = _panel(YELLOW if active else PURPLE_SOFT, YELLOW if active else PURPLE_SOFT, 15, 0)
		day_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		day_panel.custom_minimum_size.y = 34.0
		week.add_child(day_panel)
		var day_label: Label = _label(day, 12, PURPLE if active else MUTED, _dm_sans_semibold)
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		day_panel.add_child(day_label)

	card.add_child(_spacer(false))
	card.add_child(_primary_button("Continue", YELLOW, PURPLE))
	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 8)
	card.add_child(bottom_row)
	bottom_row.add_child(_secondary_button("Share", PURPLE, CREAM))
	bottom_row.add_child(_secondary_button("Menu", PURPLE, CREAM))
	page.add_child(_concept_note("C · Premium, calm and statistics-forward"))
	return root

func _mini_result_pyramid() -> VBoxContainer:
	var pyramid: VBoxContainer = _vbox(4)
	for row_size: int in [1, 2, 3, 4]:
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4)
		pyramid.add_child(row)
		for tile_index: int in row_size:
			var colors: Array[Color] = [Color("9c5df2"), CORAL, TEAL, YELLOW]
			var tile: PanelContainer = _panel(colors[row_size - 1], colors[row_size - 1], 9, 0)
			tile.custom_minimum_size = Vector2(48, 30)
			row.add_child(tile)
			var mark: Label = _label("✓", 15, WHITE if row_size < 4 else PURPLE, _fredoka_bold)
			mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			tile.add_child(mark)
	return pyramid

func _stat_card(value_text: String, caption: String, accent: Color, background: Color) -> PanelContainer:
	var stat: PanelContainer = _panel(background, Color("e5def1"), 18, 1)
	stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin: MarginContainer = _margin(5, 5, 9, 9)
	stat.add_child(margin)
	var stack: VBoxContainer = _vbox(1)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(stack)
	var value: Label = _label(value_text, 22, accent, _fredoka_bold)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(value)
	var label: Label = _label(caption, 9, MUTED, _dm_sans_semibold)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(label)
	return stat

func _metric_row(label_text: String, value_text: String, accent: Color) -> PanelContainer:
	var metric: PanelContainer = _panel(PURPLE_SOFT, PURPLE_SOFT, 15, 0)
	var margin: MarginContainer = _margin(12, 12, 7, 7)
	metric.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	margin.add_child(row)
	row.add_child(_label(label_text, 12, DARK_MUTED, FONT_DM_SANS))
	row.add_child(_spacer(true))
	row.add_child(_label(value_text, 15, accent, _fredoka_semibold))
	return metric

func _score_bar(label_text: String, value_text: String, amount: float, accent: Color) -> VBoxContainer:
	var stack: VBoxContainer = _vbox(5)
	var copy: HBoxContainer = HBoxContainer.new()
	stack.add_child(copy)
	copy.add_child(_label(label_text, 13, DARK_MUTED, FONT_DM_SANS))
	copy.add_child(_spacer(true))
	copy.add_child(_label(value_text, 13, PURPLE, _fredoka_semibold))
	var track: Panel = Panel.new()
	track.add_theme_stylebox_override("panel", _style(PURPLE_SOFT, PURPLE_SOFT, 5, 0))
	track.custom_minimum_size.y = 9.0
	track.clip_contents = true
	stack.add_child(track)
	var fill: Panel = Panel.new()
	fill.add_theme_stylebox_override("panel", _style(accent, accent, 5, 0))
	fill.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	fill.anchor_right = clampf(amount, 0.0, 1.0)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	return stack

func _section_label(text_value: String) -> Label:
	return _label(text_value, 10, MUTED, _dm_sans_semibold)

func _concept_note(text_value: String, color: Color = Color(1, 1, 1, 0.62)) -> Label:
	var note: Label = _label(text_value, 11, color, _dm_sans_semibold)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return note

func _primary_button(text_value: String, fill: Color, text_color: Color) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 52.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", _fredoka_semibold)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_stylebox_override("normal", _style(fill, fill, 18, 0, true))
	button.add_theme_stylebox_override("hover", _style(fill.lightened(0.06), fill, 18, 0, true))
	button.add_theme_stylebox_override("pressed", _style(fill.darkened(0.06), fill, 18, 0))
	return button

func _secondary_button(text_value: String, text_color: Color, background: Color) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 44.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", _dm_sans_semibold)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_stylebox_override("normal", _style(background, Color("d7cfea"), 16, 1))
	button.add_theme_stylebox_override("hover", _style(PURPLE_SOFT, Color("c8bce3"), 16, 1))
	button.add_theme_stylebox_override("pressed", _style(Color("e5def5"), Color("b9abd9"), 16, 1))
	return button

func _style_tab(button: Button, active: bool) -> void:
	var fill: Color = PURPLE if active else PURPLE_SOFT
	var text_color: Color = WHITE if active else DARK_MUTED
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_stylebox_override("normal", _style(fill, fill, 15, 0))
	button.add_theme_stylebox_override("hover", _style(fill.lightened(0.06), fill, 15, 0))
	button.add_theme_stylebox_override("pressed", _style(fill.darkened(0.06), fill, 15, 0))

func _chip(text_value: String, text_color: Color, fill: Color) -> PanelContainer:
	var chip: PanelContainer = _panel(fill, fill, 14, 0)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var margin: MarginContainer = _margin(10, 10, 5, 5)
	chip.add_child(margin)
	margin.add_child(_label(text_value, 10, text_color, _dm_sans_semibold))
	return chip

func _panel(fill: Color, border: Color, radius: int, border_width: int, shadow: bool = false) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(fill, border, radius, border_width, shadow))
	return panel

func _style(fill: Color, border: Color, radius: int, border_width: int, shadow: bool = false) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	if shadow:
		style.shadow_color = Color(0.035, 0.012, 0.16, 0.22)
		style.shadow_size = 8
		style.shadow_offset = Vector2(0, 5)
	return style

func _label(text_value: String, font_size: int, color: Color, font: Font) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _vbox(separation: int) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	return box

func _margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin

func _full_margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin: MarginContainer = _margin(left, right, top, bottom)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return margin

func _spacer(horizontal: bool) -> Control:
	var spacer: Control = Control.new()
	if horizontal:
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return spacer

func _full_root(color: Color) -> Control:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	return root

func _add_circle(parent: Control, position_value: Vector2, diameter: float, color: Color) -> void:
	var circle: Panel = Panel.new()
	circle.position = position_value
	circle.size = Vector2.ONE * diameter
	circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle.add_theme_stylebox_override("panel", _style(color, color, int(diameter * 0.5), 0))
	parent.add_child(circle)

func _add_tilted_shape(parent: Control, position_value: Vector2, size_value: Vector2, color: Color, rotation_value: float) -> void:
	var shape: Panel = Panel.new()
	shape.position = position_value
	shape.size = size_value
	shape.rotation_degrees = rotation_value
	shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shape.add_theme_stylebox_override("panel", _style(color, color, 28, 0))
	parent.add_child(shape)

func _font_variation(base_font: Font, weight: int, embolden: float) -> FontVariation:
	var font: FontVariation = FontVariation.new()
	font.base_font = base_font
	font.variation_opentype = {"wght": weight}
	font.variation_embolden = embolden
	return font
