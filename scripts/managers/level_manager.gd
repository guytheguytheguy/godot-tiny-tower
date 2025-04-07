extends Node
# Level Manager - Manages levels, their data, and progression

signal levels_loaded(levels)
signal level_loaded(level_data)

const LEVELS_PATH = "res://assets/levels/"

var levels = []
var current_level = null
var current_level_index = -1

# Level structure in Godot version:
# {
#   "id": "level-1",
#   "name": "Tutorial",
#   "description": "Learn how to stack blocks",
#   "min_score": 100,
#   "time_limit": 60,
#   "star_requirements": [100, 200, 300], # Score needed for each star
#   "blocks": [
#     {
#       "id": "block-1",
#       "type": "wood",
#       "position": [0, 1, 0],
#       "rotation": [0, 0, 0],
#       "size": [1, 1, 1],
#       "mass": 1,
#       "is_static": false
#     }
#   ],
#   "win_condition": {
#     "type": "height", # could also be "score", "time", etc.
#     "value": 10 # height in units
#   },
#   "physics": {
#     "gravity": 25.0,
#     "friction": 0.8,
#     "restitution": 0.1
#   }
# }

func _ready():
	load_all_levels()

# Load all available levels
func load_all_levels() -> void:
	var levels_dir = DirAccess.open(LEVELS_PATH)
	if levels_dir:
		levels_dir.list_dir_begin()
		var file_name = levels_dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".json"):
				var level = load_level_file(LEVELS_PATH + file_name)
				if level:
					levels.append(level)
			file_name = levels_dir.get_next()
	
	# Sort levels by ID
	levels.sort_custom(func(a, b): return a.id < b.id)
	
	# Add progress data from saves
	add_progress_data_to_levels()
	
	emit_signal("levels_loaded", levels)

# Load a specific level file
func load_level_file(file_path: String) -> Dictionary:
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		file.close()
		
		if json is Dictionary:
			return json
	
	return {}

# Add player progress data to levels
func add_progress_data_to_levels() -> void:
	var progress = DataManager.load_progress()
	if progress and progress.has("levels"):
		for level in levels:
			var level_id = level.id
			if progress.levels.has(level_id):
				level.progress = progress.levels[level_id]
				level.unlocked = true
			else:
				level.progress = {
					"completed": false,
					"stars": 0,
					"score": 0,
					"moves": 0,
					"time": 0
				}
				
				# First level is always unlocked
				if level.id == "level-1":
					level.unlocked = true
				else:
					# Unlock level if previous level is completed
					var prev_level_id = get_previous_level_id(level.id)
					if prev_level_id and progress.levels.has(prev_level_id) and progress.levels[prev_level_id].completed:
						level.unlocked = true
					else:
						level.unlocked = false

# Get the previous level's ID
func get_previous_level_id(level_id: String) -> String:
	var level_num = int(level_id.split("-")[1])
	if level_num > 1:
		return "level-" + str(level_num - 1)
	return ""

# Load a specific level by ID
func load_level(level_id: String) -> Dictionary:
	for i in range(levels.size()):
		if levels[i].id == level_id:
			current_level = levels[i].duplicate(true)
			current_level_index = i
			emit_signal("level_loaded", current_level)
			return current_level
	
	return {}

# Get the next level ID
func get_next_level_id() -> String:
	if current_level_index >= 0 and current_level_index < levels.size() - 1:
		return levels[current_level_index + 1].id
	return ""

# Check if a level is completed
func is_level_completed(level_id: String) -> bool:
	for level in levels:
		if level.id == level_id and level.has("progress") and level.progress.completed:
			return true
	return false

# Calculate stars earned for current level
func calculate_stars(score: int) -> int:
	if not current_level:
		return 0
		
	var star_requirements = current_level.star_requirements
	var stars = 0
	
	for requirement in star_requirements:
		if score >= requirement:
			stars += 1
	
	return stars
