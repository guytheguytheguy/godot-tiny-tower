extends Node
# Data Manager - Handles game saving and loading

const SAVE_PATH = "user://tiny_tower_save.json"
const SETTINGS_PATH = "user://tiny_tower_settings.json"

# Save game progress
func save_progress(data: Dictionary) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))
		file.close()

# Load game progress
func load_progress() -> Dictionary:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			
			var json = JSON.parse_string(json_text)
			if json is Dictionary:
				return json
	
	# Return default empty progress
	return {
		"levels": {},
		"lastPlayedLevel": null,
		"totalStars": 0,
		"highestBlockTower": 0
	}

# Save level progress
func save_level_progress(level_id: String, level_data: Dictionary) -> void:
	var progress = load_progress()
	
	if not progress.has("levels"):
		progress.levels = {}
	
	# Update level progress
	progress.levels[level_id] = level_data
	
	# Update last played level
	progress.lastPlayedLevel = level_id
	
	# Update total stars
	var total_stars = 0
	for level in progress.levels.values():
		if level.has("stars"):
			total_stars += level.stars
	progress.totalStars = total_stars
	
	save_progress(progress)

# Save game settings
func save_settings(settings: Dictionary) -> void:
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "  "))
		file.close()

# Load game settings
func load_settings() -> Dictionary:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			
			var json = JSON.parse_string(json_text)
			if json is Dictionary:
				return json
	
	# Return default settings
	return {
		"sound_enabled": true,
		"music_enabled": true,
		"sound_volume": 0.8,
		"music_volume": 0.5,
		"game_speed": 1.0
	}

# Clear all saved data (for debug or reset)
func clear_all_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(SETTINGS_PATH)
