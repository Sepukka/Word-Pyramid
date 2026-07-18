extends Node

func _ready() -> void:
	SaveManager.save_path = "res://.godot-test-data/share_pyramid_save.json"
	SaveManager.reset_to_defaults()
	PuzzleLoader.set_language("fi")
	var puzzles: Array[Dictionary] = PuzzleLoader.get_puzzles(GameState.DAILY_MODE)
	assert(not puzzles.is_empty(), "Share pyramid test needs a puzzle")
	GameState.puzzle = puzzles[0].duplicate(true)
	GameState.game_mode = GameState.DAILY_MODE
	GameState.daily_date = "2026-07-18"
	GameState.result_top_solved = true
	GameState.result_solved_groups.clear()
	for index: int in GameState.puzzle.get("groups", []).size():
		var row_length: int = int(GameState.puzzle["groups"][index].get("size", 0))
		if row_length == 2 or row_length == 4:
			GameState.result_solved_groups.append(index)
	GameState.attempts_left = 2
	GameState.hints_used = 1

	var finnish_share: String = GameState.build_share_text()
	var finnish_lines: PackedStringArray = finnish_share.split("\n")
	assert(finnish_lines[0] == "Word Pyramid · Päivän haaste", "Finnish share identifies the Daily mode")
	assert(finnish_lines[1] == "2026-07-18", "Daily share includes its puzzle date")
	assert(finnish_lines[3] == "    🟪", "Solved top row is centered and purple")
	assert(finnish_lines[4] == "   🟥🟥", "Solved two-word row is centered and red")
	assert(finnish_lines[5] == "  ⬜⬜⬜", "Missed three-word row keeps its three blank blocks")
	assert(finnish_lines[6] == " 🟩🟩🟩🟩", "Solved four-word row keeps its four blocks")
	assert(finnish_lines[7] == "⬜⬜⬜⬜⬜", "Missed five-word row keeps its five blank blocks")
	assert(finnish_lines[9] == "Rivit 3/5 · Virheet 2 · Vihjeet 1", "Finnish share summarizes rows, mistakes, and hints")
	assert(finnish_lines[10].begins_with("🔥 Putki "), "Finnish Daily share includes the streak")

	PuzzleLoader.set_language("en")
	GameState.game_mode = GameState.UNLIMITED_MODE
	var unlimited_share: String = GameState.build_share_text()
	assert(unlimited_share.begins_with("Word Pyramid · Infinity\n\n"), "English Infinity share uses its mode header without a Daily date")
	assert(not unlimited_share.contains("2026-07-18"), "Infinity share does not include the Daily date")
	assert(not unlimited_share.contains("Streak"), "Infinity share does not include the Daily streak")
	assert(unlimited_share.contains("Rows 3/5 · Mistakes 2 · Hints 1"), "English Infinity share includes its compact result summary")

	print("SHARE_PYRAMID_SMOKE_TEST_PASS")
	get_tree().quit()
