extends Node3D
# Main Game Screen - Handles game mechanics, block placement and physics

signal game_over
signal level_complete(score, moves, time, stars)

# Block scene
const BlockScene = preload("res://scenes/objects/block.tscn")

# Game variables
var current_level = null
var blocks = []
var current_block = null
var preview_block = null
var can_place_block = true
var is_game_active = false
var highest_block_y = 0.0
var camera_target_position = Vector3.ZERO
var camera_height_offset = 5.0
var ray_length = 100.0
var blocks_container = null
var camera_pivot = null
var main_camera = null
var placement_area = null
var difficulty_factor = 1.0

# Called when the node enters the scene tree for the first time
func _ready():
	# Get references to important nodes
	blocks_container = $BlocksContainer
	camera_pivot = $CameraPivot
	main_camera = $CameraPivot/Camera3D
	placement_area = $PlacementArea
	
	# Connect signals
	GameManager.game_state_changed.connect(_on_game_state_changed)
	
	# Setup initial camera position
	update_camera_position()
	
	# Start with game paused
	Engine.time_scale = 0.0

# Load a level for play
func load_level(level_data):
	current_level = level_data
	reset_game()
	
	# Set physics properties from level if available
	if current_level.has("physics"):
		if current_level.physics.has("gravity"):
			var gravity = current_level.physics.gravity
			PhysicsServer3D.area_set_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, gravity)
	
	# Create static blocks from level data
	if current_level.has("blocks"):
		for block_data in current_level.blocks:
			create_block_from_data(block_data)
	
	# Create initial preview block
	create_preview_block()
	
	# Start game
	is_game_active = true
	GameManager.start_game(current_level.id)

# Reset the game state
func reset_game():
	# Clear all existing blocks
	for block in blocks:
		if is_instance_valid(block):
			block.queue_free()
	
	blocks.clear()
	current_block = null
	
	if is_instance_valid(preview_block):
		preview_block.queue_free()
	
	preview_block = null
	
	can_place_block = true
	highest_block_y = 0.0
	update_camera_position()
	
	# Reset game metrics
	GameManager.reset_game_state()

# Create a block from level data
func create_block_from_data(block_data):
	var block_instance = BlockScene.instantiate()
	block_instance.block_type = block_data.type if block_data.has("type") else "wood"
	
	if block_data.has("size"):
		block_instance.custom_size = Vector3(block_data.size[0], block_data.size[1], block_data.size[2])
	
	if block_data.has("is_static"):
		block_instance.is_static = block_data.is_static
	
	blocks_container.add_child(block_instance)
	
	# Set position and rotation
	if block_data.has("position"):
		block_instance.global_position = Vector3(block_data.position[0], block_data.position[1], block_data.position[2])
	
	if block_data.has("rotation"):
		block_instance.global_rotation_degrees = Vector3(block_data.rotation[0], block_data.rotation[1], block_data.rotation[2])
	
	# Connect signals
	block_instance.block_placed.connect(_on_block_placed.bind(block_instance))
	block_instance.block_hit.connect(_on_block_hit.bind(block_instance))
	block_instance.block_settled.connect(_on_block_settled.bind(block_instance))
	
	blocks.append(block_instance)
	return block_instance

# Create a preview block that follows the mouse
func create_preview_block():
	preview_block = BlockScene.instantiate()
	preview_block.block_type = "wood" # Default type
	preview_block.is_preview = true
	preview_block.custom_size = Vector3(1, 1, 1) # Default size
	blocks_container.add_child(preview_block)
	
	# Starting position over the placement area
	preview_block.global_position = Vector3(0, 5, 0)

# Process mouse movement for block placement
func _process(_delta):
	if not is_game_active or not is_instance_valid(preview_block):
		return
	
	# Handle preview block movement
	if can_place_block:
		move_preview_block()
	
	# Handle camera rotation with right mouse button
	if Input.is_action_pressed("camera_rotate"):
		var mouse_movement = Input.get_last_mouse_velocity() * 0.001
		camera_pivot.rotate_y(-mouse_movement.x)

# Move the preview block based on mouse position
func move_preview_block():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = main_camera.project_ray_origin(mouse_pos)
	var ray_to = ray_from + main_camera.project_ray_normal(mouse_pos) * ray_length
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [preview_block]
	
	var intersection = space_state.intersect_ray(query)
	
	if intersection and intersection.has("position"):
		# Position the block on top of the placement area
		var placement_pos = intersection.position
		placement_pos.y += preview_block.custom_size.y / 2.0
		preview_block.global_position = placement_pos
		
		# Apply snapping to a grid if needed
		if Input.is_action_pressed("ui_ctrl"):
			preview_block.global_position.x = round(preview_block.global_position.x)
			preview_block.global_position.z = round(preview_block.global_position.z)
	
	# Handle block rotation with keys
	if Input.is_key_pressed(KEY_Q):
		preview_block.rotate_y(0.02)
	elif Input.is_key_pressed(KEY_E):
		preview_block.rotate_y(-0.02)

# Handle input for block placement and other game actions
func _input(event):
	if not is_game_active:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and can_place_block:
			place_current_block()
	
	# Handle block type switching with number keys
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				switch_block_type("wood")
			KEY_2:
				switch_block_type("stone")
			KEY_3:
				switch_block_type("metal")
			KEY_4:
				switch_block_type("ice")
			KEY_5:
				switch_block_type("glass")
			KEY_6:
				switch_block_type("rubber")
			KEY_R:
				if can_place_block:
					reset_game()
					GameManager.start_game(current_level.id)

# Switch the preview block type
func switch_block_type(type):
	if is_instance_valid(preview_block) and can_place_block:
		preview_block.set_block_type(type)

# Place the current block in the world
func place_current_block():
	if not is_instance_valid(preview_block):
		return
	
	# Create a new physical block at the position of the preview
	current_block = BlockScene.instantiate()
	current_block.block_type = preview_block.block_type
	current_block.custom_size = preview_block.custom_size
	current_block.global_position = preview_block.global_position
	current_block.global_rotation = preview_block.global_rotation
	blocks_container.add_child(current_block)
	
	# Connect signals
	current_block.block_placed.connect(_on_block_placed.bind(current_block))
	current_block.block_hit.connect(_on_block_hit.bind(current_block))
	current_block.block_settled.connect(_on_block_settled.bind(current_block))
	
	# Place the block and make it physical
	current_block.place()
	blocks.append(current_block)
	
	# Temporarily disable placement until this block settles
	can_place_block = false
	preview_block.visible = false
	
	# Increment move counter
	GameManager.add_move()
	
	# Add score based on height and difficulty
	var height_score = int(current_block.global_position.y * 10.0)
	GameManager.add_score(height_score)
	
	# Adjust camera to follow the action
	check_block_height(current_block)

# Check and update the highest block position
func check_block_height(block):
	var block_y = block.global_position.y + (block.custom_size.y / 2.0)
	if block_y > highest_block_y:
		highest_block_y = block_y
		update_camera_position()
		
		# Check win condition
		check_win_condition()

# Update camera position based on highest block
func update_camera_position():
	camera_target_position.y = highest_block_y + camera_height_offset
	camera_pivot.position = camera_target_position

# Check if the win condition has been met
func check_win_condition():
	if not current_level or not current_level.has("win_condition"):
		return
	
	# Different types of win conditions
	match current_level.win_condition.type:
		"height":
			var target_height = current_level.win_condition.value
			if highest_block_y >= target_height:
				complete_level()
		"score":
			var target_score = current_level.win_condition.value
			if GameManager.score >= target_score:
				complete_level()
		# Add more win condition types as needed

# Complete the current level
func complete_level():
	is_game_active = false
	
	# Calculate stars based on score
	var stars = LevelManager.calculate_stars(GameManager.score)
	GameManager.stars_earned = stars
	
	# Save progress
	GameManager.complete_level()
	
	# Emit signal with level results
	emit_signal("level_complete", GameManager.score, GameManager.moves, GameManager.timer, stars)

# End the game (player loses)
func game_over():
	is_game_active = false
	GameManager.game_over()
	emit_signal("game_over")

# Signal handlers
func _on_block_placed(block):
	# When a block is placed, it becomes physical
	pass

func _on_block_hit(block, _other_block):
	# When blocks collide
	SoundManager.play("block_hit")

func _on_block_settled(block, is_stable):
	if is_stable:
		# Block has stabilized, allow placing next block
		can_place_block = true
		preview_block.visible = true
		
		# Check if we need to adjust the camera
		check_block_height(block)

func _on_game_state_changed(new_state):
	match new_state:
		GameManager.GameState.PLAYING:
			is_game_active = true
		GameManager.GameState.PAUSED, GameManager.GameState.GAME_OVER, GameManager.GameState.LEVEL_COMPLETE:
			is_game_active = false
