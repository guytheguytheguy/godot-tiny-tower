extends Control
# Main Menu - The starting point of the game

# UI Animation parameters
var animation_player: AnimationPlayer
var tween: Tween

# Called when the node enters the scene tree for the first time
func _ready():
	# Ensure game is in menu state
	GameManager.set_state(GameManager.GameState.MENU)
	
	# Play menu music
	SoundManager.play_music("menu")
	
	# Setup animation player
	animation_player = $AnimationPlayer
	if animation_player:
		animation_player.play("menu_appear")
	
	# Connect button signals
	$Buttons/PlayButton.pressed.connect(_on_play_button_pressed)
	$Buttons/SettingsButton.pressed.connect(_on_settings_button_pressed)
	$Buttons/CreditsButton.pressed.connect(_on_credits_button_pressed)
	$Buttons/QuitButton.pressed.connect(_on_quit_button_pressed)
	
	# Show any first-time welcome messages or tutorials if needed
	check_first_time_player()

# Handle button press sounds
func _on_button_pressed():
	SoundManager.play("click")

# Check if this is the first time playing
func check_first_time_player():
	var progress = DataManager.load_progress()
	if not progress or not progress.has("levels") or progress.levels.is_empty():
		show_tutorial()

# Show the game tutorial
func show_tutorial():
	$TutorialPanel.visible = true

# Handle play button
func _on_play_button_pressed():
	_on_button_pressed()
	
	# Create a nice transition
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func():
		# Change to level select scene
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
	)

# Handle settings button
func _on_settings_button_pressed():
	_on_button_pressed()
	$SettingsPanel.visible = true

# Handle credits button
func _on_credits_button_pressed():
	_on_button_pressed()
	$CreditsPanel.visible = true

# Handle quit button
func _on_quit_button_pressed():
	_on_button_pressed()
	
	# Create a nice fade out
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func():
		get_tree().quit()
	)

# Close any open panels when their close buttons are pressed
func _on_panel_close_pressed():
	_on_button_pressed()
	$SettingsPanel.visible = false
	$CreditsPanel.visible = false
	$TutorialPanel.visible = false
