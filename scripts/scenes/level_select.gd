extends Control
# Level Select Screen - For browsing and selecting game levels

@onready var levels_container = $ScrollContainer/LevelsGrid
@onready var back_button = $ButtonsContainer/BackButton

var animation_player: AnimationPlayer
var tween: Tween = null
var level_button_scene = preload("res://scenes/ui/simple_level_button.tscn") if FileAccess.file_exists("res://scenes/ui/simple_level_button.tscn") else null
var level_buttons = []

# Called when the node enters the scene tree for the first time
func _ready():
	# Get references to nodes
	if has_node("AnimationPlayer"):
		animation_player = $AnimationPlayer
	
	# Connect signals
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect to LevelManager signals if available
	if LevelManager != null and LevelManager.has_signal("levels_loaded"):
		LevelManager.levels_loaded.connect(_on_levels_loaded)
	
	# Play animations
	if animation_player and animation_player.has_animation("screen_appear"):
		animation_player.play("screen_appear")
	
	# Load levels
	load_levels()

# Load and display all available levels
func load_levels():
	# Clear existing level buttons
	for button in level_buttons:
		button.queue_free()
	level_buttons.clear()
	
	# Get levels from the LevelManager
	var levels = []
	if LevelManager != null and LevelManager.has_method("get_all_levels"):
		levels = LevelManager.get_all_levels()
	elif LevelManager != null and LevelManager.has_property("levels"):
		levels = LevelManager.levels
	
	if levels.is_empty():
		# If levels haven't been loaded yet, try to load them
		if LevelManager != null and LevelManager.has_method("load_all_levels"):
			LevelManager.load_all_levels()
		else:
			# Fallback to creating sample levels for testing
			create_sample_levels()
	else:
		_on_levels_loaded(levels)

# Create sample levels for testing
func create_sample_levels():
	var sample_levels = [
		{
			"id": "level_1",
			"name": "Level 1: Wood Tower",
			"description": "Build a simple tower with wooden blocks",
			"unlocked": true,
			"progress": {"stars": 0}
		},
		{
			"id": "level_2",
			"name": "Level 2: Stone & Wood",
			"description": "Mix stone and wood for a stronger tower",
			"unlocked": false,
			"progress": {"stars": 0}
		}
	]
	
	_on_levels_loaded(sample_levels)

# Handle back button to return to main menu
func _on_back_button_pressed():
	if SoundManager != null and SoundManager.has_method("play"):
		SoundManager.play("click")
	
	# Create a nice transition
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)

# Callback for when levels are loaded
func _on_levels_loaded(levels):
	# Check if our container exists
	if not levels_container:
		push_error("Level grid container not found!")
		return
		
	# Check if we have the level button scene
	if not level_button_scene:
		push_error("Level button scene not found!")
		return
	
	# Create and add a button for each level
	for i in range(levels.size()):
		var level = levels[i]
		var button = level_button_scene.instantiate()
		levels_container.add_child(button)
		level_buttons.append(button)
		
		# Get level properties with fallbacks
		var l_id = level.id if level.has("id") else "level_" + str(i+1)
		var l_name = level.name if level.has("name") else "Level " + str(i+1)
		var l_desc = level.description if level.has("description") else ""
		var stars = level.progress.stars if level.has("progress") and level.progress.has("stars") else 0
		var locked = not level.unlocked if level.has("unlocked") else (i > 0) # First level always unlocked
		
		# Make first level always unlocked for testing
		if i == 0:
			locked = false
		
		# Use the configure method instead of setting properties directly
		if button.has_method("configure"):
			button.configure(l_id, l_name, l_desc, stars, locked)
		
		# Delayed appearance for nicer UI
		button.modulate = Color(1, 1, 1, 0)
		var button_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		button_tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.3).set_delay(i * 0.05)
		
		# Connect the level button signal
		if button.has_signal("level_selected"):
			print("Connecting level_selected signal for button: ", l_id)
			button.level_selected.connect(_on_level_selected)
		else:
			push_error("Button missing level_selected signal!")

# Handle level selection
func _on_level_selected(level_id):
	print("Level selected: ", level_id)  # Debug print
	
	if SoundManager != null and SoundManager.has_method("play"):
		SoundManager.play("click")
	
	# Tell the GameManager which level was selected
	if GameManager != null and GameManager.has_method("select_level"):
		GameManager.select_level(level_id)
	
	# Create a nice transition
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func():
		# Change to game scene
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	)
