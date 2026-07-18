extends RefCounted
class_name AchievementCatalog

const DEFINITIONS: Array[Dictionary] = [
	{
		"id": "daily_legend",
		"metric": "daily_wins",
		"thresholds": [10, 100, 1000],
		"title_en": "Daily Legend",
		"title_fi": "Päivän legenda",
		"description_en": "Win Daily Challenges.",
		"description_fi": "Voita päivän haasteita.",
		"accent": "yellow"
	},
	{
		"id": "endless_expedition",
		"metric": "unlimited_wins",
		"thresholds": [10, 100, 1000],
		"title_en": "Endless Expedition",
		"title_fi": "Loputon tutkimusmatka",
		"description_en": "Complete Infinity Mode pyramids.",
		"description_fi": "Ratkaise äärettömän pelin pyramideja.",
		"accent": "purple"
	},
	{
		"id": "pyramid_architect",
		"metric": "total_wins",
		"thresholds": [25, 250, 1000],
		"title_en": "Pyramid Architect",
		"title_fi": "Pyramidiarkkitehti",
		"description_en": "Complete pyramids in any game mode.",
		"description_fi": "Ratkaise pyramideja missä tahansa pelimuodossa.",
		"accent": "teal"
	},
	{
		"id": "burning_streak",
		"metric": "best_daily_streak",
		"thresholds": [3, 7, 30],
		"title_en": "Burning Streak",
		"title_fi": "Palava putki",
		"description_en": "Build a Daily Challenge win streak.",
		"description_fi": "Kasvata päivän haasteiden voittoputkea.",
		"accent": "coral"
	},
	{
		"id": "perfect_precision",
		"metric": "flawless_wins",
		"thresholds": [5, 25, 100],
		"title_en": "Perfect Precision",
		"title_fi": "Täydellinen tarkkuus",
		"description_en": "Win without making a mistake.",
		"description_fi": "Voita tekemättä yhtään virhettä.",
		"accent": "yellow"
	},
	{
		"id": "sharp_mind",
		"metric": "no_hint_wins",
		"thresholds": [5, 50, 250],
		"title_en": "Sharp Mind",
		"title_fi": "Terävä mieli",
		"description_en": "Win without using a hint.",
		"description_fi": "Voita käyttämättä vihjettä.",
		"accent": "teal"
	},
	{
		"id": "rising_scholar",
		"metric": "player_level",
		"thresholds": [5, 10, 25],
		"title_en": "Rising Scholar",
		"title_fi": "Nouseva taituri",
		"description_en": "Raise your player level.",
		"description_fi": "Nosta pelaajatasoasi.",
		"accent": "purple"
	},
	{
		"id": "first_pyramid",
		"metric": "total_wins",
		"thresholds": [1],
		"title_en": "First Pyramid",
		"title_fi": "Ensimmäinen pyramidi",
		"description_en": "Complete your first Word Pyramid.",
		"description_fi": "Ratkaise ensimmäinen sanapyramidisi.",
		"accent": "yellow",
		"special": true
	},
	{
		"id": "last_chance",
		"metric": "last_chance_wins",
		"thresholds": [1],
		"title_en": "Last Chance",
		"title_fi": "Viimeinen mahdollisuus",
		"description_en": "Win with only one attempt remaining.",
		"description_fi": "Voita, kun vain yksi yritys on jäljellä.",
		"accent": "coral",
		"special": true
	},
	{
		"id": "master_of_modes",
		"metric": "modes_won",
		"thresholds": [2],
		"title_en": "Master of Modes",
		"title_fi": "Pelimuotojen mestari",
		"description_en": "Win both Daily Challenge and Infinity Mode.",
		"description_fi": "Voita sekä päivän haaste että ääretön peli.",
		"accent": "purple",
		"special": true
	}
]

static func definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition: Dictionary in DEFINITIONS:
		result.append(definition.duplicate(true))
	return result

static func max_stars() -> int:
	var total: int = 0
	for definition: Dictionary in DEFINITIONS:
		total += (definition.get("thresholds", []) as Array).size()
	return total

static func localized_title(definition: Dictionary, language: String) -> String:
	return str(definition.get("title_fi" if language == "fi" else "title_en", definition.get("id", "Achievement")))

static func localized_description(definition: Dictionary, language: String) -> String:
	return str(definition.get("description_fi" if language == "fi" else "description_en", ""))
