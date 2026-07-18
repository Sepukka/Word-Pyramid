extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

func _ready() -> void:
	SaveManager.save_path = "res://.godot-test-data/unlimited_pool_completion_save.json"
	SaveManager.reset_to_defaults()
	SaveManager.onboarding = {"version": SaveManager.ONBOARDING_VERSION, "language_selected": true}
	assert(PuzzleLoader.set_language("fi"), "Pool completion test could not load Finnish puzzles")
	var puzzles: Array[Dictionary] = PuzzleLoader.get_puzzles(GameState.UNLIMITED_MODE)
	assert(puzzles.size() > 1, "Pool completion test needs multiple Infinity puzzles")
	var progress_key: String = "%s:%s" % [PuzzleLoader.get_language(), GameState.UNLIMITED_MODE]
	var all_ids: Array[String] = []
	for puzzle: Dictionary in puzzles:
		all_ids.append(str(puzzle.get("id", "")))
	SaveManager.replace_played_puzzle_ids(progress_key, all_ids)

	assert(GameState.is_puzzle_pool_completed(GameState.UNLIMITED_MODE), "All authored Infinity IDs should complete the current pool")
	var completion_emitted: Array[String] = []
	GameState.puzzle_pool_completed.connect(func(mode: String) -> void: completion_emitted.append(mode))
	GameState.puzzle = {}
	assert(not GameState.start_new_game(GameState.UNLIMITED_MODE), "A completed Infinity pool must not silently recycle")
	assert(completion_emitted.has(GameState.UNLIMITED_MODE), "Starting a completed pool must report its completion")
	assert(SaveManager.get_played_puzzle_ids(progress_key) == all_ids, "Completed IDs must remain saved instead of being reset")

	var main: Control = MAIN_SCENE.instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var unlimited_button: Button = main.get_node("HomeLayer/Content/ModeButtons/UnlimitedCard/CardMargin/CardContent/UnlimitedButton") as Button
	var completion_label: Label = main.get_node("HomeLayer/Content/ModeButtons/UnlimitedCard/CardMargin/CardContent/EndlessStatus/HeartLabel") as Label
	assert(unlimited_button.disabled and unlimited_button.text == SaveManager.text("all_played"), "Home must disable Infinity after every current puzzle")
	assert(completion_label.text == SaveManager.text("unlimited_pool_complete_body"), "Home must explain that updates add more puzzles")

	# This simulates an app update adding a puzzle ID that is not present in the
	# player's old save: one current ID is now absent from the saved history.
	var newly_added_id: String = all_ids.back()
	var old_save_ids: Array[String] = all_ids.duplicate()
	old_save_ids.erase(newly_added_id)
	SaveManager.replace_played_puzzle_ids(progress_key, old_save_ids)
	assert(GameState.has_unplayed_puzzles(GameState.UNLIMITED_MODE), "A new puzzle ID must automatically reopen Infinity")
	main.call("_apply_home_texts")
	assert(not unlimited_button.disabled, "Home must automatically enable Infinity when an update adds a puzzle")
	assert(GameState.start_new_game(GameState.UNLIMITED_MODE), "The newly added puzzle must be playable without resetting progress")
	assert(str(GameState.puzzle.get("id", "")) == newly_added_id, "Only the newly added puzzle should be selected")

	print("Unlimited pool completion smoke test passed")
	main.queue_free()
	await get_tree().process_frame
	get_tree().quit()
