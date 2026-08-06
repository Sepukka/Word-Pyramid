extends Node

const PALETTE = preload("res://scripts/ui/ui_palette.gd")
const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")


func _ready() -> void:
	assert(PALETTE.PRIMARY != PALETTE.ACCENT, "Selection and primary action colors must remain distinct")
	assert(PALETTE.PRIMARY != PALETTE.ERROR, "Selection and error colors must remain distinct")
	assert(_contrast_ratio(PALETTE.MUTED_TEXT, PALETTE.BACKGROUND) >= 4.5, "Essential muted text needs WCAG AA contrast")

	var board: GameBoard = GAME_BOARD_SCENE.instantiate() as GameBoard
	add_child(board)
	await get_tree().process_frame

	var selected_style: StyleBoxFlat = board.call("_selected_tile_style") as StyleBoxFlat
	assert(selected_style.bg_color == PALETTE.PRIMARY, "Selected words must use the brand primary surface")
	assert(selected_style.border_color == PALETTE.PRIMARY, "Selected words must not use the yellow action outline")

	var tile := Button.new()
	board.call("_apply_word_tile_visual", tile, true, false)
	assert(tile.get_theme_color("font_color") == Color.WHITE, "Selected words need white text")

	board.call("_apply_word_tile_visual", tile, false, true)
	var wrong_style: StyleBoxFlat = tile.get_theme_stylebox("normal") as StyleBoxFlat
	assert(wrong_style.bg_color == PALETTE.ERROR_BACKGROUND, "Wrong words need the semantic error tint")
	assert(wrong_style.border_color == PALETTE.ERROR, "Wrong words need the semantic error border")

	assert(board.call("_row_text", 2) == PALETTE.TEXT, "Coral solved tiles need readable navy text")
	assert(board.call("_row_text", 3) == PALETTE.TEXT, "Teal solved tiles need readable navy text")

	print("UI_COLOR_SEMANTICS_SMOKE_TEST_PASS")
	get_tree().quit()


func _contrast_ratio(foreground: Color, background: Color) -> float:
	var lighter: float = maxf(_relative_luminance(foreground), _relative_luminance(background))
	var darker: float = minf(_relative_luminance(foreground), _relative_luminance(background))
	return (lighter + 0.05) / (darker + 0.05)


func _relative_luminance(color: Color) -> float:
	return (
		0.2126 * _linear_channel(color.r)
		+ 0.7152 * _linear_channel(color.g)
		+ 0.0722 * _linear_channel(color.b)
	)


func _linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)
