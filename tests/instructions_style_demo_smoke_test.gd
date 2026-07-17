extends Node

const DEMO_SCENE: PackedScene = preload("res://scenes/instructions_style_demo.tscn")
const GAME_BOARD_SCENE: PackedScene = preload("res://scenes/game_board.tscn")
const PHONE_SIZE := Vector2i(390, 844)

func _ready() -> void:
	get_tree().root.size = PHONE_SIZE
	var original_language: String = str(SaveManager.settings.get("language", "en"))
	for language: String in ["en", "fi"]:
		SaveManager.settings["language"] = language
		var demo: InstructionsStyleDemo = DEMO_SCENE.instantiate() as InstructionsStyleDemo
		get_tree().root.add_child.call_deferred(demo)
		await get_tree().process_frame
		await get_tree().process_frame
		var page: VBoxContainer = demo.find_child("VariantPage", true, false) as VBoxContainer
		assert(page != null, "Selected instructions design has no page")
		assert(page.get_combined_minimum_size().x <= 362.0, "Instructions overflow phone width in %s" % language)
		assert(page.get_combined_minimum_size().y <= 817.0, "Instructions overflow phone height in %s" % language)
		var back: Button = demo.find_child("BackToGame", true, false) as Button
		assert(back != null and back.visible, "Instructions have no return button")
		assert(_has_label_fragment(demo, SaveManager.text("instructions_choose_top")), "Instructions do not say rows can be solved in any order")
		assert(demo.find_children("StepCard_*", "", true, false).size() == 3, "Instructions do not have exactly three clear steps")
		assert(demo.find_child("WordPoolExample", true, false) != null, "Instructions lack a concrete word example")
		var hint_callout: PanelContainer = demo.find_child("HintCallout", true, false) as PanelContainer
		var hint_action: Button = demo.find_child("HintAction", true, false) as Button
		assert(hint_callout != null and hint_action != null, "Hint callout does not contain its showcase button")
		assert(hint_callout.is_ancestor_of(hint_action), "Hint showcase is not attached to the Hint element")
		assert(hint_action.icon != null, "Hint showcase has no lightbulb icon")
		var expected_hints: int = maxi(int(GameState.call("_get_hint_limit")) - GameState.hints_used, 0)
		assert(hint_action.text == SaveManager.text("hint_count") % expected_hints, "Hint showcase does not display the number of hints")
		assert(hint_action.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Hint showcase must not be interactive")
		demo.queue_free()
		await get_tree().process_frame

	SaveManager.settings["language"] = original_language
	assert(GameState.start_tutorial(), "Tutorial puzzle is available for Hint integration testing")
	var board: GameBoard = GAME_BOARD_SCENE.instantiate() as GameBoard
	get_tree().root.add_child.call_deferred(board)
	await get_tree().process_frame
	board.call("_show_instructions")
	await get_tree().process_frame
	var overlay: InstructionsStyleDemo = board.find_child("InstructionsStyleDemo", true, false) as InstructionsStyleDemo
	assert(overlay != null, "Instructions button does not open the selected menu")
	var showcased_hint: Button = overlay.find_child("HintAction", true, false) as Button
	assert(showcased_hint != null and showcased_hint.icon != null, "Game instructions are missing the lightbulb Hint showcase")
	var hints_before: int = GameState.hints_used
	showcased_hint.pressed.emit()
	await get_tree().process_frame
	assert(GameState.hints_used == hints_before, "Showcase Hint button must not use a real hint")
	assert(board.find_child("InstructionsStyleDemo", true, false) != null, "Showcase Hint button unexpectedly closes Instructions")
	overlay.dismiss_requested.emit()
	await get_tree().process_frame
	assert(board.find_child("InstructionsStyleDemo", true, false) == null, "Instructions menu does not return to the game")
	var gameplay_hint: Button = board.get("_hint") as Button
	assert(gameplay_hint != null and gameplay_hint.icon != null, "Gameplay Hint button has no lightbulb icon")
	assert(gameplay_hint.text.contains(str(maxi(int(GameState.call("_get_hint_limit")) - GameState.hints_used, 0))), "Gameplay Hint button does not show the hint count")

	print("INSTRUCTIONS_STYLE_DEMO_SMOKE_TEST_PASS")
	board.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _has_label_fragment(root: Node, fragment: String) -> bool:
	for node: Node in root.find_children("*", "Label", true, false):
		var label: Label = node as Label
		if label != null and label.text.contains(fragment):
			return true
	return false
