extends Control
# Game HUD - In-game user interface showing score, time, and controls

# UI elements
var score_value: Label
var moves_value: Label
var time_value: Label
var block_buttons: GridContainer
var block_button_scene = preload("res://scenes/ui/block_button.tscn")
var block_buttons_dict = {}
var pause_button: Button
var restart_button: Button
var menu_button: Button

var currently_selected_block_type = "wood"
var game_screen: Node = null

# Called when the node enters the scene tree for the first time
func _ready():
	# Get references to UI elements
	score_value = $TopPanel/HBoxContainer/ScoreContainer/ScoreValue
	moves_value = $TopPanel/HBoxContainer/MovesContainer/MovesValue
	time_value = $TopPanel/HBoxContainer/TimeContainer/TimeValue
	block_buttons = $BlockTypesPanel/VBoxContainer/BlockButtons
	pause_button = $PauseButton
	restart_button = $RestartButton
	menu_button = $MenuButton
	
	# Get reference to the game screen
	game_screen = get_parent()
	
	# Connect signals
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.moves_updated.connect(_on_moves_updated)
	GameManager.timer_updated.connect(_on_timer_updated)
	pause_button.pressed.connect(_on_pause_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	# Create block type buttons
	create_block_buttons()

# Create buttons for each available block type
func create_block_buttons():
	# Clear existing buttons
	for child in block_buttons.get_children():
		child.queue_free()
	block_buttons_dict.clear()
	
	# Get available block types from the current level
	var available_blocks = ["wood", "stone"]  # Default blocks
	if game_screen and game_screen.current_level and game_screen.current_level.has("available_blocks"):
		available_blocks = game_screen.current_level.available_blocks
	
	# Create a button for each available block type
	for block_type in available_blocks:
		# Create the button
		var button = TextureButton.new()
		block_buttons.add_child(button)
		
		# Set button size
		button.custom_minimum_size = Vector2(64, 64)
		
		# Create block preview texture
		var texture_path = "res://assets/textures/blocks/" + block_type + "_icon.png"
		if ResourceLoader.exists(texture_path):
			button.texture_normal = load(texture_path)
		
		# Store button reference
		block_buttons_dict[block_type] = button
		
		# Connect signal
		button.pressed.connect(_on_block_type_button_pressed.bind(block_type))
		
		# Set initial selection state
		if block_type == currently_selected_block_type:
			_highlight_selected_button(button)
	
	# Make wood the default selected type if available
	if block_buttons_dict.has("wood"):
		currently_selected_block_type = "wood"
		_highlight_selected_button(block_buttons_dict["wood"])

# Highlight the selected block type button
func _highlight_selected_button(selected_button):
	for button in block_buttons_dict.values():
		if button == selected_button:
			button.modulate = Color(1.5, 1.5, 1.5, 1)
			button.scale = Vector2(1.1, 1.1)
		else:
			button.modulate = Color(1, 1, 1, 1)
			button.scale = Vector2(1, 1)

# Format time as MM:SS
func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

# Signal handlers
func _on_score_updated(new_score):
	score_value.text = str(new_score)

func _on_moves_updated(new_moves):
	moves_value.text = str(new_moves)

func _on_timer_updated(new_time):
	time_value.text = format_time(new_time)

func _on_block_type_button_pressed(block_type):
	SoundManager.play("click")
	currently_selected_block_type = block_type
	
	# Highlight the selected button
	if block_buttons_dict.has(block_type):
		_highlight_selected_button(block_buttons_dict[block_type])
	
	# Tell the game screen to change the preview block type
	if game_screen and game_screen.has_method("switch_block_type"):
		game_screen.switch_block_type(block_type)

func _on_pause_button_pressed():
	SoundManager.play("click")
	GameManager.pause_game()

func _on_restart_button_pressed():
	SoundManager.play("click")
	if game_screen and game_screen.has_method("reset_game"):
		game_screen.reset_game()
		if game_screen.current_level:
			GameManager.start_game(game_screen.current_level.id)

func _on_menu_button_pressed():
	SoundManager.play("click")
	
	# Ask for confirmation
	var confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.dialog_text = "Return to level select? Current progress will be lost."
	confirm_dialog.get_ok_button().text = "Yes"
	confirm_dialog.get_cancel_button().text = "No"
	add_child(confirm_dialog)
	
	# Connect confirmation signal
	confirm_dialog.confirmed.connect(func():
		# Return to level select
		GameManager.return_to_menu()
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
	)
	
	confirm_dialog.popup_centered()
