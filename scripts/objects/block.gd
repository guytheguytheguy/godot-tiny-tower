extends RigidBody3D
# Block - Physics object that players stack to build towers

signal block_placed
signal block_hit(other_block)
signal block_settled(is_stable)

# Block types with their properties
const BLOCK_TYPES = {
	"wood": {
		"mass": 2.0,
		"friction": 0.7,
		"restitution": 0.3,
		"color": Color(0xa0, 0x6d, 0x43),
		"emissive": false,
		"texture": "res://assets/textures/blocks/wood.png",
		"sound_type": "wood"
	},
	"stone": {
		"mass": 5.0,
		"friction": 0.8,
		"restitution": 0.2,
		"color": Color(0x8c, 0x8c, 0x8c),
		"emissive": false,
		"texture": "res://assets/textures/blocks/stone.png",
		"sound_type": "stone"
	},
	"metal": {
		"mass": 8.0,
		"friction": 0.6,
		"restitution": 0.5,
		"color": Color(0x90, 0x90, 0x90),
		"emissive": false,
		"texture": "res://assets/textures/blocks/metal.png",
		"sound_type": "metal"
	},
	"ice": {
		"mass": 1.5,
		"friction": 0.1,
		"restitution": 0.8,
		"color": Color(0xad, 0xd8, 0xe6),
		"emissive": true,
		"texture": "res://assets/textures/blocks/ice.png",
		"sound_type": "ice"
	},
	"glass": {
		"mass": 1.8,
		"friction": 0.5,
		"restitution": 0.6,
		"color": Color(0xad, 0xdb, 0xee, 0.6),
		"emissive": true,
		"texture": "res://assets/textures/blocks/glass.png", 
		"sound_type": "glass"
	},
	"rubber": {
		"mass": 1.0,
		"friction": 0.9,
		"restitution": 0.9,
		"color": Color(0x33, 0x33, 0x33),
		"emissive": false,
		"texture": "res://assets/textures/blocks/rubber.png",
		"sound_type": "rubber"
	},
}

@export var block_type: String = "wood"
@export var custom_color: Color = Color.WHITE
@export var custom_size: Vector3 = Vector3(1, 1, 1)
@export var is_preview: bool = false
@export var is_static: bool = false
@export var highlight_on_hover: bool = false

var material: StandardMaterial3D
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var stable_timer: Timer
var velocity_threshold: float = 0.1
var angular_velocity_threshold: float = 0.1
var is_placed: bool = false
var is_being_placed: bool = false
var is_stable: bool = false
var original_position: Vector3
var original_rotation: Vector3
var body_entered_count: int = 0
var block_id: String = ""

# Called when the node enters the scene tree for the first time
func _ready():
	if block_id.is_empty():
		block_id = "block_" + str(get_instance_id())
	
	# Setup physics properties based on block type
	setup_physics()
	
	# Setup visual properties
	setup_visuals()
	
	# Setup collision
	setup_collision()
	
	# Setup stability timer
	setup_stability_timer()
	
	if is_preview:
		setup_as_preview()
	elif is_static:
		setup_as_static()

# Setup block physics properties
func setup_physics():
	if BLOCK_TYPES.has(block_type):
		var properties = BLOCK_TYPES[block_type]
		mass = properties.mass * (custom_size.x * custom_size.y * custom_size.z)
		physics_material_override = PhysicsMaterial.new()
		physics_material_override.friction = properties.friction
		physics_material_override.bounce = properties.restitution
	
	# Configure RigidBody properties
	contact_monitor = true
	max_contacts_reported = 10
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# Setup visual appearance of the block
func setup_visuals():
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.mesh.size = custom_size
	
	# Create material
	material = StandardMaterial3D.new()
	
	if BLOCK_TYPES.has(block_type):
		var properties = BLOCK_TYPES[block_type]
		
		# Set material properties
		if custom_color == Color.WHITE:  # Only use default if no custom color
			material.albedo_color = properties.color
		else:
			material.albedo_color = custom_color
		
		# Load texture if available
		if ResourceLoader.exists(properties.texture):
			var texture = load(properties.texture)
			if texture:
				material.albedo_texture = texture
		
		# Set emissive if needed
		if properties.emissive:
			material.emission_enabled = true
			material.emission = properties.color
			material.emission_energy = 0.5
	else:
		material.albedo_color = custom_color
	
	# Apply material
	mesh_instance.material_override = material
	
	add_child(mesh_instance)

# Setup collision shape
func setup_collision():
	collision_shape = CollisionShape3D.new()
	collision_shape.shape = BoxShape3D.new()
	collision_shape.shape.size = custom_size
	add_child(collision_shape)

# Setup stability timer
func setup_stability_timer():
	stable_timer = Timer.new()
	stable_timer.wait_time = 0.5
	stable_timer.one_shot = true
	add_child(stable_timer)
	stable_timer.timeout.connect(_on_stable_timer_timeout)

# Setup as a preview block (non-physical)
func setup_as_preview():
	freeze = true
	collision_layer = 0
	collision_mask = 0
	
	# Make semi-transparent
	material.albedo_color.a = 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

# Setup as a static block (immovable)
func setup_as_static():
	freeze = true
	collision_layer = 1
	collision_mask = 1

# Check if block has settled (stopped moving)
func is_settled() -> bool:
	return linear_velocity.length() < velocity_threshold and angular_velocity.length() < angular_velocity_threshold

# Called every physics frame
func _physics_process(_delta):
	if not is_preview and not is_static and is_placed and not is_stable:
		if is_settled():
			if not stable_timer.is_started():
				stable_timer.start()
		else:
			if stable_timer.is_started():
				stable_timer.stop()

# Place block in the world (make it physical)
func place():
	if is_preview:
		is_preview = false
		is_placed = true
		is_being_placed = false
		
		# Save original position/rotation
		original_position = global_position
		original_rotation = global_rotation_degrees
		
		# Make it physical
		freeze = false
		collision_layer = 1
		collision_mask = 1
		
		# Make fully opaque
		material.albedo_color.a = 1.0
		material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		
		# Play sound
		if SoundManager.has_method("play"):
			SoundManager.play("place_block")
		
		emit_signal("block_placed")

# Reset block to its original state
func reset():
	global_position = original_position
	global_rotation_degrees = original_rotation
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	body_entered_count = 0
	is_stable = false
	
	if stable_timer.is_started():
		stable_timer.stop()

# Set block type and update properties
func set_block_type(type: String):
	if BLOCK_TYPES.has(type):
		block_type = type
		setup_physics()
		setup_visuals()

# Set block size and update properties
func set_size(size: Vector3):
	custom_size = size
	if mesh_instance and mesh_instance.mesh:
		mesh_instance.mesh.size = size
	if collision_shape and collision_shape.shape:
		collision_shape.shape.size = size
	
	# Update mass based on new size
	if BLOCK_TYPES.has(block_type):
		mass = BLOCK_TYPES[block_type].mass * (size.x * size.y * size.z)

# Highlight the block (for hover effects)
func highlight(enable: bool):
	if not highlight_on_hover:
		return
		
	if enable:
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_energy = 0.3
	else:
		if not BLOCK_TYPES.has(block_type) or not BLOCK_TYPES[block_type].emissive:
			material.emission_enabled = false

# Initialize the block with specific type and properties
func initialize(type: String, preview: bool = false):
	block_type = type
	is_preview = preview
	
	# Initialize the block based on the type
	if BLOCK_TYPES.has(type):
		# Set properties directly without waiting for _ready
		if not is_inside_tree():
			# We'll handle everything in _ready later
			return
			
		# Setup physics and visuals immediately if we're already in the tree
		setup_physics()
		setup_visuals()
		setup_collision()
		
		if is_preview:
			setup_as_preview()
	
	return self

# Signal handlers
func _on_body_entered(body):
	if body is RigidBody3D and body != self:
		body_entered_count += 1
		
		if is_placed and not is_being_placed:
			if SoundManager.has_method("play"):
				SoundManager.play("block_hit")
			emit_signal("block_hit", body)

func _on_body_exited(_body):
	body_entered_count = max(0, body_entered_count - 1)

func _on_stable_timer_timeout():
	if is_settled():
		is_stable = true
		emit_signal("block_settled", true)
	else:
		stable_timer.start() # Still moving, check again
