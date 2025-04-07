extends Control
# Level Select Screen - For browsing and selecting game levels

var levels_container: GridContainer
var animation_player: AnimationPlayer
var tween: Tween
var level_button_scene = preload("res://scenes/ui/level_button.tscn")
var level_buttons = []

# Called when the node enters the scene tree for the first time
func _ready():
	# Get references to nodes
	levels_container = $ScrollContainer/LevelsContainer
	animation_player = $AnimationPlayer
	
	# Connect signals
	$TopBar/BackButton.pressed.connect(_on_back_button_pressed)
	LevelManager.levels_loaded.connect(_on_levels_loaded)
	
	# Play animations
	if animation_player:
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
	var levels = LevelManager.levels
	if levels.is_empty():
		# If levels haven't been loaded yet, this will trigger the _on_levels_loaded signal
		LevelManager.load_all_levels()
	else:
		_on_levels_loaded(levels)

# Handle back button to return to main menu
func _on_back_button_pressed():
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
	# Create and add a button for each level
	for i in range(levels.size()):
		var level = levels[i]
		var button = level_button_scene.instantiate()
		levels_container.add_child(button)
		level_buttons.append(button)
		
		# Configure the button
		button.level_id = level.id
		button.level_name = level.name
		button.level_description = level.description
		button.star_count = level.progress.stars if level.has("progress") else 0
		button.is_locked = not level.unlocked if level.has("unlocked") else true
		
		# First level is always unlocked
		if i == 0:
			button.is_locked = false
		
		# Delayed appearance for nicer UI
		button.modulate = Color(1, 1, 1, 0)
		var button_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		button_tween.tween_property(button, "modulate", Color(1, 1, 1, 1), 0.3).set_delay(i * 0.05)
		
		# Connect the level button signal
		button.level_selected.connect(_on_level_selected)

# Handle level selection
func _on_level_selected(level_id):
	SoundManager.play("click")
	
	# Load the level data
	var level_data = LevelManager.load_level(level_id)
	if level_data.is_empty():
		# Handle error
		print("Error: Failed to load level %s" % level_id)
		return
	
	# Create a nice transition
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func():
		# Change to game scene and pass level data
		var game_scene = load("res://scenes/game_screen.tscn").instantiate()
		get_tree().root.add_child(game_scene)
		get_tree().current_scene = game_scene
		game_scene.load_level(level_data)
		
		# Remove this scene
		queue_free()
	)
