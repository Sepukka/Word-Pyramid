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
		for variant_index: int in 3:
			demo.call("_show_variant", variant_index)
			await get_tree().process_frame
			await get_tree().process_frame
			var page: VBoxContainer = demo.find_child("VariantPage", true, false) as VBoxContainer
			assert(page != null, "Instructions variant %d has no page" % variant_index)
			assert(page.get_combined_minimum_size().x <= 362.0, "Instructions variant %d overflows phone width in %s" % [variant_index, language])
			assert(page.get_combined_minimum_size().y <= 758.0, "Instructions variant %d overflows phone height in %s" % [variant_index, language])
			var back: Button = demo.find_child("BackToGame", true, false) as Button
			assert(back != null and back.visible, "Instructions variant %d has no return button" % variant_index)
			assert(_has_label_fragment(demo, SaveManager.text("instructions_choose_top")), "Instructions variant %d does not say rows can be solved in any order" % variant_index)
			if variant_index < 2:
				assert(demo.find_child("WordPoolExample", true, false) != null, "Instructions variant %d lacks a concrete word example" % variant_index)
			else:
				assert(demo.find_child("LabeledPyramid", true, false) != null, "Quick-reference variant lacks the labeled pyramid")
		demo.queue_free()
		await get_tree().process_frame

	SaveManager.settings["language"] = original_language
	var board: GameBoard = GAME_BOARD_SCENE.instantiate() as GameBoard
	get_tree().root.add_child.call_deferred(board)
	await get_tree().process_frame
	board.call("_show_instructions")
	await get_tree().process_frame
	var overlay: InstructionsStyleDemo = board.find_child("InstructionsStyleDemo", true, false) as InstructionsStyleDemo
	assert(overlay != null, "Instructions button does not open the comparison menu")
	overlay.dismiss_requested.emit()
	await get_tree().process_frame
	assert(board.find_child("InstructionsStyleDemo", true, false) == null, "Instructions menu does not return to the game")

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
