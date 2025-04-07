extends Control
# Main Menu - First screen players see when starting the game

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var settings_button = $CenterContainer/VBoxContainer/SettingsButton
@onready var credits_button = $CenterContainer/VBoxContainer/CreditsButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton
@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null

var tween: Tween = null

# Called when the node enters the scene tree for the first time
func _ready():
	# Ensure game is in menu state
	GameManager.set_state(GameManager.GameState.MENU)
	
	# Setup button connections
	if play_button:
		play_button.pressed.connect(_on_play_button_pressed)
	
	if settings_button:
		settings_button.pressed.connect(_on_settings_button_pressed)
	
	if credits_button:
		credits_button.pressed.connect(_on_credits_button_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	
	# Play background music
	if SoundManager != null and SoundManager.has_method("play_music"):
		SoundManager.play_music("menu")
	
	# Play animation if available
	if animation_player and animation_player.has_animation("menu_appear"):
		animation_player.play("menu_appear")
	
	# Load latest settings
	_load_settings()

	# Show any first-time welcome messages or tutorials if needed
	check_first_time_player()

# Load saved settings
func _load_settings():
	if DataManager == null or not DataManager.has_method("load_settings"):
		return
		
	var settings = DataManager.load_settings()
	if settings:
		# Apply saved settings
		if settings.has("sound_volume") and SoundManager != null and SoundManager.has_method("set_sound_volume"):
			SoundManager.set_sound_volume(settings["sound_volume"])
		
		if settings.has("music_volume") and SoundManager != null and SoundManager.has_method("set_music_volume"):
			SoundManager.set_music_volume(settings["music_volume"])

# Check if this is the first time playing
func check_first_time_player():
	var progress = DataManager.load_progress() if DataManager != null and DataManager.has_method("load_progress") else null
	if not progress or not progress.has("levels") or progress.levels.is_empty():
		show_tutorial()

# Show the game tutorial
func show_tutorial():
	if has_node("TutorialPanel"):
		$TutorialPanel.visible = true

# Button handlers
func _on_play_button_pressed():
	if SoundManager != null and SoundManager.has_method("play"):
		SoundManager.play("click")
	
	# Create a nice transition
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func():
		# Change to level select screen
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
	)

func _on_settings_button_pressed():
	if SoundManager != null and SoundManager.has_method("play"):
		SoundManager.play("click")
	
	# Show settings panel (not implemented yet)
	var settings_panel = load("res://scenes/ui/settings_panel.tscn").instantiate() if FileAccess.file_exists("res://scenes/ui/settings_panel.tscn") else null
	if settings_panel:
		add_child(settings_panel)

func _on_credits_button_pressed():
	if SoundManager != null and SoundManager.has_method("play"):
		SoundManager.play("click")
	
	# Show credits panel (not implemented yet)
	var credits_panel = load("res://scenes/ui/credits_panel.tscn").instantiate() if FileAccess.file_exists("res://scenes/ui/credits_panel.tscn") else null
	if credits_panel:
		add_child(credits_panel)

func _on_quit_button_pressed():
	if SoundManager != null and SoundManager.has_method("play"):
		SoundManager.play("click")
	
	# Create a nice fade out
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(func():
		# Confirm quit with dialog
		var dialog = ConfirmationDialog.new()
		dialog.title = "Confirm Quit"
		dialog.dialog_text = "Are you sure you want to quit?"
		dialog.get_ok_button().text = "Yes"
		dialog.get_cancel_button().text = "No"
		dialog.confirmed.connect(func(): get_tree().quit())
		add_child(dialog)
		dialog.popup_centered()
	)

# Close any open panels when their close buttons are pressed
func _on_panel_close_pressed():
	if SoundManager != null and SoundManager.has_method("play"):
		SoundManager.play("click")
	
	if has_node("SettingsPanel"):
		$SettingsPanel.visible = false
	if has_node("CreditsPanel"):
		$CreditsPanel.visible = false
	if has_node("TutorialPanel"):
		$TutorialPanel.visible = false
