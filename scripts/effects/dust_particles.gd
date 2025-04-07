extends GPUParticles3D
# Enhanced dust particles with configurable parameters

# Configure emission properties
@export var default_amount: int = 40
@export var default_lifetime: float = 1.5
@export var default_explosiveness: float = 0.8
@export var default_velocity_min: float = 1.0
@export var default_velocity_max: float = 3.0

# Called when the node enters the scene tree for the first time
func _ready():
	# Initialize with defaults
	amount = default_amount
	lifetime = default_lifetime
	explosiveness = default_explosiveness
	emitting = false

# Start particles emission
func play():
	emitting = true

# Configure particles for different impact levels
func configure_for_impact(impact_force: float):
	# Scale parameters based on impact force
	var force_factor = clamp(impact_force / 10.0, 0.5, 2.0)
	
	# Adjust particle properties based on impact
	amount = int(default_amount * force_factor)
	lifetime = default_lifetime * sqrt(force_factor)
	explosiveness = min(default_explosiveness * force_factor, 0.95)
	
	# Adjust process material properties
	if process_material:
		# Increase velocity for bigger impacts
		process_material.initial_velocity_min = default_velocity_min * force_factor
		process_material.initial_velocity_max = default_velocity_max * force_factor
		
		# Adjust spread for bigger impacts
		process_material.spread = 60.0 + (force_factor - 1.0) * 30.0
		
		# Modify color to be slightly darker for heavier impacts
		var base_color = Color(0.886, 0.792, 0.651, 1.0)
		var darkened = base_color.darkened(0.1 * (force_factor - 1.0))
		process_material.color = darkened

# Configure for light dust from block movement
func configure_for_movement():
	amount = int(default_amount * 0.5)
	lifetime = default_lifetime * 0.7
	explosiveness = 0.5
	
	if process_material:
		process_material.initial_velocity_min = default_velocity_min * 0.5
		process_material.initial_velocity_max = default_velocity_max * 0.5
		process_material.spread = 40.0
		
		# Lighter color and more transparent
		var light_color = Color(0.886, 0.792, 0.651, 0.7)
		process_material.color = light_color

# Configure for tower collapse (large dust cloud)
func configure_for_collapse():
	amount = default_amount * 3
	lifetime = default_lifetime * 2.0
	explosiveness = 0.9
	
	if process_material:
		process_material.initial_velocity_min = default_velocity_min * 2.0
		process_material.initial_velocity_max = default_velocity_max * 2.5
		process_material.spread = 90.0
		
		# Darker, dense dust
		var dense_color = Color(0.886, 0.792, 0.651, 1.0).darkened(0.2)
		process_material.color = dense_color
