extends Node

const DEFAULT_SETTINGS: Dictionary = {"attempts": 4, "sound_enabled": true, "language": "en"}

var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var statistics: Dictionary = {"wins": 0, "losses": 0, "streak": 0, "best_streak": 0}
var active_game: Dictionary = {}
var daily_results: Dictionary = {}
var played_puzzle_ids: Dictionary = {"daily": [], "unlimited": []}

func _ready() -> void:
	# Word Pyramid deliberately runs as a fresh session every time the project
	# starts. Nothing is restored from user:// or written there.
	reset_to_defaults()

func load_data() -> void:
	reset_to_defaults()

func reset_to_defaults() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)
	statistics = {"wins": 0, "losses": 0, "streak": 0, "best_streak": 0}
	active_game = {}
	daily_results = {}
	played_puzzle_ids = {"daily": [], "unlimited": []}

func save_data() -> void:
	# Kept as a compatibility entry point for gameplay code. State remains
	# available while this run is open, but is never persisted to disk.
	pass

func record_result(won: bool, day_key: String = "") -> void:
	if won:
		statistics["wins"] = int(statistics.get("wins", 0)) + 1
		statistics["streak"] = int(statistics.get("streak", 0)) + 1
		statistics["best_streak"] = max(int(statistics.get("best_streak", 0)), int(statistics["streak"]))
	else:
		statistics["losses"] = int(statistics.get("losses", 0)) + 1
		statistics["streak"] = 0
	if not day_key.is_empty():
		daily_results[day_key] = {"won": won}
	save_data()

func get_played_puzzle_ids(mode: String) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in played_puzzle_ids.get(mode, []):
		result.append(str(value))
	return result

func record_puzzle_played(mode: String, puzzle_id: String) -> void:
	if puzzle_id.is_empty():
		return
	var ids: Array[String] = get_played_puzzle_ids(mode)
	if not ids.has(puzzle_id):
		ids.append(puzzle_id)
		played_puzzle_ids[mode] = ids
		save_data()
