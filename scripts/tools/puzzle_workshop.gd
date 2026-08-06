extends Control

const FONT_FREDOKA: Font = preload("res://assets/fonts/Fredoka.ttf")
const FONT_DM_SANS: Font = preload("res://assets/fonts/DMSans.ttf")
const DATA_PATHS: Dictionary = {
	"en": {"daily": "res://data/daily_puzzles.json", "unlimited": "res://data/unlimited_puzzles.json"},
	"fi": {"daily": "res://data/daily_puzzles_fi.json", "unlimited": "res://data/unlimited_puzzles_fi.json"}
}
const DIFFICULTY_PATH: String = "res://data/puzzle_difficulty.json"
const GROUP_SIZES: Array[int] = [2, 3, 4, 5]
const PURPLE: Color = Color("1a0a5e")
const PURPLE_2: Color = Color("382276")
const YELLOW: Color = Color("ffd600")
const OFF_WHITE: Color = Color("fffaf2")
const SURFACE: Color = Color("ffffff")
const BORDER: Color = Color("d9d1f3")
const MUTED: Color = Color("756a9c")
const GREEN: Color = Color("39b77a")
const RED: Color = Color("e75c62")
const ORANGE: Color = Color("e89a35")

var _font_heading: FontVariation
var _font_body: FontVariation
var _font_tile: FontVariation
var _language: String = "en"
var _mode: String = "unlimited"
var _roots: Dictionary = {}
var _difficulty_root: Dictionary = {"version": 1, "puzzles": {}}
var _current_index: int = -1
var _is_draft: bool = false
var _dirty: bool = false
var _suspend_changes: bool = false

var _language_option: OptionButton
var _mode_option: OptionButton
var _search: LineEdit
var _puzzle_list: ItemList
var _dirty_label: Label
var _status: Label
var _id_input: LineEdit
var _title_input: LineEdit
var _top_word_input: LineEdit
var _date_input: LineEdit
var _tier_option: OptionButton
var _rating_input: SpinBox
var _breaks_input: TextEdit
var _group_inputs: Dictionary = {}
var _preview_pyramid: VBoxContainer
var _preview_title: Label
var _preview_meta: Label
var _validation_label: RichTextLabel
var _save_button: Button
var _revert_button: Button
var _delete_dialog: ConfirmationDialog
var _tabs: TabContainer

func _ready() -> void:
	_font_heading = _font_variation(FONT_FREDOKA, 650, 0.08)
	_font_body = _font_variation(FONT_DM_SANS, 500, 0.02)
	_font_tile = _font_variation(FONT_FREDOKA, 600, 0.05, 88)
	_build_interface()
	if not OS.has_feature("editor"):
		_status.text = "Puzzle Workshop on käytettävissä vain Godot-editorista käynnistettynä."
		_status.add_theme_color_override("font_color", RED)
	_load_all_data()
	_refresh_list()

func _build_interface() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = OFF_WHITE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var page := VBoxContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	page.add_theme_constant_override("separation", 7)
	add_child(page)
	page.add_child(_build_header())

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.add_theme_font_override("font", _font_heading)
	_tabs.add_theme_font_size_override("font_size", 14)
	page.add_child(_tabs)
	var library_panel := _build_library_panel()
	library_panel.name = "Kentat"
	_tabs.add_child(library_panel)
	var editor_panel := _build_editor_panel()
	editor_panel.name = "Muokkaa"
	_tabs.add_child(editor_panel)
	var preview_panel := _build_preview_panel()
	preview_panel.name = "Esikatselu"
	_tabs.add_child(preview_panel)
	_tabs.set_tab_title(0, "Kentät")
	_tabs.set_tab_title(1, "Muokkaa")
	_tabs.set_tab_title(2, "Esikatselu")

	_status = _label("Valmis", 12, MUTED, _font_body)
	_status.custom_minimum_size = Vector2(0, 34)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_status)

	_delete_dialog = ConfirmationDialog.new()
	_delete_dialog.title = "Poista kenttä"
	_delete_dialog.dialog_text = "Poistetaanko tämä kenttä ja sen vaikeustieto? Tätä ei voi perua Workshopissa."
	_delete_dialog.confirmed.connect(_confirm_delete)
	add_child(_delete_dialog)

func _build_header() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(PURPLE, PURPLE, 22, 0, 12))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	card.add_child(stack)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	stack.add_child(row)
	var title := _label("Puzzle Workshop", 22, Color.WHITE, _font_heading)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(title)
	var close := _button("Sulje", false)
	close.custom_minimum_size = Vector2(64, 38)
	close.pressed.connect(func() -> void: get_tree().quit())
	row.add_child(close)
	_dirty_label = _label("Ei muutoksia", 10, Color("d9d1f3"), _font_body)
	_dirty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dirty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dirty_label.clip_text = true
	_dirty_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stack.add_child(_dirty_label)
	return card

func _build_library_panel() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(SURFACE, BORDER, 20, 1, 12))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	card.add_child(stack)
	stack.add_child(_label("Kenttäkirjasto", 19, PURPLE, _font_heading))

	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 6)
	stack.add_child(filters)
	_language_option = OptionButton.new()
	_language_option.add_item("English", 0)
	_language_option.add_item("Suomi", 1)
	_language_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_option(_language_option)
	_language_option.item_selected.connect(_on_language_selected)
	filters.add_child(_language_option)
	_mode_option = OptionButton.new()
	_mode_option.add_item("Unlimited", 0)
	_mode_option.add_item("Daily", 1)
	_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_option(_mode_option)
	_mode_option.item_selected.connect(_on_mode_selected)
	filters.add_child(_mode_option)

	_search = LineEdit.new()
	_search.placeholder_text = "Hae nimellä tai ID:llä"
	_style_line_edit(_search)
	_search.text_changed.connect(func(_value: String) -> void: _refresh_list())
	stack.add_child(_search)

	_puzzle_list = ItemList.new()
	_puzzle_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_puzzle_list.add_theme_font_override("font", _font_body)
	_puzzle_list.add_theme_font_size_override("font_size", 13)
	_puzzle_list.item_selected.connect(_on_list_selected)
	stack.add_child(_puzzle_list)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	stack.add_child(actions)
	var new_button := _button("+ Uusi", true)
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_button.pressed.connect(_new_puzzle)
	actions.add_child(new_button)
	var duplicate := _button("Kopioi", false)
	duplicate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	duplicate.pressed.connect(_duplicate_puzzle)
	actions.add_child(duplicate)
	var remove := _button("Poista", false)
	remove.pressed.connect(_request_delete)
	remove.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(remove)
	return card

func _build_editor_panel() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(SURFACE, BORDER, 20, 1, 0))
	var scroll := ScrollContainer.new()
	scroll.name = "EditorScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 18)
	scroll.add_child(margin)
	var stack := VBoxContainer.new()
	stack.name = "EditorStack"
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)
	stack.add_child(_label("Kentän sisältö", 20, PURPLE, _font_heading))

	var identity := GridContainer.new()
	identity.columns = 1
	identity.add_theme_constant_override("h_separation", 10)
	identity.add_theme_constant_override("v_separation", 4)
	stack.add_child(identity)
	_id_input = _add_labeled_input(identity, "Kentän ID", "unlimited_001")
	_title_input = _add_labeled_input(identity, "Nimi", "Kitchen Logic")
	_top_word_input = _add_labeled_input(identity, "Huippusana", "APRON")
	_date_input = _add_labeled_input(identity, "Päivä (Daily)", "2026-07-18")
	_date_input.editable = _mode == "daily"

	var difficulty := GridContainer.new()
	difficulty.columns = 1
	difficulty.add_theme_constant_override("separation", 4)
	stack.add_child(difficulty)
	difficulty.add_child(_field_label("Vaikeustaso"))
	_tier_option = OptionButton.new()
	for tier: int in range(1, 6):
		_tier_option.add_item(str(tier), tier)
	_tier_option.select(1)
	_style_option(_tier_option)
	_tier_option.item_selected.connect(_on_option_changed)
	difficulty.add_child(_tier_option)
	difficulty.add_child(_field_label("Rating 500–1600"))
	_rating_input = SpinBox.new()
	_rating_input.min_value = 500
	_rating_input.max_value = 1600
	_rating_input.step = 10
	_rating_input.value = 900
	_rating_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rating_input.value_changed.connect(_on_number_changed)
	difficulty.add_child(_rating_input)

	stack.add_child(_separator())
	stack.add_child(_label("Ryhmät", 18, PURPLE, _font_heading))
	for size_value: int in GROUP_SIZES:
		stack.add_child(_build_group_editor(size_value))

	stack.add_child(_separator())
	stack.add_child(_label("Sanakatkot", 18, PURPLE, _font_heading))
	var breaks_help := _label("Yksi rivi per sana muodossa SANA=SANA|KATKO. Pystyviiva muuttuu rivinvaihdoksi pelissä.", 11, MUTED, _font_body)
	breaks_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(breaks_help)
	_breaks_input = TextEdit.new()
	_breaks_input.custom_minimum_size.y = 82
	_breaks_input.placeholder_text = "AALLONMURTAJA=AALLON|MURTAJA"
	_breaks_input.add_theme_font_override("font", _font_body)
	_breaks_input.add_theme_font_size_override("font_size", 13)
	_breaks_input.text_changed.connect(_on_text_edit_changed)
	stack.add_child(_breaks_input)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	stack.add_child(actions)
	_save_button = _button("Tallenna kenttä", true)
	_save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_button.custom_minimum_size.y = 48
	_save_button.pressed.connect(_save_current)
	actions.add_child(_save_button)
	_revert_button = _button("Palauta", false)
	_revert_button.pressed.connect(_revert_current)
	actions.add_child(_revert_button)
	return card

func _build_group_editor(size_value: int) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _panel_style(Color("faf8ff"), BORDER, 15, 1, 9))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	card.add_child(stack)
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation", 4)
	stack.add_child(heading)
	var title := _label("%d sanan ryhmä" % size_value, 14, PURPLE, _font_heading)
	title.custom_minimum_size.x = 0
	heading.add_child(title)
	var label_input := LineEdit.new()
	label_input.placeholder_text = "Ryhmän yhdistävä tekijä"
	label_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_line_edit(label_input)
	label_input.text_changed.connect(_on_line_changed)
	heading.add_child(label_input)
	var words_row := GridContainer.new()
	words_row.columns = 2
	words_row.add_theme_constant_override("h_separation", 5)
	words_row.add_theme_constant_override("v_separation", 5)
	stack.add_child(words_row)
	var word_inputs: Array[LineEdit] = []
	for word_index: int in size_value:
		var input := LineEdit.new()
		input.placeholder_text = "Sana %d" % (word_index + 1)
		input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input.add_theme_font_override("font", _font_tile)
		input.add_theme_font_size_override("font_size", 12)
		_style_line_edit(input)
		input.text_changed.connect(_on_line_changed)
		words_row.add_child(input)
		word_inputs.append(input)
	_group_inputs[size_value] = {"label": label_input, "words": word_inputs}
	return card

func _build_preview_panel() -> Control:
	var outer := PanelContainer.new()
	outer.add_theme_stylebox_override("panel", _panel_style(PURPLE, PURPLE, 24, 0, 12))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	outer.add_child(stack)
	var heading := HBoxContainer.new()
	stack.add_child(heading)
	var preview_label := _label("Puhelinesikatselu", 19, Color.WHITE, _font_heading)
	preview_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(preview_label)
	_preview_meta = _label("390 × 844", 11, Color("d9d1f3"), _font_body)
	heading.add_child(_preview_meta)

	var phone := PanelContainer.new()
	phone.size_flags_vertical = Control.SIZE_EXPAND_FILL
	phone.add_theme_stylebox_override("panel", _panel_style(OFF_WHITE, Color("0e0632"), 26, 3, 12))
	stack.add_child(phone)
	var phone_content := VBoxContainer.new()
	phone_content.alignment = BoxContainer.ALIGNMENT_CENTER
	phone_content.add_theme_constant_override("separation", 8)
	phone.add_child(phone_content)
	var logo := _label("Word Ascent", 20, PURPLE, _font_heading)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phone_content.add_child(logo)
	_preview_title = _label("Uusi kenttä", 15, PURPLE_2, _font_heading)
	_preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phone_content.add_child(_preview_title)
	var instruction := _label("Löydä samaan ryhmään kuuluvat sanat", 11, MUTED, _font_body)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phone_content.add_child(instruction)
	var purple_card := PanelContainer.new()
	purple_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	purple_card.add_theme_stylebox_override("panel", _panel_style(PURPLE_2, PURPLE_2, 22, 0, 10))
	phone_content.add_child(purple_card)
	_preview_pyramid = VBoxContainer.new()
	_preview_pyramid.alignment = BoxContainer.ALIGNMENT_CENTER
	_preview_pyramid.add_theme_constant_override("separation", 6)
	purple_card.add_child(_preview_pyramid)

	_validation_label = RichTextLabel.new()
	_validation_label.bbcode_enabled = true
	_validation_label.fit_content = true
	_validation_label.custom_minimum_size.y = 126
	_validation_label.add_theme_font_override("normal_font", _font_body)
	_validation_label.add_theme_font_size_override("normal_font_size", 11)
	stack.add_child(_validation_label)
	return outer

func _load_all_data() -> void:
	_roots.clear()
	for language_key: String in DATA_PATHS:
		_roots[language_key] = {}
		var paths: Dictionary = DATA_PATHS[language_key]
		for mode_key: String in paths:
			var root: Dictionary = _read_json_dictionary(str(paths[mode_key]))
			if not root.get("puzzles", null) is Array:
				root = {"puzzles": []}
			(_roots[language_key] as Dictionary)[mode_key] = root
	_difficulty_root = _read_json_dictionary(DIFFICULTY_PATH)
	if not _difficulty_root.get("puzzles", null) is Dictionary:
		_difficulty_root = {"version": 1, "puzzles": {}}

func _read_json_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_status_message("Tiedostoa ei voitu avata: %s" % path, true)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return (parsed as Dictionary).duplicate(true)
	_status_message("Virheellinen JSON: %s" % path, true)
	return {}

func _current_root() -> Dictionary:
	return ((_roots.get(_language, {}) as Dictionary).get(_mode, {}) as Dictionary)

func _current_puzzles() -> Array:
	return _current_root().get("puzzles", []) as Array

func _refresh_list(select_id: String = "") -> void:
	if _puzzle_list == null:
		return
	_puzzle_list.clear()
	var query := _search.text.strip_edges().to_lower() if _search != null else ""
	var puzzles := _current_puzzles()
	var selected_list_index := -1
	for source_index: int in puzzles.size():
		var puzzle: Dictionary = puzzles[source_index] as Dictionary
		var puzzle_id := str(puzzle.get("id", ""))
		var title := str(puzzle.get("title", "Nimetön"))
		if not query.is_empty() and not (puzzle_id.to_lower().contains(query) or title.to_lower().contains(query)):
			continue
		var list_index := _puzzle_list.add_item("%s\n%s" % [title, puzzle_id])
		_puzzle_list.set_item_metadata(list_index, source_index)
		if puzzle_id == select_id:
			selected_list_index = list_index
	if selected_list_index >= 0:
		_puzzle_list.select(selected_list_index)
		_load_puzzle(int(_puzzle_list.get_item_metadata(selected_list_index)))
	elif _puzzle_list.item_count > 0 and not _is_draft:
		_puzzle_list.select(0)
		_load_puzzle(int(_puzzle_list.get_item_metadata(0)))
	elif _puzzle_list.item_count == 0 and not _is_draft:
		_clear_form()

func _on_language_selected(index: int) -> void:
	if not _can_leave_current():
		_language_option.select(0 if _language == "en" else 1)
		return
	_language = "en" if index == 0 else "fi"
	_current_index = -1
	_refresh_list()

func _on_mode_selected(index: int) -> void:
	if not _can_leave_current():
		_mode_option.select(0 if _mode == "unlimited" else 1)
		return
	_mode = "unlimited" if index == 0 else "daily"
	_date_input.editable = _mode == "daily"
	_current_index = -1
	_refresh_list()

func _on_list_selected(list_index: int) -> void:
	var source_index := int(_puzzle_list.get_item_metadata(list_index))
	if source_index == _current_index and not _is_draft:
		return
	if not _can_leave_current():
		_select_current_in_list()
		return
	_load_puzzle(source_index)
	_tabs.current_tab = 1

func _can_leave_current() -> bool:
	if not _dirty:
		return true
	_status_message("Tallentamattomia muutoksia: tallenna tai paina Palauta ennen kentän vaihtamista.", true)
	return false

func _select_current_in_list() -> void:
	for list_index: int in _puzzle_list.item_count:
		if int(_puzzle_list.get_item_metadata(list_index)) == _current_index:
			_puzzle_list.select(list_index)
			return
	_puzzle_list.deselect_all()

func _load_puzzle(index: int) -> void:
	var puzzles := _current_puzzles()
	if index < 0 or index >= puzzles.size():
		return
	_current_index = index
	_is_draft = false
	_populate_form((puzzles[index] as Dictionary).duplicate(true))

func _populate_form(puzzle: Dictionary) -> void:
	_suspend_changes = true
	var puzzle_id := str(puzzle.get("id", ""))
	_id_input.text = puzzle_id
	_title_input.text = str(puzzle.get("title", ""))
	_top_word_input.text = str(puzzle.get("top_word", ""))
	var schedule: Dictionary = _current_root().get("schedule", {}) as Dictionary
	_date_input.text = str(schedule.get(puzzle_id, puzzle.get("date", "")))
	var metadata: Dictionary = (_difficulty_root.get("puzzles", {}) as Dictionary).get(puzzle_id, {}) as Dictionary
	var tier := clampi(int(metadata.get("tier", 2)), 1, 5)
	_tier_option.select(tier - 1)
	_rating_input.value = clampi(int(metadata.get("rating", 900)), 500, 1600)
	for size_value: int in GROUP_SIZES:
		var group := _find_group(puzzle, size_value)
		var controls: Dictionary = _group_inputs[size_value]
		(controls["label"] as LineEdit).text = str(group.get("label", ""))
		var words: Array = group.get("words", []) as Array
		var inputs: Array = controls["words"] as Array
		for word_index: int in inputs.size():
			(inputs[word_index] as LineEdit).text = str(words[word_index]) if word_index < words.size() else ""
	_breaks_input.text = _breaks_to_editor_text(puzzle.get("display_breaks", {}) as Dictionary)
	_suspend_changes = false
	_set_dirty(false)
	_update_preview_and_validation()

func _find_group(puzzle: Dictionary, size_value: int) -> Dictionary:
	for group_value: Variant in puzzle.get("groups", []):
		if group_value is Dictionary and int((group_value as Dictionary).get("size", 0)) == size_value:
			return group_value as Dictionary
	return {"size": size_value, "label": "", "words": []}

func _new_puzzle() -> void:
	if not _can_leave_current():
		return
	_current_index = -1
	_is_draft = true
	var puzzle := _blank_puzzle(_next_id())
	_populate_form(puzzle)
	_is_draft = true
	_set_dirty(true)
	_puzzle_list.deselect_all()
	_tabs.current_tab = 1
	_status_message("Uusi kenttäluonnos. Täytä tiedot ja tallenna.")

func _duplicate_puzzle() -> void:
	if not _can_leave_current() or _current_index < 0:
		return
	var source: Dictionary = (_current_puzzles()[_current_index] as Dictionary).duplicate(true)
	source["id"] = _next_id()
	source["title"] = "%s Copy" % str(source.get("title", ""))
	_current_index = -1
	_is_draft = true
	_populate_form(source)
	_is_draft = true
	_set_dirty(true)
	_puzzle_list.deselect_all()
	_tabs.current_tab = 1
	_status_message("Kentästä luotiin kopio. Muuta ID:tä tai sisältöä ennen tallennusta.")

func _blank_puzzle(puzzle_id: String) -> Dictionary:
	var groups: Array[Dictionary] = []
	for size_value: int in GROUP_SIZES:
		var words: Array[String] = []
		for _index: int in size_value:
			words.append("")
		groups.append({"size": size_value, "label": "", "words": words})
	return {"id": puzzle_id, "title": "", "groups": groups, "top_word": "", "difficulty": 2, "difficulty_rating": 900, "display_breaks": {}}

func _next_id() -> String:
	var prefix := "fi_%s_" % _mode if _language == "fi" else "%s_" % _mode
	var largest := 0
	for root_language: String in _roots:
		for root_mode: String in (_roots[root_language] as Dictionary):
			for puzzle_value: Variant in (((_roots[root_language] as Dictionary)[root_mode] as Dictionary).get("puzzles", []) as Array):
				var puzzle_id := str((puzzle_value as Dictionary).get("id", ""))
				if puzzle_id.begins_with(prefix):
					largest = maxi(largest, int(puzzle_id.trim_prefix(prefix)))
	return "%s%03d" % [prefix, largest + 1]

func _revert_current() -> void:
	if _is_draft:
		_is_draft = false
		_set_dirty(false)
		_refresh_list()
	elif _current_index >= 0:
		_load_puzzle(_current_index)

func _request_delete() -> void:
	if _current_index < 0 or _is_draft:
		_status_message("Valitse ensin tallennettu kenttä.", true)
		return
	if _dirty:
		_status_message("Palauta tai tallenna muutokset ennen poistamista.", true)
		return
	_delete_dialog.popup_centered()

func _confirm_delete() -> void:
	var puzzles := _current_puzzles()
	if _current_index < 0 or _current_index >= puzzles.size():
		return
	var puzzle_id := str((puzzles[_current_index] as Dictionary).get("id", ""))
	puzzles.remove_at(_current_index)
	(_difficulty_root.get("puzzles", {}) as Dictionary).erase(puzzle_id)
	var schedule: Dictionary = _current_root().get("schedule", {}) as Dictionary
	schedule.erase(puzzle_id)
	if _persist_current_files():
		_current_index = -1
		PuzzleLoader.load_puzzles()
		_refresh_list()
		_status_message("Kenttä %s poistettiin." % puzzle_id)
	else:
		_load_all_data()
		_refresh_list(puzzle_id)

func _save_current() -> void:
	if not OS.has_feature("editor"):
		_status_message("Tallennus on estetty exportatussa versiossa.", true)
		return
	var puzzle := _form_to_puzzle()
	var errors := _validate_with_extras(puzzle)
	if not errors.is_empty():
		_status_message("Kenttää ei tallennettu: korjaa punaiset virheet.", true)
		return
	var puzzles := _current_puzzles()
	var old_id := ""
	if not _is_draft and _current_index >= 0 and _current_index < puzzles.size():
		old_id = str((puzzles[_current_index] as Dictionary).get("id", ""))
	var stored := puzzle.duplicate(true)
	stored.erase("difficulty")
	stored.erase("difficulty_rating")
	stored.erase("difficulty_source")
	stored.erase("date")
	if (stored.get("display_breaks", {}) as Dictionary).is_empty():
		stored.erase("display_breaks")
	if _is_draft:
		puzzles.append(stored)
		_current_index = puzzles.size() - 1
	else:
		puzzles[_current_index] = stored
	var puzzle_id := str(puzzle["id"])
	var difficulty_puzzles: Dictionary = _difficulty_root["puzzles"] as Dictionary
	if not old_id.is_empty() and old_id != puzzle_id:
		difficulty_puzzles.erase(old_id)
		(_current_root().get("schedule", {}) as Dictionary).erase(old_id)
	difficulty_puzzles[puzzle_id] = {"tier": int(puzzle["difficulty"]), "rating": int(puzzle["difficulty_rating"])}
	if _mode == "daily":
		if not _current_root().has("schedule"):
			_current_root()["schedule"] = {}
		var schedule: Dictionary = _current_root()["schedule"] as Dictionary
		var date_value := _date_input.text.strip_edges()
		if date_value.is_empty():
			schedule.erase(puzzle_id)
		else:
			schedule[puzzle_id] = date_value
	if not _persist_current_files():
		_load_all_data()
		_refresh_list(old_id)
		return
	_is_draft = false
	_set_dirty(false)
	PuzzleLoader.load_puzzles()
	_refresh_list(puzzle_id)
	_status_message("Kenttä %s tallennettiin. Varmuuskopio luotiin user://puzzle_workshop_backups-hakemistoon." % puzzle_id)

func _persist_current_files() -> bool:
	var data_path := str((DATA_PATHS[_language] as Dictionary)[_mode])
	var originals := {data_path: _read_text(data_path), DIFFICULTY_PATH: _read_text(DIFFICULTY_PATH)}
	_backup_texts(originals)
	var data_text := JSON.stringify(_current_root(), "\t", false) + "\n"
	var difficulty_text := JSON.stringify(_difficulty_root, "\t", false) + "\n"
	if not _write_text(data_path, data_text):
		_status_message("Sisältötiedoston tallennus epäonnistui.", true)
		return false
	if not _write_text(DIFFICULTY_PATH, difficulty_text):
		_write_text(data_path, str(originals[data_path]))
		_status_message("Vaikeustiedoston tallennus epäonnistui; sisältötiedosto palautettiin.", true)
		return false
	return true

func _backup_texts(originals: Dictionary) -> void:
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var directory := "user://puzzle_workshop_backups/%s" % stamp
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	for path_value: Variant in originals:
		var filename := str(path_value).get_file()
		_write_text("%s/%s" % [directory, filename], str(originals[path_value]))

func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _write_text(path: String, content: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.flush()
	return file.get_error() == OK

func _form_to_puzzle() -> Dictionary:
	var groups: Array[Dictionary] = []
	for size_value: int in GROUP_SIZES:
		var controls: Dictionary = _group_inputs[size_value]
		var words: Array[String] = []
		for input_value: Variant in controls["words"]:
			words.append((input_value as LineEdit).text.strip_edges().to_upper())
		groups.append({"size": size_value, "label": (controls["label"] as LineEdit).text.strip_edges(), "words": words})
	return {
		"id": _id_input.text.strip_edges(),
		"title": _title_input.text.strip_edges(),
		"groups": groups,
		"top_word": _top_word_input.text.strip_edges().to_upper(),
		"display_breaks": _editor_text_to_breaks(),
		"difficulty": _tier_option.get_selected_id(),
		"difficulty_rating": int(_rating_input.value)
	}

func _editor_text_to_breaks() -> Dictionary:
	var result: Dictionary = {}
	for raw_line: String in _breaks_input.text.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty() or not line.contains("="):
			continue
		var separator := line.find("=")
		var word := line.substr(0, separator).strip_edges().to_upper()
		var display := line.substr(separator + 1).strip_edges().replace("|", "\n")
		if not word.is_empty():
			result[word] = display
	return result

func _breaks_to_editor_text(display_breaks: Dictionary) -> String:
	var lines: PackedStringArray = []
	for word_value: Variant in display_breaks:
		lines.append("%s=%s" % [str(word_value), str(display_breaks[word_value]).replace("\n", "|")])
	return "\n".join(lines)

func _validate_with_extras(puzzle: Dictionary) -> PackedStringArray:
	var errors := PuzzleLoader.validate_puzzle(puzzle)
	var puzzle_id := str(puzzle.get("id", ""))
	for language_key: String in _roots:
		for mode_key: String in (_roots[language_key] as Dictionary):
			var puzzles: Array = ((_roots[language_key] as Dictionary)[mode_key] as Dictionary).get("puzzles", []) as Array
			for index: int in puzzles.size():
				if language_key == _language and mode_key == _mode and index == _current_index and not _is_draft:
					continue
				if str((puzzles[index] as Dictionary).get("id", "")) == puzzle_id and not puzzle_id.is_empty():
					errors.append("id is already used in %s/%s" % [language_key, mode_key])
	if str(puzzle.get("title", "")).strip_edges().is_empty():
		errors.append("missing title")
	if _mode == "daily" and not _date_input.text.strip_edges().is_empty() and not _valid_iso_date(_date_input.text.strip_edges()):
		errors.append("daily date must use YYYY-MM-DD")
	elif _mode == "daily" and not _date_input.text.strip_edges().is_empty():
		var requested_date := _date_input.text.strip_edges()
		var schedule: Dictionary = _current_root().get("schedule", {}) as Dictionary
		for scheduled_id_value: Variant in schedule:
			var scheduled_id := str(scheduled_id_value)
			if scheduled_id != puzzle_id and str(schedule[scheduled_id_value]) == requested_date:
				errors.append("daily date is already used by %s" % scheduled_id)
	var break_lines := _breaks_input.text.split("\n")
	for raw_line: String in break_lines:
		if not raw_line.strip_edges().is_empty() and not raw_line.contains("="):
			errors.append("invalid display break line: %s" % raw_line.strip_edges())
	return errors

func _warnings_for(puzzle: Dictionary) -> PackedStringArray:
	var warnings: PackedStringArray = []
	var breaks: Dictionary = puzzle.get("display_breaks", {}) as Dictionary
	var seen_pool_words: Dictionary = {}
	for group_value: Variant in puzzle.get("groups", []):
		for word_value: Variant in (group_value as Dictionary).get("words", []):
			var word := str(word_value)
			if word.length() >= 12 and not breaks.has(word):
				warnings.append("Pitkä sana ilman käsin määritettyä katkoa: %s" % word)
			seen_pool_words[word] = true
	var top_word := str(puzzle.get("top_word", ""))
	if top_word.length() >= 12 and not breaks.has(top_word):
		warnings.append("Pitkä huippusana ilman katkoa: %s" % top_word)
	if _mode == "daily" and _date_input.text.strip_edges().is_empty():
		warnings.append("Daily-kentällä ei ole kiinteää päivämäärää")
	return warnings

func _valid_iso_date(value: String) -> bool:
	var parts := value.split("-")
	return parts.size() == 3 and parts[0].length() == 4 and parts[1].length() == 2 and parts[2].length() == 2 and int(parts[1]) in range(1, 13) and int(parts[2]) in range(1, 32)

func _update_preview_and_validation() -> void:
	if _preview_pyramid == null:
		return
	var puzzle := _form_to_puzzle()
	_preview_title.text = str(puzzle.get("title", "Uusi kenttä")) if not str(puzzle.get("title", "")).is_empty() else "Uusi kenttä"
	_preview_meta.text = "390 × 844  ·  Tier %d  ·  %d" % [int(puzzle["difficulty"]), int(puzzle["difficulty_rating"])]
	_clear_children(_preview_pyramid)
	var rows: Array[Array] = []
	rows.append([str(puzzle.get("top_word", "HUIPPU"))])
	for size_value: int in GROUP_SIZES:
		var group := _find_group(puzzle, size_value)
		rows.append((group.get("words", []) as Array).duplicate())
	var breaks: Dictionary = puzzle.get("display_breaks", {}) as Dictionary
	for row_index: int in rows.size():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 5)
		_preview_pyramid.add_child(row)
		for word_value: Variant in rows[row_index]:
			var word := str(word_value)
			row.add_child(_preview_tile(str(breaks.get(word, word)), word.length() >= 12 and not breaks.has(word)))
	var errors := _validate_with_extras(puzzle)
	var warnings := _warnings_for(puzzle)
	_save_button.disabled = not errors.is_empty()
	var lines: PackedStringArray = []
	if errors.is_empty():
		lines.append("[color=#39b77a][b]✓ Kenttä on teknisesti kelvollinen[/b][/color]")
	else:
		lines.append("[color=#e75c62][b]Korjattavaa (%d)[/b][/color]" % errors.size())
		for error: String in errors:
			lines.append("[color=#e75c62]• %s[/color]" % _translate_error(error))
	if not warnings.is_empty():
		lines.append("[color=#e89a35][b]Huomiot (%d)[/b][/color]" % warnings.size())
		for warning: String in warnings:
			lines.append("[color=#e89a35]• %s[/color]" % warning)
	_validation_label.text = "\n".join(lines)

func _preview_tile(display_text: String, warning: bool) -> Button:
	var tile := Button.new()
	tile.custom_minimum_size = Vector2(60, 62)
	tile.text = display_text if not display_text.is_empty() else "—"
	tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tile.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.focus_mode = Control.FOCUS_NONE
	tile.add_theme_font_override("font", _font_tile)
	tile.add_theme_font_size_override("font_size", 11)
	tile.add_theme_color_override("font_color", PURPLE)
	var border_color := ORANGE if warning else BORDER
	var style := _panel_style(SURFACE, border_color, 14, 2 if warning else 1, 4)
	style.shadow_color = Color(0.04, 0.02, 0.16, 0.2)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0, 2)
	tile.add_theme_stylebox_override("normal", style)
	return tile

func _translate_error(error: String) -> String:
	var translations := {
		"missing id": "Kentän ID puuttuu",
		"missing top word": "Huippusana puuttuu",
		"groups must be an array": "Ryhmät puuttuvat",
		"requires exactly four groups": "Kentässä täytyy olla neljä ryhmää",
		"each group must be an object": "Ryhmän rakenne on virheellinen",
		"group size does not match its words": "Ryhmän sanamäärä ei vastaa ryhmän kokoa",
		"group missing label": "Ryhmän yhdistävä tekijä puuttuu",
		"words must be non-empty and unique": "Sanojen täytyy olla täytettyjä ja yksilöllisiä",
		"group sizes must be 2, 3, 4 and 5": "Ryhmien kokojen täytyy olla 2, 3, 4 ja 5",
		"groups must contain 14 unique words": "Ryhmissä täytyy olla yhteensä 14 eri sanaa",
		"top word must not occur in a group": "Huippusana ei saa esiintyä ryhmissä",
		"difficulty must be between 1 and 5": "Vaikeustason täytyy olla 1–5",
		"difficulty_rating must be between 500 and 1600": "Ratingin täytyy olla 500–1600",
		"display_breaks must be an object": "Sanakatkojen rakenne on virheellinen",
		"missing title": "Kentän nimi puuttuu",
		"daily date must use YYYY-MM-DD": "Päivämäärän muodon täytyy olla YYYY-MM-DD"
	}
	for key: String in translations:
		if error == key:
			return str(translations[key])
	if error.begins_with("display_breaks references an unknown word"):
		return "Sanakatko viittaa sanaan, jota kentässä ei ole: %s" % error.get_slice(":", 1).strip_edges()
	if error.begins_with("display_breaks must only add whitespace"):
		return "Sanakatko saa lisätä vain rivinvaihdon: %s" % error.get_slice(":", 1).strip_edges()
	if error.begins_with("id is already used"):
		return "Sama ID on jo käytössä (%s)" % error.trim_prefix("id is already used in ")
	if error.begins_with("invalid display break line"):
		return "Sanakatkoriviltä puuttuu = merkki: %s" % error.get_slice(":", 1).strip_edges()
	if error.begins_with("daily date is already used"):
		return "Daily-päivä on jo kentän käytössä: %s" % error.trim_prefix("daily date is already used by ")
	return error

func _clear_form() -> void:
	_current_index = -1
	_is_draft = false
	_populate_form(_blank_puzzle(""))

func _on_line_changed(_value: String) -> void:
	_mark_changed()

func _on_text_edit_changed() -> void:
	_mark_changed()

func _on_option_changed(_index: int) -> void:
	_mark_changed()

func _on_number_changed(_value: float) -> void:
	_mark_changed()

func _mark_changed() -> void:
	if _suspend_changes:
		return
	_set_dirty(true)
	_update_preview_and_validation()

func _set_dirty(value: bool) -> void:
	_dirty = value
	if _dirty_label != null:
		_dirty_label.text = "Tallentamattomia muutoksia" if value else "Tallennettu"
		_dirty_label.add_theme_color_override("font_color", YELLOW if value else Color("b9efd4"))
	if _revert_button != null:
		_revert_button.disabled = not value

func _status_message(message: String, is_error: bool = false) -> void:
	if _status == null:
		return
	_status.text = message
	_status.add_theme_color_override("font_color", RED if is_error else MUTED)

func _add_labeled_input(grid: GridContainer, label_text: String, placeholder: String) -> LineEdit:
	grid.add_child(_field_label(label_text))
	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_line_edit(input)
	input.text_changed.connect(_on_line_changed)
	grid.add_child(input)
	return input

func _field_label(value: String) -> Label:
	var label := _label(value, 12, MUTED, _font_body)
	label.custom_minimum_size.x = 92
	return label

func _label(value: String, font_size: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(value: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = value
	button.add_theme_font_override("font", _font_heading)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", PURPLE)
	button.add_theme_color_override("font_hover_color", PURPLE)
	button.add_theme_color_override("font_pressed_color", PURPLE)
	var fill := YELLOW if primary else SURFACE
	button.add_theme_stylebox_override("normal", _panel_style(fill, YELLOW if primary else BORDER, 13, 1, 8))
	button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.06), PURPLE if not primary else YELLOW, 13, 2, 8))
	button.add_theme_stylebox_override("pressed", _panel_style(fill.darkened(0.06), PURPLE, 13, 2, 8))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("e9e5f2"), BORDER, 13, 1, 8))
	return button

func _style_line_edit(input: LineEdit) -> void:
	input.add_theme_font_override("font", _font_body)
	input.add_theme_font_size_override("font_size", 13)
	input.add_theme_color_override("font_color", PURPLE)
	input.add_theme_color_override("font_placeholder_color", Color("aaa1c5"))
	input.add_theme_stylebox_override("normal", _panel_style(Color("fbfaff"), BORDER, 11, 1, 6))
	input.add_theme_stylebox_override("focus", _panel_style(Color.WHITE, PURPLE, 11, 2, 6))

func _style_option(option: OptionButton) -> void:
	option.add_theme_font_override("font", _font_body)
	option.add_theme_font_size_override("font_size", 12)
	option.add_theme_color_override("font_color", PURPLE)
	option.add_theme_stylebox_override("normal", _panel_style(Color("fbfaff"), BORDER, 11, 1, 6))

func _separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation", 2)
	return separator

func _panel_style(fill: Color, border: Color, radius: int, border_width: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

func _font_variation(base_font: Font, weight: int, embolden: float, width: int = 100) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = base_font
	var variations: Dictionary = {"wght": weight}
	if width != 100:
		variations[2003072104] = width
	font.variation_opentype = variations
	font.variation_embolden = embolden
	return font

func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()
