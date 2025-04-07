extends Button
# Level Button - Simple, reliable implementation

signal level_selected(level_id)

var level_id: String = ""
var level_name: String = "Level"
var level_description: String = ""
var star_count: int = 0
var is_locked: bool = false

func _ready():
	# Connect our pressed signal
	pressed.connect(_on_pressed)
	
	# Update appearance
	text = level_name
	disabled = is_locked
	
	if is_locked:
		modulate = Color(0.5, 0.5, 0.5, 0.7)
	else:
		modulate = Color(1, 1, 1, 1)

func _on_pressed():
	if SoundManager != null and SoundManager.has_method("play"):
		SoundManager.play("click")
	
	print("Level button pressed: ", level_id)
	emit_signal("level_selected", level_id)

# Public method to configure the button
func configure(l_id: String, l_name: String, l_desc: String, stars: int, locked: bool):
	level_id = l_id
	level_name = l_name
	level_description = l_desc
	star_count = stars
	is_locked = locked
	
	# Update UI
	text = level_name
	disabled = is_locked
	
	if is_locked:
		modulate = Color(0.5, 0.5, 0.5, 0.7)
	else:
		modulate = Color(1, 1, 1, 1)
