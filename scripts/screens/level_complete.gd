extends Control
# Level Complete Screen - Shown when a player completes a level

signal menu_selected
signal replay_selected
signal next_level_selected

var animation_player: AnimationPlayer
var tween: Tween
var stars_container: HBoxContainer
var score_value: Label
var moves_value: Label
var time_value: Label
var next_button: Button

var level_id: String = ""
var score: int = 0
var moves: int = 0
var time_seconds: float = 0
var stars: int = 0
var has_next_level: bool = false

# Called when the node enters the scene tree for the first time
func _ready():
	# Get references to UI elements
	animation_player = $AnimationPlayer
	stars_container = $ContentPanel/VBoxContainer/StarsContainer
	score_value = $ContentPanel/VBoxContainer/StatsContainer/ScoreContainer/ScoreValue
	moves_value = $ContentPanel/VBoxContainer/StatsContainer/MovesContainer/MovesValue
	time_value = $ContentPanel/VBoxContainer/StatsContainer/TimeContainer/TimeValue
	next_button = $ContentPanel/VBoxContainer/ButtonsContainer/NextButton
	
	# Connect button signals
	$ContentPanel/VBoxContainer/ButtonsContainer/NextButton.pressed.connect(_on_next_button_pressed)
	$ContentPanel/VBoxContainer/ButtonsContainer/RetryButton.pressed.connect(_on_retry_button_pressed)
	$ContentPanel/VBoxContainer/ButtonsContainer/MenuButton.pressed.connect(_on_menu_button_pressed)
	
	# Start with next button hidden until we check if there's a next level
	next_button.visible = false
	
	# Play victory music
	SoundManager.play("level_complete")
	SoundManager.play_music("bgm_victory")
	
	# Show the screen with animation
	if animation_player:
		animation_player.play("screen_appear")

# Initialize with level results
func initialize(p_level_id: String, p_score: int, p_moves: int, p_time: float, p_stars: int):
	level_id = p_level_id
	score = p_score
	moves = p_moves
	time_seconds = p_time
	stars = p_stars
	
	# Check if there's a next level
	var next_level_id = LevelManager.get_next_level_id()
	has_next_level = !next_level_id.is_empty()
	
	# Update UI
	update_ui()

# Update the UI with level results
func update_ui():
	# Set statistics
	score_value.text = str(score)
	moves_value.text = str(moves)
	time_value.text = format_time(time_seconds)
	
	# Handle next button
	next_button.visible = has_next_level
	
	# Clear existing stars
	for child in stars_container.get_children():
		child.queue_free()
	
	# Add and animate stars
	for i in range(3):
		var star_container = Control.new()
		stars_container.add_child(star_container)
		
		var star = TextureRect.new()
		star_container.add_child(star)
		
		# Configure star
		star.custom_minimum_size = Vector2(64, 64)
		star.expand_mode = TextureRect.EXPAND_KEEP_ASPECT
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.pivot_offset = Vector2(32, 32)  # Set pivot to center for rotation
		
		# Set star texture based on whether it's earned
		if i < stars:
			star.texture = preload("res://assets/textures/ui/star_filled.png")
			
			# Animate star appearance
			star.scale = Vector2.ZERO
			var star_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			star_tween.tween_property(star, "scale", Vector2(1, 1), 0.5).set_delay(i * 0.7)
			
			# Play sound effect with delay
			call_deferred("_play_delayed_star_sound", i * 0.7)
		else:
			star.texture = preload("res://assets/textures/ui/star_empty.png")
			star.modulate = Color(0.5, 0.5, 0.5, 0.5)

# Play star sound with delay
func _play_delayed_star_sound(delay):
	await get_tree().create_timer(delay).timeout
	SoundManager.play("star_earned")

# Format time as MM:SS
func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

# Button handlers
func _on_next_button_pressed():
	SoundManager.play("click")
	emit_signal("next_level_selected")
	transition_out()

func _on_retry_button_pressed():
	SoundManager.play("click")
	emit_signal("replay_selected")
	transition_out()

func _on_menu_button_pressed():
	SoundManager.play("click")
	emit_signal("menu_selected")
	transition_out()

# Transition out animation
func transition_out():
	if animation_player and animation_player.has_animation("screen_disappear"):
		animation_player.play("screen_disappear")
		await animation_player.animation_finished
		queue_free()
	else:
		# Fallback fade out
		if tween:
			tween.kill()
		tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
		tween.tween_callback(func(): queue_free())
