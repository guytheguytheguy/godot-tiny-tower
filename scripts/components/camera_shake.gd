extends Camera3D
# Camera shake effect component

var shake_amount: float = 0.0
var shake_duration: float = 0.0
var shake_remaining: float = 0.0
var shake_noise: FastNoiseLite
var noise_y: float = 0.0
var original_position: Vector3
var original_rotation: Vector3

func _ready():
	# Initialize noise generator for natural shake
	shake_noise = FastNoiseLite.new()
	shake_noise.seed = randi()
	shake_noise.frequency = 4.0
	shake_noise.fractal_octaves = 2
	
	# Store original position/rotation
	original_position = position
	original_rotation = rotation_degrees

# Called every frame during active shake
func _process(delta):
	if shake_remaining > 0:
		# Decrease shake timer
		shake_remaining -= delta
		
		# Calculate shake intensity based on remaining time
		var current_amount = shake_amount * (shake_remaining / shake_duration)
		
		# Apply procedural noise-based shake
		noise_y += delta * 10.0  # Scroll through noise
		
		# Create shake offsets using noise for natural feel
		var offset_x = shake_noise.get_noise_2d(noise_y, 0.0) * current_amount
		var offset_y = shake_noise.get_noise_2d(0.0, noise_y) * current_amount
		var offset_z = shake_noise.get_noise_2d(noise_y, noise_y) * current_amount * 0.5
		
		# Apply shake to position
		position = original_position + Vector3(offset_x, offset_y, offset_z)
		
		# Add subtle rotation shake
		rotation_degrees = original_rotation + Vector3(
			offset_y * 0.3, 
			offset_x * 0.3,
			offset_z * 0.2
		)
		
		# Reset when shake is done
		if shake_remaining <= 0:
			_reset_shake()
			
# Begin a camera shake effect
func shake(amount: float, duration: float):
	# Only start a new shake if it's stronger than the current one
	if amount > shake_amount or shake_remaining <= 0:
		# Save original position if we're starting a new shake
		if shake_remaining <= 0:
			original_position = position
			original_rotation = rotation_degrees
			
		# Set shake parameters
		shake_amount = amount
		shake_duration = duration
		shake_remaining = duration
		
		# Enable processing
		set_process(true)

# Reset camera after shake
func _reset_shake():
	shake_amount = 0
	shake_remaining = 0
	position = original_position
	rotation_degrees = original_rotation
	set_process(false)

# Stop shake immediately
func stop_shake():
	_reset_shake()
