extends Panel
# Level Button - Used in level select screen to display and select levels

signal level_selected(level_id)

@export var level_id: String = ""
@export var level_name: String = "Level"
@export var level_description: String = ""
@export var star_count: int = 0
@export var is_locked: bool = true

# UI elements
var name_label: Label
var stars_container: HBoxContainer
var lock_icon: TextureRect
var description_label: Label
var button: Button

# Called when the node enters the scene tree for the first time
func _ready():
	# Get references to UI elements
	name_label = $VBoxContainer/TopRow/NameLabel
	stars_container = $VBoxContainer/StarsContainer
	lock_icon = $LockIcon
	description_label = $VBoxContainer/DescriptionLabel
	button = $Button
	
	# Connect button signal
	button.pressed.connect(_on_button_pressed)
	
	# Update UI with level data
	update_ui()

# Update the UI elements to display level information
func update_ui():
	# Set level name
	name_label.text = level_name
	
	# Set description
	description_label.text = level_description
	
	# Show or hide lock
	lock_icon.visible = is_locked
	
	# Button is disabled if level is locked
	button.disabled = is_locked
	
	# Update stars display
	update_stars()
	
	# Change appearance based on locked status
	if is_locked:
		modulate = Color(0.7, 0.7, 0.7, 0.8)
		name_label.modulate = Color(0.7, 0.7, 0.7)
		description_label.modulate = Color(0.7, 0.7, 0.7, 0.5)
	else:
		modulate = Color(1, 1, 1, 1)
		name_label.modulate = Color(1, 1, 1)
		description_label.modulate = Color(1, 1, 1, 0.8)

# Update the stars display
func update_stars():
	# Clear existing stars
	for child in stars_container.get_children():
		child.queue_free()
	
	# Add stars based on count (max 3)
	for i in range(3):
		var star = TextureRect.new()
		stars_container.add_child(star)
		
		# Set star texture based on whether it's earned
		if i < star_count:
			star.texture = preload("res://assets/textures/ui/star_filled.png")
		else:
			star.texture = preload("res://assets/textures/ui/star_empty.png")
		
		# Set star size
		star.custom_minimum_size = Vector2(24, 24)
		star.expand_mode = TextureRect.EXPAND_KEEP_ASPECT
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

# Button press handler
func _on_button_pressed():
	SoundManager.play("click")
	emit_signal("level_selected", level_id)

# Optional hover effects
func _on_button_mouse_entered():
	if not is_locked:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_button_mouse_exited():
	if not is_locked:
		var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1, 1), 0.1)
