extends Control

const FONT_FREDOKA: Font = preload("res://assets/fonts/Fredoka.ttf")
const FONT_DM_SANS: Font = preload("res://assets/fonts/DMSans.ttf")
const PURPLE: Color = Color("1a0a5e")
const YELLOW: Color = Color("ffd600")
const MUTED: Color = Color("d9d1f3")
const TILE_WIDTH: float = 70.0
const TILE_HEIGHT: float = 91.0
const SAMPLE_WORDS: Array[String] = [
	"KAUNOKIRJALLISUUS",
	"SUOSIONOSOITUKSET",
	"AALLONMURTAJA",
	"KULTAINEN MAAILMANPALLO",
]

var _fredoka_semibold: FontVariation
var _fredoka_condensed: FontVariation
var _dm_sans_semibold: FontVariation

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fredoka_semibold = _font_variation(FONT_FREDOKA, 600, 0.10)
	_fredoka_condensed = _font_variation(FONT_FREDOKA, 600, 0.30, 85)
	_dm_sans_semibold = _font_variation(FONT_DM_SANS, 600, 0.06)
	_build()

func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = PURPLE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var page_margin: MarginContainer = MarginContainer.new()
	page_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_margin.add_theme_constant_override("margin_left", 14)
	page_margin.add_theme_constant_override("margin_right", 14)
	page_margin.add_theme_constant_override("margin_top", 18)
	page_margin.add_theme_constant_override("margin_bottom", 24)
	scroll.add_child(page_margin)

	var page: VBoxContainer = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	page_margin.add_child(page)

	var title: Label = _label("Long-word tile comparison", 25, Color.WHITE, _fredoka_semibold)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(title)
	var intro: Label = _label("Same 70 × 91 px blocks used by the 1.0.2 phone layout and the same words in every option. Compare clarity, wrapping, and personality.", 13, MUTED, FONT_DM_SANS)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(intro)

	_add_variant(page, "A · Current approach", "Condensed Fredoka · 11 px · automatic wrapping", _fredoka_condensed, 11, false, false)
	_add_variant(page, "B · Balanced Fredoka", "Semibold Fredoka · 12 px · deliberate two-line balance", _fredoka_semibold, 12, true, false)
	_add_variant(page, "C · Clear sans", "DM Sans Semibold · 11 px · deliberate two-line balance", _dm_sans_semibold, 11, true, false)
	_add_variant(page, "D · High contrast", "Semibold Fredoka · 12 px · balanced lines + subtle outline", _fredoka_semibold, 12, true, true)

	var recommendation: Label = _label("My starting recommendation: B. It keeps the playful game identity while avoiding extreme condensation.", 13, PURPLE, _dm_sans_semibold)
	recommendation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recommendation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recommendation.add_theme_stylebox_override("normal", _panel_style(Color("fff3b8"), YELLOW, 18, 1))
	page.add_child(recommendation)

func _add_variant(parent: VBoxContainer, heading: String, description: String, font: Font, font_size: int, balanced_wrap: bool, outlined: bool) -> void:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(Color("f9f7ff"), Color("d8cff0"), 20, 1))
	parent.add_child(card)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	margin.add_child(stack)
	stack.add_child(_label(heading, 17, PURPLE, _fredoka_semibold))
	stack.add_child(_label(description, 11, Color("756a9c"), FONT_DM_SANS))
	var tiles: HBoxContainer = HBoxContainer.new()
	tiles.alignment = BoxContainer.ALIGNMENT_CENTER
	tiles.add_theme_constant_override("separation", 5)
	stack.add_child(tiles)
	for word: String in SAMPLE_WORDS:
		tiles.add_child(_sample_tile(word, font, font_size, balanced_wrap, outlined))

func _sample_tile(word: String, font: Font, font_size: int, balanced_wrap: bool, outlined: bool) -> Button:
	var tile: Button = Button.new()
	tile.custom_minimum_size = Vector2(TILE_WIDTH, TILE_HEIGHT)
	tile.text = _balanced_two_lines(word) if balanced_wrap else word
	tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	tile.alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.focus_mode = Control.FOCUS_NONE
	tile.add_theme_font_override("font", font)
	tile.add_theme_font_size_override("font_size", font_size)
	tile.add_theme_color_override("font_color", PURPLE)
	tile.add_theme_color_override("font_outline_color", Color("d8cff0") if outlined else Color.TRANSPARENT)
	tile.add_theme_constant_override("outline_size", 1 if outlined else 0)
	var style: StyleBoxFlat = _panel_style(Color.WHITE, Color("cfc5ea") if not outlined else PURPLE, 15, 1 if not outlined else 2)
	style.shadow_color = Color(0.05, 0.02, 0.18, 0.18)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 3)
	tile.add_theme_stylebox_override("normal", style)
	return tile

func _balanced_two_lines(word: String) -> String:
	if word.contains(" "):
		var spaces: Array[int] = []
		for index: int in word.length():
			if word[index] == " ":
				spaces.append(index)
		if not spaces.is_empty():
			var split_at: int = spaces[0]
			for candidate: int in spaces:
				if absi(candidate * 2 - word.length()) < absi(split_at * 2 - word.length()):
					split_at = candidate
			return word.substr(0, split_at) + "\n" + word.substr(split_at + 1)
	var midpoint: int = word.length() / 2
	return word.substr(0, midpoint) + "\n" + word.substr(midpoint)

func _label(text_value: String, font_size: int, color: Color, font: Font) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _font_variation(base_font: Font, weight: int, embolden: float, width: int = 100) -> FontVariation:
	var font: FontVariation = FontVariation.new()
	font.base_font = base_font
	var variations: Dictionary = {"wght": weight}
	if width != 100:
		variations[2003072104] = width # wdth
	font.variation_opentype = variations
	font.variation_embolden = embolden
	return font

func _panel_style(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
