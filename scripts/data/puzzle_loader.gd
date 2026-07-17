extends Node

const PUZZLE_PATHS: Dictionary = {
	"en": {"daily": "res://data/daily_puzzles.json", "unlimited": "res://data/unlimited_puzzles.json"},
	"fi": {"daily": "res://data/daily_puzzles_fi.json", "unlimited": "res://data/unlimited_puzzles_fi.json"}
}
const DAILY_MODE: String = "daily"
const UNLIMITED_MODE: String = "unlimited"
const DIFFICULTY_METADATA_PATH: String = "res://data/puzzle_difficulty.json"
const DEFAULT_DIFFICULTY_TIER: int = 2
const DEFAULT_DIFFICULTY_RATING: int = 900
const TARGET_WIN_OFFSET: float = 170.0
const SELECTION_SIGMA: float = 85.0

var _puzzles_by_mode: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _language: String = "en"
var _difficulty_metadata: Dictionary = {}
var _difficulty_overrides: Dictionary = {}

func _ready() -> void:
	_rng.randomize()
	load_puzzles()

func load_puzzles() -> bool:
	_puzzles_by_mode.clear()
	_load_difficulty_metadata()
	_language = str(SaveManager.settings.get("language", "en"))
	if not PUZZLE_PATHS.has(_language):
		_language = "en"
	var paths: Dictionary = PUZZLE_PATHS[_language]
	var daily_loaded: bool = _load_pool(DAILY_MODE, str(paths[DAILY_MODE]))
	var unlimited_loaded: bool = _load_pool(UNLIMITED_MODE, str(paths[UNLIMITED_MODE]))
	return daily_loaded and unlimited_loaded

func set_language(language: String) -> bool:
	if not PUZZLE_PATHS.has(language):
		return false
	var previous_language: String = str(SaveManager.settings.get("language", "en"))
	SaveManager.settings["language"] = language
	if not load_puzzles():
		SaveManager.settings["language"] = previous_language
		load_puzzles()
		return false
	SaveManager.save_data()
	return true

func get_language() -> String:
	return _language

func _load_pool(mode: String, path: String) -> bool:
	var puzzles: Array[Dictionary] = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open %s puzzle data: %s" % [mode, path])
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary) or not parsed.has("puzzles") or not (parsed["puzzles"] is Array):
		push_error("%s puzzle data has an invalid root format." % mode)
		return false
	var schedule: Dictionary = parsed.get("schedule", {}) as Dictionary
	for candidate: Variant in parsed["puzzles"]:
		if candidate is Dictionary:
			var puzzle_data: Dictionary = candidate.duplicate(true)
			_apply_difficulty_metadata(puzzle_data)
			var scheduled_date: String = str(schedule.get(str(puzzle_data.get("id", "")), ""))
			if not scheduled_date.is_empty():
				puzzle_data["date"] = scheduled_date
			var errors: PackedStringArray = validate_puzzle(puzzle_data)
			if errors.is_empty():
				puzzles.append(puzzle_data)
			else:
				push_error("Invalid puzzle '%s': %s" % [str(candidate.get("id", "unknown")), "; ".join(errors)])
	if puzzles.is_empty():
		push_error("No valid %s puzzles were loaded." % mode)
		return false
	_puzzles_by_mode[mode] = puzzles
	return true

func get_random_puzzle(mode: String, exclude_id: String = "") -> Dictionary:
	var pool: Array[Dictionary] = get_puzzles(mode)
	var choices: Array[Dictionary] = []
	for puzzle: Dictionary in pool:
		if puzzle.get("id", "") != exclude_id or pool.size() == 1:
			choices.append(puzzle)
	if choices.is_empty():
		return {}
	return choices[_rng.randi_range(0, choices.size() - 1)].duplicate(true)

func get_daily_puzzle(date_key: String) -> Dictionary:
	var pool: Array[Dictionary] = get_puzzles(DAILY_MODE)
	if pool.is_empty():
		return {}
	for puzzle: Dictionary in pool:
		if str(puzzle.get("date", "")) == date_key:
			return puzzle.duplicate(true)
	# Daily entries are authored in chronological ID order. This also covers a
	# newly appended entry before its optional schedule map is updated.
	var epoch: int = Time.get_unix_time_from_datetime_string("2026-07-12T00:00:00")
	var requested: int = Time.get_unix_time_from_datetime_string("%sT00:00:00" % date_key)
	var offset: int = int((requested - epoch) / 86400.0)
	if offset >= 0 and offset < pool.size():
		return pool[offset].duplicate(true)
	var parts: PackedStringArray = date_key.split("-")
	if parts.size() != 3:
		return get_random_puzzle(DAILY_MODE)
	var day_number: int = int(parts[0]) * 372 + int(parts[1]) * 31 + int(parts[2])
	return pool[posmod(day_number, pool.size())].duplicate(true)

func get_next_unplayed_puzzle(mode: String, played_ids: Array[String]) -> Dictionary:
	var choices: Array[Dictionary] = []
	for puzzle: Dictionary in get_puzzles(mode):
		if not played_ids.has(str(puzzle.get("id", ""))):
			choices.append(puzzle)
	if choices.is_empty():
		return {}
	return choices[_rng.randi_range(0, choices.size() - 1)].duplicate(true)

func get_next_unplayed_puzzle_for_skill(mode: String, played_ids: Array[String], player_rating: float, rated_games: int) -> Dictionary:
	var choices: Array[Dictionary] = []
	for puzzle: Dictionary in get_puzzles(mode):
		if not played_ids.has(str(puzzle.get("id", ""))):
			choices.append(puzzle)
	if choices.is_empty():
		return {}
	# The first five rated games deliberately climb through the easier part of
	# the pool. Afterwards, target roughly a 72% expected win rate.
	var target_rating: float = 780.0 + float(rated_games) * 35.0 if rated_games < 5 else player_rating - TARGET_WIN_OFFSET
	var weights: Array[float] = []
	var total_weight: float = 0.0
	for candidate: Dictionary in choices:
		var difference: float = float(get_effective_difficulty_rating(candidate)) - target_rating
		var weight: float = maxf(exp(-(difference * difference) / (2.0 * SELECTION_SIGMA * SELECTION_SIGMA)), 0.001)
		weights.append(weight)
		total_weight += weight
	var roll: float = _rng.randf() * total_weight
	for index: int in choices.size():
		roll -= weights[index]
		if roll <= 0.0:
			return choices[index].duplicate(true)
	return choices.back().duplicate(true)

func get_effective_difficulty_rating(puzzle: Dictionary) -> int:
	var puzzle_id: String = str(puzzle.get("id", ""))
	if _difficulty_overrides.has(puzzle_id):
		return clampi(int(_difficulty_overrides[puzzle_id]), 500, 1600)
	return clampi(int(puzzle.get("difficulty_rating", DEFAULT_DIFFICULTY_RATING)), 500, 1600)

func get_difficulty_tier(puzzle: Dictionary) -> int:
	return clampi(int(puzzle.get("difficulty", DEFAULT_DIFFICULTY_TIER)), 1, 5)

func set_difficulty_overrides(ratings_by_puzzle_id: Dictionary) -> void:
	# Future backend integration can feed population-adjusted ratings through
	# this seam. Local metadata remains the fallback and is never overwritten.
	_difficulty_overrides.clear()
	for puzzle_id: Variant in ratings_by_puzzle_id:
		_difficulty_overrides[str(puzzle_id)] = clampi(int(ratings_by_puzzle_id[puzzle_id]), 500, 1600)

func clear_difficulty_overrides() -> void:
	_difficulty_overrides.clear()

func get_puzzles(mode: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var pool_value: Variant = _puzzles_by_mode.get(mode, [])
	if pool_value is Array:
		for puzzle_value: Variant in pool_value:
			if puzzle_value is Dictionary:
				result.append(puzzle_value)
	return result

func validate_puzzle(puzzle: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	var expected_sizes: Array[int] = [2, 3, 4, 5]
	if str(puzzle.get("id", "")).is_empty():
		errors.append("missing id")
	if str(puzzle.get("top_word", "")).strip_edges().is_empty():
		errors.append("missing top word")
	if not (puzzle.get("groups", null) is Array):
		errors.append("groups must be an array")
		return errors
	var groups: Array = puzzle["groups"]
	if groups.size() != 4:
		errors.append("requires exactly four groups")
	var found_sizes: Array[int] = []
	var all_words: Dictionary = {}
	for group_value: Variant in groups:
		if not group_value is Dictionary:
			errors.append("each group must be an object")
			continue
		var group: Dictionary = group_value
		var words: Variant = group.get("words", [])
		var declared_size: int = int(group.get("size", 0))
		found_sizes.append(declared_size)
		if not (words is Array) or words.size() != declared_size:
			errors.append("group size does not match its words")
			continue
		if str(group.get("label", "")).strip_edges().is_empty():
			errors.append("group missing label")
		for word_value: Variant in words:
			var word: String = str(word_value).strip_edges().to_upper()
			if word.is_empty() or all_words.has(word):
				errors.append("words must be non-empty and unique")
			all_words[word] = true
	found_sizes.sort()
	if found_sizes != expected_sizes:
		errors.append("group sizes must be 2, 3, 4 and 5")
	if all_words.size() != 14:
		errors.append("groups must contain 14 unique words")
	if all_words.has(str(puzzle.get("top_word", "")).to_upper()):
		errors.append("top word must not occur in a group")
	var difficulty_tier: int = int(puzzle.get("difficulty", 0))
	var difficulty_rating: int = int(puzzle.get("difficulty_rating", 0))
	if difficulty_tier < 1 or difficulty_tier > 5:
		errors.append("difficulty must be between 1 and 5")
	if difficulty_rating < 500 or difficulty_rating > 1600:
		errors.append("difficulty_rating must be between 500 and 1600")
	var display_breaks_value: Variant = puzzle.get("display_breaks", {})
	if not (display_breaks_value is Dictionary):
		errors.append("display_breaks must be an object")
	else:
		var display_breaks: Dictionary = display_breaks_value
		var top_word: String = str(puzzle.get("top_word", "")).strip_edges().to_upper()
		for word_value: Variant in display_breaks:
			var word: String = str(word_value).strip_edges().to_upper()
			var display: String = str(display_breaks[word_value]).strip_edges()
			if not all_words.has(word) and word != top_word:
				errors.append("display_breaks references an unknown word: %s" % word)
			elif display.is_empty() or _compact_display_word(display) != _compact_display_word(word):
				errors.append("display_breaks must only add whitespace to: %s" % word)
	return errors

func _compact_display_word(word: String) -> String:
	return word.to_upper().replace(" ", "").replace("\n", "").replace("\r", "").replace("\t", "")

func _load_difficulty_metadata() -> void:
	_difficulty_metadata.clear()
	var file: FileAccess = FileAccess.open(DIFFICULTY_METADATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("Could not open puzzle difficulty metadata; using defaults.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and (parsed as Dictionary).get("puzzles", null) is Dictionary:
		_difficulty_metadata = ((parsed as Dictionary)["puzzles"] as Dictionary).duplicate(true)
	else:
		push_warning("Puzzle difficulty metadata has an invalid format; using defaults.")

func _apply_difficulty_metadata(puzzle: Dictionary) -> void:
	var puzzle_id: String = str(puzzle.get("id", ""))
	var metadata_value: Variant = _difficulty_metadata.get(puzzle_id, {})
	var metadata: Dictionary = metadata_value if metadata_value is Dictionary else {}
	puzzle["difficulty"] = clampi(int(metadata.get("tier", DEFAULT_DIFFICULTY_TIER)), 1, 5)
	puzzle["difficulty_rating"] = clampi(int(metadata.get("rating", DEFAULT_DIFFICULTY_RATING)), 500, 1600)
	puzzle["difficulty_source"] = "local_metadata" if not metadata.is_empty() else "default"
