extends Node

const DEFAULT_SETTINGS: Dictionary = {"attempts": 4, "sound_enabled": true, "language": "en"}
const SAVE_PATH: String = "user://word_pyramid_save.json"
const TEXT: Dictionary = {
	"en": {
		"settings": "Settings",
		"daily_button": "Daily\nToday's challenge",
		"view_result": "View result",
		"unlimited_button": "Infinity Mode",
		"all_played": "All played",
		"all_played_daily": "All played\nDaily challenges",
		"daily_pool": "daily challenges",
		"unlimited_pool": "unlimited challenges",
		"daily_challenge_label": "Daily Challenge",
		"unlimited_mode_label": "Infinity Mode",
		"home_subtitle": "Daily word challenge",
		"home_daily_title": "Around the Kitchen",
		"home_card_meta": "Food & Cooking · 15 words · 4 categories",
		"home_streak": "%d-day streak",
		"home_hint_markup": "Build a [b][color=#1A0A5E]15-word[/color][/b] pyramid — any order.\nYou get [b][color=#1A0A5E]2 hints[/color][/b] and [b][color=#1A0A5E]4 lives[/color][/b] before the pyramid falls.",
		"pool_complete": "Congratulations! You have played all %s.",
		"statistics_title": "Statistics",
		"statistics_subtitle": "Your Word Pyramid record",
		"settings_title": "Settings",
		"settings_subtitle": "Personalize the challenge",
		"language": "Language",
		"attempts_per_puzzle": "Attempts per puzzle",
		"sound_effects": "Sound effects",
		"settings_note": "New attempt settings are applied when a new puzzle starts.",
		"debug_reset_progress": "Debug: Reset all progress",
		"debug_reset_confirm": "Tap again to reset everything",
		"back": "Back",
		"wins": "Wins",
		"losses": "Losses",
		"win_rate": "Win rate",
		"current_streak": "Current streak",
		"best_streak": "Best streak",
		"result_score": "Result: %d/%d",
		"share_result": "Share",
		"result_copied": "Result copied.",
		"share_daily_result": "Word Pyramid %s\nResult: %d/%d\nStreak: %d",
		"aftermath_win_title": "Pyramid Complete!",
		"aftermath_loss_title": "Pyramid Fell!",
		"aftermath_flawless": "Flawless solve - no mistakes!",
		"aftermath_solved_mistakes": "Solved with %d mistakes",
		"aftermath_loss_subtitle": "%d/%d correct - better luck tomorrow",
		"aftermath_results": "Results",
		"aftermath_streak_current": "%d day streak",
		"aftermath_streak": "%d → %d day streak",
		"aftermath_streak_lost": "Streak lost",
		"stat_mistakes": "Mistakes",
		"stat_groups": "Groups",
		"stat_hints_used": "Hints used",
		"instructions": "Instructions",
		"board_title": "Select related words",
		"daily_message": "Daily challenge · find words that belong together.",
		"hint": "Hint",
		"clear": "Clear",
		"check": "Check",
		"new_game": "New game",
		"menu": "Menu",
		"select_tooltip": "Select %s",
		"hint_tooltip": "Hint: locked into the correct row",
		"mistakes_left": "Mistakes left: %d / %d",
		"selected": "Selected: %s",
		"select_words": "Select 1-5 words to check",
		"hint_count": "Hint %d",
		"hint_zero": "Hint 0",
		"bonus_hint": "Bonus hint",
		"ad_hint": "Ad +1",
		"game_complete": "Pyramid complete - top word: %s",
		"game_failed": "No attempts left - showing the solution.",
		"guess_failed": "These words do not form a group. Try again.",
		"repeated_guess": "You already tried this combination.",
		"missing_word": "One word is missing.",
		"extra_word": "One word too many.",
		"unlimited_hint_limit": "Unlimited mode has two hints per puzzle.",
		"hint_placed": "Hint: %s was placed into the correct row.",
		"bonus_hint_earned": "Bonus hint earned! Use the Hint button.",
		"rewarded_hint_required": "Two free hints have been used. Watch a rewarded ad to get a bonus hint.",
		"rewarded_ad_unavailable": "Rewarded ads are available only in Android or iOS test builds.",
		"rewarded_ad_loading": "The ad is loading. It will open shortly.",
		"rewarded_ad_failed": "The ad could not be loaded: %s",
		"instructions_text": "Find groups of 2, 3, 4 and 5 words, then guess the top word with one selection."
	},
	"fi": {
		"settings": "Asetukset",
		"daily_button": "Päivän haaste\nTämän päivän pulma",
		"view_result": "Näytä tulos",
		"unlimited_button": "Ääretön peli",
		"all_played": "Kaikki pelattu",
		"all_played_daily": "Kaikki pelattu\nPäivittäiset haasteet",
		"daily_pool": "päivittäiset haasteet",
		"unlimited_pool": "rajattomat haasteet",
		"daily_challenge_label": "Päivän haaste",
		"unlimited_mode_label": "Ääretön peli",
		"home_subtitle": "Päivän sanahaaste",
		"home_daily_title": "Keittiön äärellä",
		"home_card_meta": "Ruoka ja kokkaus · 15 sanaa · 4 kategoriaa",
		"home_streak": "%d päivän putki",
		"home_hint_markup": "Rakenna [b][color=#1A0A5E]15 sanan[/color][/b] pyramidi — missä järjestyksessä tahansa.\nSaat [b][color=#1A0A5E]2 vihjettä[/color][/b] ja [b][color=#1A0A5E]4 elämää[/color][/b] ennen kuin pyramidi kaatuu.",
		"pool_complete": "Onneksi olkoon! Olet pelannut kaikki %s.",
		"statistics_title": "Tilastot",
		"statistics_subtitle": "Word Pyramid -tuloksesi",
		"settings_title": "Asetukset",
		"settings_subtitle": "Muokkaa haastetta",
		"language": "Kieli",
		"attempts_per_puzzle": "Yrityksiä per pulma",
		"sound_effects": "Äänitehosteet",
		"settings_note": "Uusi yritysmäärä tulee käyttöön, kun uusi pulma alkaa.",
		"debug_reset_progress": "Debug: Nollaa kaikki edistyminen",
		"debug_reset_confirm": "Nollaa kaikki napauttamalla uudelleen",
		"back": "Takaisin",
		"wins": "Voitot",
		"losses": "Tappiot",
		"win_rate": "Voittoprosentti",
		"current_streak": "Nykyinen putki",
		"best_streak": "Paras putki",
		"result_score": "Tulos: %d/%d",
		"share_result": "Jaa",
		"result_copied": "Tulos kopioitu.",
		"share_daily_result": "Word Pyramid %s\nTulos: %d/%d\nPutki: %d",
		"aftermath_win_title": "Pyramidi valmis!",
		"aftermath_loss_title": "Pyramidi kaatui!",
		"aftermath_flawless": "Täydellinen ratkaisu - ei virheitä!",
		"aftermath_solved_mistakes": "Ratkaistu %d virheellä",
		"aftermath_loss_subtitle": "%d/%d oikein - huomenna uudestaan",
		"aftermath_results": "Tulokset",
		"aftermath_streak_current": "%d päivän putki",
		"aftermath_streak": "%d → %d päivän putki",
		"aftermath_streak_lost": "Putki katkesi",
		"stat_mistakes": "Virheet",
		"stat_groups": "Ryhmät",
		"stat_hints_used": "Vihjeet",
		"instructions": "Ohjeet",
		"board_title": "Valitse yhteen kuuluvat sanat",
		"daily_message": "Päivän haaste · etsi samaan ryhmään kuuluvat sanat.",
		"hint": "Vihje",
		"clear": "Tyhjennä",
		"check": "Tarkista",
		"new_game": "Uusi peli",
		"menu": "Valikko",
		"select_tooltip": "Valitse %s",
		"hint_tooltip": "Vihje: lukittu oikealle riville",
		"mistakes_left": "Virheitä jäljellä: %d / %d",
		"selected": "Valitut: %s",
		"select_words": "Valitse 1-5 sanaa tarkistettavaksi",
		"hint_count": "Vihje %d",
		"hint_zero": "Vihje 0",
		"bonus_hint": "Bonusvihje",
		"ad_hint": "Mainos +1",
		"game_complete": "Pyramidi valmis - huippusana: %s",
		"game_failed": "Virheet loppuivat - ratkaisu näytetään.",
		"guess_failed": "Nämä sanat eivät muodosta ryhmää. Kokeile uudelleen.",
		"repeated_guess": "Olet jo kokeillut tätä yhdistelmää.",
		"missing_word": "Yksi sana puuttuu.",
		"extra_word": "Yksi sana liikaa.",
		"unlimited_hint_limit": "Rajattomassa pelissä on kaksi vihjettä per pulma.",
		"hint_placed": "Vihje: %s sijoitettiin oikealle riville.",
		"bonus_hint_earned": "Bonusvihje ansaittu! Käytä Vihje-painiketta.",
		"rewarded_hint_required": "Kaksi maksutonta vihjettä on käytetty. Katso palkittu mainos saadaksesi bonusvihjeen.",
		"rewarded_ad_unavailable": "Palkitut mainokset toimivat vain Android- tai iOS-testiversiossa.",
		"rewarded_ad_loading": "Mainosta ladataan. Se avautuu hetken kuluttua.",
		"rewarded_ad_failed": "Mainosta ei saatu ladattua: %s",
		"instructions_text": "Etsi 2, 3, 4 ja 5 sanan ryhmät sekä arvaa huippusana yhdellä valinnalla."
	}
}

var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var statistics: Dictionary = {"wins": 0, "losses": 0, "streak": 0, "best_streak": 0}
var active_game: Dictionary = {}
var daily_results: Dictionary = {}
var played_puzzle_ids: Dictionary = {"daily": [], "unlimited": []}

func _ready() -> void:
	load_data()

func load_data() -> void:
	reset_to_defaults()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	var saved: Dictionary = parsed
	_merge_settings(saved.get("settings", {}))
	statistics = _merge_dictionary(statistics, saved.get("statistics", {}))
	active_game = _dictionary_or_empty(saved.get("active_game", {}))
	daily_results = _dictionary_or_empty(saved.get("daily_results", {}))
	played_puzzle_ids = _merge_dictionary(played_puzzle_ids, saved.get("played_puzzle_ids", {}))

func reset_to_defaults() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)
	statistics = {"wins": 0, "losses": 0, "streak": 0, "best_streak": 0}
	active_game = {}
	daily_results = {}
	played_puzzle_ids = {"daily": [], "unlimited": []}

func reset_all_data() -> void:
	reset_to_defaults()
	save_data()

func save_data() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save data to %s" % SAVE_PATH)
		return
	var data: Dictionary = {
		"settings": settings,
		"statistics": statistics,
		"active_game": active_game,
		"daily_results": daily_results,
		"played_puzzle_ids": played_puzzle_ids
	}
	file.store_string(JSON.stringify(data))

func text(key: String) -> String:
	var language: String = str(settings.get("language", DEFAULT_SETTINGS["language"]))
	var table: Dictionary = TEXT.get(language, TEXT["en"])
	return str(table.get(key, TEXT["en"].get(key, key)))

func record_result(won: bool, day_key: String = "", mode: String = "", correct_count: int = 0, total_count: int = 0) -> void:
	if won:
		statistics["wins"] = int(statistics.get("wins", 0)) + 1
		statistics["streak"] = int(statistics.get("streak", 0)) + 1
		statistics["best_streak"] = max(int(statistics.get("best_streak", 0)), int(statistics["streak"]))
	else:
		statistics["losses"] = int(statistics.get("losses", 0)) + 1
		statistics["streak"] = 0
	if mode == "daily" and not day_key.is_empty():
		daily_results[day_key] = {
			"completed": true,
			"won": won,
			"correct_count": correct_count,
			"total_count": total_count
		}
	save_data()

func get_daily_streak(today_key: String = "") -> int:
	var current_day: String = today_key if not today_key.is_empty() else Time.get_date_string_from_system()
	# A loss today breaks the visible daily streak. Previously this skipped back
	# to yesterday and made a lost challenge look as though the streak survived.
	if _daily_challenge_completed(current_day) and not _daily_challenge_won(current_day):
		return 0
	if not _daily_challenge_won(current_day):
		current_day = _date_offset(current_day, -1)
	var streak: int = 0
	while _daily_challenge_won(current_day):
		streak += 1
		current_day = _date_offset(current_day, -1)
	return streak

func get_daily_streak_before(day_key: String) -> int:
	var current_day: String = _date_offset(day_key, -1)
	var streak: int = 0
	while _daily_challenge_won(current_day):
		streak += 1
		current_day = _date_offset(current_day, -1)
	return streak

func daily_streak_text(today_key: String = "") -> String:
	return text("home_streak") % get_daily_streak(today_key)

func is_daily_challenge_completed(day_key: String = "") -> bool:
	var current_day: String = day_key if not day_key.is_empty() else Time.get_date_string_from_system()
	return _daily_challenge_completed(current_day)

func get_daily_result(day_key: String = "") -> Dictionary:
	var current_day: String = day_key if not day_key.is_empty() else Time.get_date_string_from_system()
	var result: Variant = daily_results.get(current_day, {})
	return result.duplicate(true) if result is Dictionary else {}

func consume_daily_streak_animation(day_key: String) -> bool:
	if day_key.is_empty():
		return false
	var result_value: Variant = daily_results.get(day_key, {})
	if not (result_value is Dictionary):
		return false
	var result: Dictionary = result_value
	if not bool(result.get("completed", false)) or bool(result.get("streak_animation_seen", false)):
		return false
	result["streak_animation_seen"] = true
	daily_results[day_key] = result
	save_data()
	return true

func _daily_challenge_completed(day_key: String) -> bool:
	var result: Variant = daily_results.get(day_key, {})
	if not (result is Dictionary):
		return false
	return bool(result.get("completed", result.get("won", false)))

func _daily_challenge_won(day_key: String) -> bool:
	var result: Variant = daily_results.get(day_key, {})
	if not (result is Dictionary):
		return false
	return bool(result.get("won", false))

func _date_offset(day_key: String, offset_days: int) -> String:
	var unix_time: int = Time.get_unix_time_from_datetime_string("%sT00:00:00" % day_key)
	var shifted_time: int = unix_time + offset_days * 86400
	var shifted_date: Dictionary = Time.get_date_dict_from_unix_time(shifted_time)
	return "%04d-%02d-%02d" % [
		int(shifted_date.get("year", 1970)),
		int(shifted_date.get("month", 1)),
		int(shifted_date.get("day", 1))
	]

func get_played_puzzle_ids(mode: String) -> Array[String]:
	var result: Array[String] = []
	var saved_ids: Variant = played_puzzle_ids.get(mode, [])
	if not (saved_ids is Array):
		return result
	for value: Variant in saved_ids:
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

func _merge_settings(saved_settings: Variant) -> void:
	if not (saved_settings is Dictionary):
		return
	for key: Variant in DEFAULT_SETTINGS.keys():
		if saved_settings.has(key):
			settings[key] = saved_settings[key]
	if not TEXT.has(str(settings.get("language", "en"))):
		settings["language"] = DEFAULT_SETTINGS["language"]

func _merge_dictionary(defaults: Dictionary, saved_value: Variant) -> Dictionary:
	var result: Dictionary = defaults.duplicate(true)
	if saved_value is Dictionary:
		for key: Variant in saved_value.keys():
			result[key] = saved_value[key]
	return result

func _dictionary_or_empty(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}
