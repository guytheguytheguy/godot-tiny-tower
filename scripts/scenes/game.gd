extends Node3D
# Main game scene that handles block removal physics, and game rules

signal level_completed(star_count, score, time_taken, blocks_removed)

@export var block_scene: PackedScene
@export var gravity_multiplier: float = 1.0
@export var particle_effect_scene: PackedScene
@export var camera_shake_intensity: float = 0.2
@export var camera_shake_duration: float = 0.4

# Game parameters
var current_level_id: String = ""
var current_level_data: Dictionary = {}
var game_started: bool = false
var pause_physics: bool = false

# Score tracking
var current_score: int = 0
var blocks_removed: int = 0
var time_elapsed: float = 0
var finished: bool = false
var final_stars: int = 0
var tower_collapsed: bool = false

# Tower tracking
var tower_blocks: Array = []
var selected_block: RigidBody3D = null
var starting_block_count: int = 0
var can_remove_blocks: bool = true
var tower_center: Vector3 = Vector3.ZERO

# Visual effects
var dust_particles_scene: PackedScene = preload("res://scenes/effects/dust_particles.tscn")
var tower_collapse_effect_scene: PackedScene = preload("res://scenes/effects/tower_collapse_effect.tscn")
var camera_original_position: Vector3
var camera_original_rotation: Vector3

# UI references
@onready var score_label: Label = $UI/ScoreLabel
@onready var blocks_removed_label: Label = $UI/BlocksRemovedLabel
@onready var timer_label: Label = $UI/TimerLabel
@onready var stability_timer = $StabilityTimer
@onready var collapse_timer = $CollapseTimer
@onready var camera = $Camera3D

# Called when the node enters the scene tree for the first time
func _ready():
	# Initialize physics settings for Jenga-style gameplay
	PhysicsServer3D.area_set_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 9.8 * gravity_multiplier)
	
	# Make sure block scene is loaded
	if block_scene == null:
		block_scene = preload("res://scenes/objects/block.tscn")
		print("Block scene loaded from script")
	
	# Load level if specified
	var level_id = GameManager.get_selected_level() if GameManager.has_method("get_selected_level") else "level_1"
	load_level(level_id)
	
	# Setup timers
	$GameTimer.timeout.connect(_on_game_timer_timeout)
	stability_timer.timeout.connect(_on_stability_timer_timeout)
	collapse_timer.timeout.connect(_on_collapse_timer_timeout)
	
	# Add camera shake component if not present
	if !camera.has_script():
		camera.set_script(load("res://scripts/components/camera_shake.gd"))
	
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
			"name": "Jenga Tower",
			"tower_layers": 7,
			"time_limit": 180,
			"tower_config": {
				"blocks_per_layer": 3,
				"layout": "alternating",  # standard, alternating, random
				"block_types": ["jenga_wood"] # types of blocks to use
			},
			"stars": [
				{"requirement": "blocks_removed", "value": 5},
				{"requirement": "time", "value": 120},
				{"requirement": "tower_height", "value": 10}
			]
		}
	
	# Reset game state
	reset_game_state()
	
	# Build the tower
	build_tower()
	
	# Update UI to reflect loaded level
	update_ui()

# Reset game state
func reset_game_state():
	current_score = 0
	blocks_removed = 0
	time_elapsed = 0
	finished = false
	final_stars = 0
	tower_collapsed = false
	selected_block = null
	can_remove_blocks = true
	
	# Clear any existing blocks
	for tower_block in tower_blocks:
		if is_instance_valid(tower_block):
			tower_block.queue_free()
	
	tower_blocks.clear()
	
	# Reset physics
	pause_physics = false
	
	# Update UI
	update_ui()

# Build the tower based on level configuration
func build_tower():
	var tower_config = current_level_data.tower_config
	var num_layers = current_level_data.tower_layers
	
	# Block dimensions
	var block_size = Vector3(1, 0.5, 3)
	var block_spacing = 0.05  # Small gap between blocks to prevent initial collisions
	
	# Create the tower blocks
	var block_scene = load("res://scenes/objects/block.tscn")
	for layer_index in range(num_layers):
		# Alternate the orientation of blocks in each layer
		var is_vertical_layer = layer_index % 2 == 0
		var blocks_per_layer = 3
		var layer_height = layer_index * (block_size.y + block_spacing)
		
		for block_index in range(blocks_per_layer):
			var block_instance = block_scene.instantiate()
			add_child(block_instance)
			
			# Set block properties
			var block_type_key = "wood"
			if tower_config and tower_config.has("layers") and tower_config.layers.has(str(layer_index)):
				var layer_config = tower_config.layers[str(layer_index)]
				if layer_config.has("blocks") and layer_config.blocks.has(str(block_index)):
					block_type_key = layer_config.blocks[str(block_index)]
			
			# Set position and rotation
			var x_pos = 0
			var z_pos = 0
			var rotation_y = 0
			
			if is_vertical_layer:
				# Blocks go along Z axis
				x_pos = block_index - 1
				z_pos = 0
				rotation_y = 0
			else:
				# Blocks go along X axis
				x_pos = 0
				z_pos = block_index - 1
				rotation_y = PI / 2
			
			# Calculate final position with spacing
			var block_position = Vector3(
				x_pos * (block_size.z + block_spacing) if is_vertical_layer else 0,
				layer_height + block_size.y / 2,
				z_pos * (block_size.z + block_spacing) if not is_vertical_layer else 0
			)
			
			# Set the block's properties
			block_instance.block_type = block_type_key
			block_instance.global_position = block_position
			block_instance.rotation.y = rotation_y
			
			# Set physics properties - important for stability
			block_instance.freeze = true
			block_instance.is_static = true
			block_instance.gravity_scale = 0
			
			# Connect signals
			block_instance.block_hit.connect(_on_block_hit.bind(block_instance))
			block_instance.block_settled.connect(_on_block_settled.bind(block_instance))
			block_instance.block_selected.connect(_on_block_selected.bind(block_instance))
			block_instance.block_removed.connect(_on_block_removed.bind(block_instance))
			
			# Add to tower blocks array
			tower_blocks.append(block_instance)
	
	starting_block_count = tower_blocks.size()
	
	# Wait a moment to ensure physics is ready
	await get_tree().create_timer(0.5).timeout
	
	# Enable highlighting for the blocks
	for tower_block in tower_blocks:
		if is_instance_valid(tower_block):
			tower_block.highlight_on_hover = true

# Start the game by releasing all blocks from static state
func start_game():
	if game_started:
		return
	
	print("Starting game with tower blocks: ", tower_blocks.size())
	game_started = true
	time_elapsed = 0
	$GameTimer.start()
	
	# Delay physics for a significant moment to let the tower stabilize
	pause_physics = true
	can_remove_blocks = false
	
	# Wait longer before enabling physics (increased from 1.0 to 2.0)
	await get_tree().create_timer(2.0).timeout
	
	# Keep blocks frozen in place initially
	for tower_block in tower_blocks:
		if is_instance_valid(tower_block):
			tower_block.freeze = true
			tower_block.gravity_scale = 1.0  # Normal gravity now
	
	# Allow more time for the blocks to settle into position
	await get_tree().create_timer(1.0).timeout
	
	# Now very slowly release blocks from bottom to top with longer delays
	var blocks_by_height = {}
	for tower_block in tower_blocks:
		if is_instance_valid(tower_block):
			var height = tower_block.global_position.y
			if not blocks_by_height.has(height):
				blocks_by_height[height] = []
			blocks_by_height[height].append(tower_block)
	
	# Sort heights from lowest to highest
	var heights = blocks_by_height.keys()
	heights.sort()
	
	# Enable physics for each layer with a larger delay
	for height in heights:
		for tower_block in blocks_by_height[height]:
			if is_instance_valid(tower_block):
				tower_block.is_static = false
		
		# Larger delay between layers (increased from 0.1 to 0.3)
		await get_tree().create_timer(0.3).timeout
		
		# Unfreeze after a small delay to ensure proper positioning
		for tower_block in blocks_by_height[height]:
			if is_instance_valid(tower_block):
				tower_block.freeze = false
		
		# Additional delay after unfreezing
		await get_tree().create_timer(0.2).timeout
	
	# Enable player interaction
	pause_physics = false
	can_remove_blocks = true
	
	# Enable block selection for all blocks
	for tower_block in tower_blocks:
		if is_instance_valid(tower_block):
			tower_block.highlight_on_hover = true
			tower_block.is_selectable = true
	
	print("Tower construction complete. Ready for player interaction.")

# Handle user input
func _input(event):
	if not game_started or finished or pause_physics:
		return
	
	# Handle mouse click to select/remove blocks
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_viewport().get_mouse_position()
		
		# Cast ray from camera to mouse position
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * 100
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = false
		
		var result = space_state.intersect_ray(query)
		if result and result.collider in tower_blocks and can_remove_blocks:
			var block = result.collider
			
			if selected_block == block:
				# Block is already selected, attempt to remove it
				_remove_block(block)
			else:
				# Select the block
				_select_block(block)
	
	# Handle escape key to deselect block
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if selected_block:
			selected_block.deselect()
			selected_block = null

# Select a block
func _select_block(block):
	if not can_remove_blocks or not block.is_selectable:
		return
	
	print("Selecting block:", block)
	
	# Deselect the currently selected block if different
	if selected_block and selected_block != block:
		selected_block.deselect()
	
	# Select the new block
	selected_block = block
	block.select()
	
	# Emit signal for other components
	block.emit_signal("block_selected")

# Remove a block
func _remove_block(block):
	if not can_remove_blocks or not block.is_removable:
		return
	
	print("Removing block:", block)
	
	# Disable block interactions temporarily
	can_remove_blocks = false
	
	# Remove from tower blocks array
	if tower_blocks.has(block):
		tower_blocks.erase(block)
	
	# Emit signal before physical removal
	block.emit_signal("block_removed")
	
	# Free block instance
	block.queue_free()

# Focus camera on a specific block with subtle animation
func _focus_camera_on_block(block):
	if not block:
		return
		
	var target_position = block.global_position
	var camera_offset = Vector3(0, 0.5, 0)  # Slight upward offset for better view
	
	# Create a subtle animation to shift camera focus slightly
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "global_position", 
		camera_original_position + (target_position - tower_center).normalized() * 0.5, 
		0.5)
	
	# Also slightly rotate the camera toward the block
	var look_target = target_position
	var current_rotation = camera.global_rotation
	var target_rotation = camera.global_rotation.lerp(
		camera.global_transform.looking_at(look_target, Vector3.UP).basis.get_euler(),
		0.15)  # Only rotate slightly toward target
	
	tween.parallel().tween_property(camera, "global_rotation", target_rotation, 0.5)

# Reset camera to its original position
func _reset_camera_position():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", camera_original_position, 0.8)
	tween.parallel().tween_property(camera, "global_rotation", camera_original_rotation, 0.8)

# Create dust particles at position
func _create_dust_particles(position, size):
	# Instance the dust particles scene
	var particles = dust_particles_scene.instantiate()
	add_child(particles)
	particles.global_position = position
	
	# Configure particle size based on block size
	if size:
		var particle_scale = max(size.x, size.z) / 2
		particles.scale = Vector3(particle_scale, particle_scale, particle_scale)
	
	# Play particles
	particles.play()
	
	# Set up auto-destruction after emission
	var timer = Timer.new()
	particles.add_child(timer)
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(func(): particles.queue_free())
	timer.start()

# Check if tower has collapsed
func _check_tower_collapse():
	var fallen_blocks = 0
	var total_blocks = tower_blocks.size()
	
	for tower_block in tower_blocks:
		if is_instance_valid(tower_block):
			# Consider a block fallen if it's below a certain height or has significant rotation
			var fallen = false
			
			# Below the base
			if tower_block.global_position.y < 0.2:
				fallen = true
			
			# Tipped over (significant rotation)
			var up_dot = tower_block.global_transform.basis.y.dot(Vector3.UP)
			if up_dot < 0.7:  # More sensitive detection
				fallen = true
			
			if fallen:
				fallen_blocks += 1
	
	# Calculate the percentage of fallen blocks
	var fallen_percentage = float(fallen_blocks) / total_blocks if total_blocks > 0 else 0
	
	# Tower is collapsed if enough blocks have fallen
	if fallen_percentage > 0.25:  # 25% of blocks have fallen
		tower_collapsed = true
		_on_tower_collapsed()
		return
	
	# All blocks are stable, allow removing blocks again
	can_remove_blocks = true
	
	# Enable hovering on blocks again
	for tower_block in tower_blocks:
		if is_instance_valid(tower_block) and tower_block.highlight_on_hover:
			tower_block.highlight_on_hover = true

# Handle tower collapse event
func _on_tower_collapsed():
	# Stop checking for collapses
	if not collapse_timer.is_stopped():
		collapse_timer.stop()
	
	# Play collapse sound
	if SoundManager.has_method("play"):
		SoundManager.play("tower_collapse")
	
	# Apply stronger camera shake
	if camera.has_method("shake"):
		camera.shake(camera_shake_intensity * 3, camera_shake_duration * 2)
	
	# Create tower collapse effect at tower center
	var collapse_effect = tower_collapse_effect_scene.instantiate()
	add_child(collapse_effect)
	collapse_effect.global_position = tower_center
	collapse_effect.play()
	
	# Complete the level after a short delay
	await get_tree().create_timer(2.0).timeout
	_complete_level()

# Game timer callback
func _on_game_timer_timeout():
	if finished:
		return
	
	time_elapsed += 1
	update_timer_display()
	
	# Check for time limit
	if current_level_data.has("time_limit") and time_elapsed >= current_level_data.time_limit:
		# Time's up - complete the level
		_complete_level()

# Stability timer callback
func _on_stability_timer_timeout():
	# Check if any block is still moving
	for tower_block in tower_blocks:
		if is_instance_valid(tower_block) and not tower_block.is_settled():
			# Tower is still moving, check again later
			stability_timer.start()
			return
	
	# All blocks are stable, allow removing blocks again
	can_remove_blocks = true
	
	# Enable hovering on blocks again
	for tower_block in tower_blocks:
		if is_instance_valid(tower_block) and tower_block.highlight_on_hover:
			tower_block.highlight_on_hover = true

# Collapse timer callback
func _on_collapse_timer_timeout():
	_check_tower_collapse()
	
	# If tower hasn't collapsed, check again in 1 second
	if not tower_collapsed:
		collapse_timer.start()

# Block hit callback
func _on_block_hit(block, other_block):
	# Disable highlighting and block removal while physics is happening
	can_remove_blocks = false
	
	for tower_block in tower_blocks:
		if is_instance_valid(tower_block):
			tower_block.highlight_on_hover = false
	
	# Apply a small camera shake based on impact velocity
	if is_instance_valid(block) and is_instance_valid(other_block):
		var relative_velocity = (block.linear_velocity - other_block.linear_velocity).length()
		
		if relative_velocity > 1.5 and camera.has_method("shake"):
			var intensity = clamp(relative_velocity / 10.0, 0.05, 0.3)
			var duration = clamp(relative_velocity / 15.0, 0.2, 0.5)
			camera.shake(intensity, duration)
	
	# Start stability check
	stability_timer.start()

# Block settled callback
func _on_block_settled(block, is_stable):
	# Once blocks have settled, check for tower collapse
	_check_tower_collapse()

# Handle block selection events
func _on_block_selected(block):
	if is_instance_valid(block):
		selected_block = block
		
		# Shake the camera slightly when a block is selected
		if camera.has_method("add_trauma"):
			camera.add_trauma(camera_shake_intensity * 0.3)
		
		# Play selection sound
		if SoundManager.has_method("play"):
			SoundManager.play("block_select")

# Handle block removal events
func _on_block_removed(block):
	if is_instance_valid(block):
		# Update score and block count
		blocks_removed += 1
		
		# Update score (more points for higher blocks)
		var height_bonus = int(block.global_position.y * 10)
		var points = 100 + height_bonus
		current_score += points
		
		# Update UI
		update_score_display()
		update_blocks_removed_display()
		
		# Create dust effect
		if is_instance_valid(dust_particles_scene):
			var dust = dust_particles_scene.instantiate()
			if dust:
				get_tree().get_root().add_child(dust)
				dust.global_position = block.global_position
				
				# Configure dust for block removal
				if dust.has_method("configure_for_removal"):
					dust.configure_for_removal()
				elif dust.has_method("emitting"):
					dust.emitting = true
		
		# Shake camera based on block height
		if camera.has_method("add_trauma"):
			var height_factor = min(block.global_position.y / 10.0, 1.0)
			camera.add_trauma(camera_shake_intensity * (0.5 + height_factor))
		
		# Play removal sound
		if SoundManager.has_method("play"):
			SoundManager.play("block_remove")
			
		# Allow the tower to settle after block removal
		can_remove_blocks = false
		selected_block = null
		
		# Start stability timer to check when tower settles
		stability_timer.start()
		
		# Check if level is complete (all blocks removed or goal reached)
		if blocks_removed >= current_level_data.max_blocks_to_remove:
			_complete_level()

# Complete the level
func _complete_level():
	if finished:
		return
		
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
	
	# Star calculation based on level requirements
	for star_req in current_level_data.stars:
		var requirement = star_req.requirement
		var value = star_req.value
		
		if requirement == "blocks_removed" and blocks_removed >= value:
			stars += 1
		elif requirement == "time" and time_elapsed <= value:
			stars += 1
		elif requirement == "tower_height" and blocks_removed >= value:
			stars += 1
	
	return stars

# Save level progress
func _save_progress():
	# Report progress to GameManager
	if GameManager.has_method("complete_level"):
		GameManager.complete_level(current_level_id, final_stars, current_score, time_elapsed, blocks_removed)

# Show level completion screen
func _show_completion_screen():
	# Pause the game
	pause_physics = true
	
	# Add a victory camera effect
	if camera.has_method("shake"):
		# A gentle, celebratory shake
		camera.shake(0.1, 1.0)
	
	# Emit completion signal
	emit_signal("level_completed", final_stars, current_score, time_elapsed, blocks_removed)
	
	# Load and show completion screen
	var level_complete = load("res://scenes/level_complete.tscn").instantiate()
	level_complete.setup(final_stars, current_score, time_elapsed, blocks_removed)
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
	
	# Update blocks removed
	blocks_removed_label.text = "Blocks: " + str(blocks_removed)
	
	# Update timer
	update_timer_display()

# Update score display
func update_score_display():
	score_label.text = "Score: " + str(current_score)

# Update blocks removed display
func update_blocks_removed_display():
	blocks_removed_label.text = "Blocks: " + str(blocks_removed)

# Update timer display
func update_timer_display():
	var minutes = int(time_elapsed) / 60
	var seconds = int(time_elapsed) % 60
	timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

# Physics process
func _physics_process(delta):
	if pause_physics:
		return
		
	# Highlight block under mouse cursor
	if game_started and not finished and not selected_block:
		_update_hover_highlight()

# Update hover highlight
func _update_hover_highlight():
	if not can_remove_blocks:
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Cast ray from camera to mouse position
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 100
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	
	var result = space_state.intersect_ray(query)
	if result and result.collider in tower_blocks:
		# Only highlight if block is allowed to be highlighted and selectable
		if result.collider.highlight_on_hover and result.collider.is_selectable:
			result.collider.highlight(true)
			
			# Unhighlight other blocks
			for tower_block in tower_blocks:
				if tower_block != result.collider and is_instance_valid(tower_block) and not tower_block.is_selected:
					tower_block.highlight(false)
	else:
		# No block under cursor, clear all highlights
		for tower_block in tower_blocks:
			if is_instance_valid(tower_block) and not tower_block.is_selected:
				tower_block.highlight(false)
