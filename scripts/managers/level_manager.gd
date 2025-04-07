extends Node
# Level Manager - Manages levels, their data, and progression

signal levels_loaded(levels)
signal level_loaded(level_data)

const LEVELS_PATH = "res://data/"
const LEVELS_FILE = "levels.json"

var levels = []
var current_level = null
var current_level_index = -1

# Level structure:
# {
#   "id": "level_1",
#   "name": "Level 1: Wooden Tower",
#   "description": "Build a simple tower with wooden blocks",
#   "difficulty": 1,
#   "target_height": 5,
#   "time_limit": 120,
#   "blocks": {
#     "wood": 10,
#     "stone": 2,
#     "metal": 0,
#     "ice": 0
#   },
#   "stars": [
#     {"requirement": "height", "value": 5},
#     {"requirement": "time", "value": 60},
#     {"requirement": "remaining_blocks", "value": 3}
#   ],
#   "unlocks": ["level_2"]
# }

func _ready():
	# Load levels with a slight delay to ensure other systems are initialized
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(load_all_levels)

# Load all available levels
func load_all_levels() -> void:
	levels.clear()
	var full_path = LEVELS_PATH + LEVELS_FILE
	
	if FileAccess.file_exists(full_path):
		var file = FileAccess.open(full_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var error = json.parse(json_text)
			
			if error == OK:
				var data = json.get_data()
				if data is Dictionary:
					# Convert dictionary of levels to array
					for level_id in data:
						var level = data[level_id]
						if level is Dictionary:
							levels.append(level)
				elif data is Array:
					levels = data
			else:
				push_error("JSON Parse Error: " + json.get_error_message())
	else:
		push_error("Levels file not found at: " + full_path)
		# Create sample levels for testing
		create_sample_levels()
	
	# Sort levels by ID
	levels.sort_custom(func(a, b): return a.id < b.id)
	
	# Add progress data from saves
	add_progress_data_to_levels()
	
	emit_signal("levels_loaded", levels)

# Create sample levels for testing if no file exists
func create_sample_levels() -> void:
	levels = [
		{
			"id": "level_1",
			"name": "Level 1: Wooden Tower",
			"description": "Build a simple tower with wooden blocks",
			"difficulty": 1,
			"target_height": 5,
			"time_limit": 120,
			"blocks": {
				"wood": 10,
				"stone": 2,
				"metal": 0,
				"ice": 0
			},
			"stars": [
				{"requirement": "height", "value": 5},
				{"requirement": "time", "value": 60},
				{"requirement": "remaining_blocks", "value": 3}
			],
			"unlocks": ["level_2"]
		},
		{
			"id": "level_2",
			"name": "Level 2: Stone & Wood",
			"description": "Mix stone and wood for a stronger tower",
			"difficulty": 2,
			"target_height": 8,
			"time_limit": 180,
			"blocks": {
				"wood": 8,
				"stone": 5,
				"metal": 0,
				"ice": 0
			},
			"stars": [
				{"requirement": "height", "value": 8},
				{"requirement": "time", "value": 120},
				{"requirement": "remaining_blocks", "value": 2}
			],
			"unlocks": ["level_3"]
		}
	]

# Get all levels
func get_all_levels() -> Array:
	return levels

# Add player progress data to levels
func add_progress_data_to_levels() -> void:
	if not DataManager.has_method("load_progress"):
		# Set default progress for testing
		for i in range(levels.size()):
			var level = levels[i]
			level["progress"] = {
				"completed": false,
				"stars": 0,
				"score": 0,
				"moves": 0,
				"time": 0
			}
			level["unlocked"] = (i == 0) # First level is always unlocked
		return
		
	var progress = DataManager.load_progress()
	if progress and progress.has("levels"):
		for level in levels:
			var level_id = level.id
			if progress.levels.has(level_id):
				level["progress"] = progress.levels[level_id]
				level["unlocked"] = true
			else:
				level["progress"] = {
					"completed": false,
					"stars": 0,
					"score": 0,
					"moves": 0,
					"time": 0
				}
				
				# First level is always unlocked
				if level.id == "level_1":
					level["unlocked"] = true
				else:
					# Unlock level if previous level is completed
					var prev_level_id = get_previous_level_id(level.id)
					if prev_level_id and progress.levels.has(prev_level_id) and progress.levels[prev_level_id].completed:
						level["unlocked"] = true
					else:
						level["unlocked"] = false

# Get the previous level's ID
func get_previous_level_id(level_id: String) -> String:
	var parts = level_id.split("_")
	if parts.size() >= 2:
		var level_num = int(parts[1])
		if level_num > 1:
			return "level_" + str(level_num - 1)
	return ""

# Load a specific level by ID
func load_level(level_id: String) -> Dictionary:
	for i in range(levels.size()):
		if levels[i].id == level_id:
			current_level = levels[i].duplicate(true)
			current_level_index = i
			emit_signal("level_loaded", current_level)
			return current_level
	
	# Level not found
	push_error("Level not found: " + level_id)
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

# Calculate stars earned for a level
func calculate_stars(level_id: String, score: int, time: float, remaining_blocks: int) -> int:
	var level = get_level_by_id(level_id)
	if not level or not level.has("stars"):
		return 0
	
	var stars = 0
	
	for star_req in level.stars:
		var requirement = star_req.requirement
		var value = star_req.value
		
		if requirement == "height" and score >= value:
			stars += 1
		elif requirement == "time" and time <= value:
			stars += 1
		elif requirement == "remaining_blocks" and remaining_blocks >= value:
			stars += 1
	
	return stars

# Get a level by its ID
func get_level_by_id(level_id: String) -> Dictionary:
	for level in levels:
		if level.id == level_id:
			return level
	return {}
