extends Node3D
# Main game scene that handles block placement, physics, and game rules

signal level_completed(star_count, score, time_taken, moves)

@export var block_scene: PackedScene
@export var gravity_multiplier: float = 1.0

# Game parameters
var current_level_id: String = ""
var current_level_data: Dictionary = {}
var game_started: bool = false
var pause_physics: bool = false

# Score tracking
var current_score: int = 0
var moves_made: int = 0
var time_elapsed: float = 0
var finished: bool = false
var final_stars: int = 0

# Block preview
var current_block_type: String = "wood"
var current_block_rotation: float = 0
var preview_block: RigidBody3D = null

# Block counters
var available_blocks: Dictionary = {
	"wood": 10,
	"stone": 5,
	"metal": 2,
	"ice": 1
}

# UI references
@onready var score_label: Label = $UI/ScoreLabel
@onready var moves_label: Label = $UI/MovesLabel
@onready var timer_label: Label = $UI/TimerLabel
@onready var block_toolbar = $UI/BlockToolbar
@onready var wood_button = $UI/BlockToolbar/BlockButtons/WoodButton
@onready var stone_button = $UI/BlockToolbar/BlockButtons/StoneButton
@onready var metal_button = $UI/BlockToolbar/BlockButtons/MetalButton
@onready var ice_button = $UI/BlockToolbar/BlockButtons/IceButton
@onready var block_preview_node = $BlockPreview
@onready var camera = $Camera3D
@onready var game_timer = $GameTimer
@onready var stability_timer = $StabilityTimer

# Called when the node enters the scene tree for the first time
func _ready():
	# Setup block toolbar
	wood_button.pressed.connect(func(): set_block_type("wood"))
	stone_button.pressed.connect(func(): set_block_type("stone"))
	metal_button.pressed.connect(func(): set_block_type("stone"))
	ice_button.pressed.connect(func(): set_block_type("ice"))
	
	# Load level if specified
	var level_id = GameManager.get_selected_level() if GameManager.has_method("get_selected_level") else "level_1"
	load_level(level_id)
	
	# Setup timers
	game_timer.timeout.connect(_on_game_timer_timeout)
	stability_timer.timeout.connect(_on_stability_timer_timeout)
	
	# Create initial block preview
	_create_block_preview()
	
	# Start game
	start_game()

# Load the specified level
func load_level(level_id: String):
	current_level_id = level_id
	
	# Get level data from LevelManager
	if LevelManager.has_method("get_level"):
		current_level_data = LevelManager.get_level(level_id)
	else:
		# Fallback to default level data if LevelManager doesn't exist
		current_level_data = {
			"id": level_id,
			"name": "Test Level",
			"target_height": 10,
			"time_limit": 120,
			"blocks": {
				"wood": 10,
				"stone": 5,
				"metal": 2,
				"ice": 1
			},
			"stars": [
				{"requirement": "height", "value": 5},
				{"requirement": "time", "value": 60},
				{"requirement": "remaining_blocks", "value": 3}
			]
		}
	
	# Reset game state
	reset_game_state()
	
	# Set available blocks based on level data
	if current_level_data.has("blocks"):
		available_blocks = current_level_data.blocks.duplicate()
	
	# Update UI to reflect loaded level
	update_ui()

# Reset game state
func reset_game_state():
	current_score = 0
	moves_made = 0
	time_elapsed = 0
	finished = false
	final_stars = 0
	
	# Clear any existing blocks
	for child in get_children():
		if child is RigidBody3D and child != preview_block:
			child.queue_free()
	
	# Reset physics
	pause_physics = false
	
	# Update UI
	update_ui()

# Start the game
func start_game():
	game_started = true
	
	# Start timer
	game_timer.start()
	
	# Set game state
	if GameManager.has_method("set_state"):
		GameManager.set_state(GameManager.GameState.PLAYING)

# Set the current block type
func set_block_type(type: String):
	if type in available_blocks and available_blocks[type] > 0:
		current_block_type = type
		_update_block_preview()
		
		# Play sound
		if SoundManager.has_method("play"):
			SoundManager.play("click")

# Handle user input
func _input(event):
	if finished or pause_physics:
		return
	
	# Handle keyboard shortcuts for block types
	if event.is_action_pressed("block_type_wood"):
		set_block_type("wood")
	elif event.is_action_pressed("block_type_stone"):
		set_block_type("stone")
	elif event.is_action_pressed("block_type_metal"):
		set_block_type("metal")
	elif event.is_action_pressed("block_type_ice"):
		set_block_type("ice")
	
	# Handle block rotation
	if event.is_action_pressed("rotate_block_left"):
		current_block_rotation -= PI/2
		_update_block_preview()
	elif event.is_action_pressed("rotate_block_right"):
		current_block_rotation += PI/2
		_update_block_preview()
	
	# Handle block placement
	if event.is_action_pressed("place_block"):
		_place_block()
	
	# Handle pause
	if event.is_action_pressed("pause"):
		_toggle_pause()

# Place a block in the world
func _place_block():
	if not game_started or finished or available_blocks[current_block_type] <= 0:
		return
	
	# Create a real block at the preview position
	var block = block_scene.instantiate()
	block.initialize(current_block_type)
	block.transform = preview_block.transform
	add_child(block)
	
	# Decrement available blocks
	available_blocks[current_block_type] -= 1
	
	# Increment moves
	moves_made += 1
	
	# Update UI
	update_ui()
	
	# Play sound
	if SoundManager.has_method("play"):
		SoundManager.play("place_block")
	
	# Start stability timer to check if tower is stable
	stability_timer.start()

# Create and update the block preview
func _create_block_preview():
	if preview_block == null:
		preview_block = block_scene.instantiate()
		preview_block.set_physics_process(false)
		preview_block.set_process(false)
		block_preview_node.add_child(preview_block)
	
	_update_block_preview()

func _update_block_preview():
	if preview_block:
		preview_block.initialize(current_block_type, true)
		preview_block.rotation.y = current_block_rotation
		
		# Update the preview position based on mouse position
		var mouse_pos = get_viewport().get_mouse_position()
		
		# Position the preview block in 3D space
		# This is a simplified version - in a real game you'd use raycasting to position it properly
		block_preview_node.position = Vector3(0, 1.5, 0)

# Timer callback
func _on_game_timer_timeout():
	if game_started and not finished:
		time_elapsed += 1
		update_timer_display()
		
		# Check if time limit is reached
		if current_level_data.has("time_limit") and time_elapsed >= current_level_data.time_limit:
			_check_completion()

# Stability timer callback
func _on_stability_timer_timeout():
	# Check if tower is stable and meets completion criteria
	_check_completion()

# Check if level is completed
func _check_completion():
	if finished:
		return
	
	# Here we would check if the tower height requirement is met
	# For now, we'll assume it's completed after placing some blocks
	if moves_made >= 5:
		_complete_level()

# Complete the level
func _complete_level():
	finished = true
	
	# Calculate stars
	final_stars = _calculate_stars()
	
	# Save progress
	_save_progress()
	
	# Show completion screen
	_show_completion_screen()

# Calculate stars earned
func _calculate_stars() -> int:
	var stars = 0
	
	# Simple star calculation based on moves and time
	# In a real implementation, you'd check against the star requirements in level_data
	if moves_made <= 10:
		stars += 1
	if time_elapsed <= 60:
		stars += 1
	if available_blocks.values().reduce(func(accum, count): return accum + count, 0) > 0:
		stars += 1
	
	return stars

# Save level progress
func _save_progress():
	# Report progress to GameManager
	if GameManager.has_method("complete_level"):
		GameManager.complete_level(current_level_id, final_stars, current_score, time_elapsed, moves_made)

# Show level completion screen
func _show_completion_screen():
	# Pause the game
	pause_physics = true
	
	# Emit completion signal
	emit_signal("level_completed", final_stars, current_score, time_elapsed, moves_made)
	
	# Load and show completion screen
	var level_complete = load("res://scenes/level_complete.tscn").instantiate()
	level_complete.setup(final_stars, current_score, time_elapsed, moves_made)
	add_child(level_complete)

# Toggle pause state
func _toggle_pause():
	if GameManager.has_method("toggle_pause"):
		GameManager.toggle_pause()
	else:
		pause_physics = !pause_physics
		get_tree().paused = pause_physics

# Update UI elements
func update_ui():
	# Update score
	score_label.text = "Score: " + str(current_score)
	
	# Update moves
	moves_label.text = "Moves: " + str(moves_made)
	
	# Update timer
	update_timer_display()
	
	# Update block counts on buttons
	wood_button.text = "Wood (" + str(available_blocks["wood"]) + ")"
	stone_button.text = "Stone (" + str(available_blocks["stone"]) + ")"
	metal_button.text = "Metal (" + str(available_blocks["metal"]) + ")"
	ice_button.text = "Ice (" + str(available_blocks["ice"]) + ")"
	
	# Disable buttons if no blocks available
	wood_button.disabled = available_blocks["wood"] <= 0
	stone_button.disabled = available_blocks["stone"] <= 0
	metal_button.disabled = available_blocks["metal"] <= 0
	ice_button.disabled = available_blocks["ice"] <= 0

# Update timer display
func update_timer_display():
	var minutes = int(time_elapsed) / 60
	var seconds = int(time_elapsed) % 60
	timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

# Physics process for handling block preview position
func _physics_process(delta):
	if pause_physics:
		return
	
	# Update preview position based on mouse
	_update_preview_position()

# Update preview position based on mouse position
func _update_preview_position():
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Cast ray from camera to mouse position
	var camera_pos = camera.global_position
	var ray_length = 100
	
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	
	var result = space_state.intersect_ray(query)
	if result:
		# Position block preview at hit position
		block_preview_node.global_position = result.position + Vector3(0, 1, 0)
