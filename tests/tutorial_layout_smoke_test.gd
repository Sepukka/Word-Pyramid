extends Node

const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")
const PHONE_SIZE := Vector2i(390, 844)

func _ready() -> void:
	get_tree().root.size = PHONE_SIZE
	_assert(GameState.start_tutorial(), "tutorial starts")
	var board: GameBoard = GAME_BOARD_SCENE.instantiate() as GameBoard
	get_tree().root.add_child.call_deferred(board)
	await get_tree().process_frame
	board.refresh()
	await get_tree().process_frame

	var card: PanelContainer = board.get("_card") as PanelContainer
	var pyramid: VBoxContainer = board.get("_pyramid") as VBoxContainer
	var check_button: Button = board.get("_check") as Button
	_assert(card != null and pyramid != null and check_button != null, "tutorial layout is built")
	_assert(card.get_global_rect().end.x <= PHONE_SIZE.x + 0.5, "tutorial card fits the phone width")
	_assert(card.get_global_rect().end.y <= PHONE_SIZE.y + 0.5, "tutorial card fits the phone height")
	_assert(check_button.get_global_rect().end.y <= PHONE_SIZE.y + 0.5, "tutorial controls remain on screen")
	var word_buttons: Dictionary = board.get("_word_buttons") as Dictionary
	_assert(not word_buttons.is_empty(), "tutorial word tiles are created")
	var first_tile: Button = word_buttons.values()[0] as Button
	_assert(first_tile.size.y <= 80.0, "tutorial guide space is deducted from the pyramid")

	print("TUTORIAL_LAYOUT_SMOKE_TEST_PASS")
	board.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _assert(condition: bool, description: String) -> void:
	if condition:
		return
	push_error("Tutorial layout smoke test failed: %s" % description)
	get_tree().quit(1)
