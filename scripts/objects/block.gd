extends RigidBody3D
# Block - Physics object that players remove from towers

signal block_placed
signal block_hit(other_block)
signal block_settled(is_stable)
signal block_selected
signal block_deselected
signal block_removed

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
	"jenga_wood": {
		"mass": 1.8,
		"friction": 0.65,
		"restitution": 0.2,
		"color": Color(0xbe, 0x8c, 0x63),
		"emissive": false,
		"material": "res://assets/materials/wood_shader_material.tres",
		"selected_material": "res://assets/materials/wood_selected_shader_material.tres",
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

@export var block_type: String = "jenga_wood" # Default to jenga wood for the new gameplay
@export var custom_color: Color = Color.WHITE
@export var custom_size: Vector3 = Vector3(1, 0.5, 3) # Standard Jenga block size ratio
@export var is_preview: bool = false
@export var is_static: bool = false
@export var highlight_on_hover: bool = true # Enable by default for Jenga-style gameplay
@export var is_selectable: bool = true # Whether this block can be selected for removal
@export var is_removable: bool = true # Whether this block can be removed

# Materials
var material: Material
var highlight_material: Material
var is_shader_material: bool = false
var default_material_path: String = "res://assets/materials/wood_shader_material.tres"
var selected_material_path: String = "res://assets/materials/wood_selected_shader_material.tres"
var dust_particles_scene: PackedScene = preload("res://scenes/effects/dust_particles.tscn")

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var stable_timer: Timer
var velocity_threshold: float = 0.1
var angular_velocity_threshold: float = 0.1
var is_placed: bool = false
var is_being_placed: bool = false
var is_stable: bool = false
var is_selected: bool = false
var is_hovered: bool = false
var original_position: Vector3
var original_rotation: Vector3
var body_entered_count: int = 0
var block_id: String = ""
var impact_threshold: float = 4.0

# Particle effects
var dust_particles: GPUParticles3D = null
var impact_particles: GPUParticles3D = null

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
	
	# Setup particle effects
	setup_particles()
	
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
	
	# Configure RigidBody
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
	
	# Check if we should use shader materials
	is_shader_material = false
	
	# Create or load material
	if BLOCK_TYPES.has(block_type) and BLOCK_TYPES[block_type].has("material"):
		# Use the predefined material for the block type
		material = load(BLOCK_TYPES[block_type].material)
		
		# Check if it's a shader material
		if material is ShaderMaterial:
			is_shader_material = true
	else:
		# Create a new material
		material = StandardMaterial3D.new()
		
		# Set color based on block type or custom color
		if BLOCK_TYPES.has(block_type):
			material.albedo_color = BLOCK_TYPES[block_type].color
		else:
			material.albedo_color = custom_color
		
		# Set texture if specified
		if BLOCK_TYPES.has(block_type) and BLOCK_TYPES[block_type].has("texture"):
			var texture = load(BLOCK_TYPES[block_type].texture)
			if texture:
				material.albedo_texture = texture
		
		# Set emissive property if specified
		if BLOCK_TYPES.has(block_type) and BLOCK_TYPES[block_type].has("emissive") and BLOCK_TYPES[block_type].emissive:
			if material is StandardMaterial3D:
				material.emission_enabled = true
				material.emission = Color(0.6, 0.6, 0.8, 0.8)
				material.emission_energy = 0.2
	
	mesh_instance.material_override = material
	add_child(mesh_instance)
	
	# Also load the highlight material for selection
	if BLOCK_TYPES.has(block_type) and BLOCK_TYPES[block_type].has("selected_material"):
		highlight_material = load(BLOCK_TYPES[block_type].selected_material)
	else:
		# Create highlight material
		if is_shader_material and material is ShaderMaterial:
			# Create a duplicate of the shader material with selection parameters
			highlight_material = material.duplicate()
			highlight_material.set_shader_parameter("selected", true)
			highlight_material.set_shader_parameter("selected_glow", 1.0)
		else:
			# Fallback to standard material
			highlight_material = StandardMaterial3D.new()
			highlight_material.emission_enabled = true
			highlight_material.emission = Color(1, 0.8, 0.3, 1)
			highlight_material.emission_energy = 0.3
			highlight_material.rim_enabled = true
			highlight_material.rim = 0.5
			highlight_material.rim_tint = 0.3

# Setup collision
func setup_collision():
	collision_shape = CollisionShape3D.new()
	collision_shape.shape = BoxShape3D.new()
	collision_shape.shape.size = custom_size
	add_child(collision_shape)

# Setup particle effects for block removal and impacts
func setup_particles():
	# Setup dust particles
	dust_particles = dust_particles_scene.instantiate()
	dust_particles.emitting = false
	add_child(dust_particles)
	
	# Setup impact particles (for when blocks hit each other)
	impact_particles = dust_particles_scene.instantiate()
	impact_particles.emitting = false
	impact_particles.amount = 10
	impact_particles.lifetime = 0.5
	add_child(impact_particles)
	
	# Configure particles based on block size
	var particle_scale = (custom_size.x + custom_size.y + custom_size.z) / 6.0
	dust_particles.scale = Vector3(particle_scale, particle_scale, particle_scale)
	impact_particles.scale = Vector3(particle_scale * 0.5, particle_scale * 0.5, particle_scale * 0.5)

# Setup stability timer
func setup_stability_timer():
	stable_timer = Timer.new()
	stable_timer.one_shot = true
	stable_timer.wait_time = 0.5
	stable_timer.timeout.connect(_on_stable_timer_timeout)
	add_child(stable_timer)

# Setup block as a preview (for placement)
func setup_as_preview():
	# Set preview properties
	is_preview = true
	freeze = true
	collision_layer = 0
	collision_mask = 0
	is_selectable = false
	
	# Make it translucent
	if material is StandardMaterial3D:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.5
	elif is_shader_material and material is ShaderMaterial:
		# For shader materials, we need to adjust based on shader parameters
		material.set_shader_parameter("selected_glow", 0.3)

# Setup as a static block (doesn't move initially)
func setup_as_static():
	freeze = true
	is_placed = true
	is_stable = true
	is_being_placed = false
	is_selectable = false

# Set block as placed
func set_placed():
	is_placed = true
	is_being_placed = false
	is_static = false
	freeze = false
	is_selectable = true

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

	# For preview blocks, update transparency based on valid placement
	if is_preview:
		var valid_placement = body_entered_count == 0
		
		if valid_placement:
			if material is StandardMaterial3D:
				material.albedo_color.a = 0.7
			elif is_shader_material and material is ShaderMaterial:
				material.set_shader_parameter("selected_glow", 0.5)
		else:
			if material is StandardMaterial3D:
				material.albedo_color.a = 0.3
			elif is_shader_material and material is ShaderMaterial:
				material.set_shader_parameter("selected_glow", 0.1)

# Make the block static (freeze physics)
func make_static():
	is_static = true
	freeze = true
	
	if stable_timer.is_started():
		stable_timer.stop()

# Make the block dynamic (unfreeze physics)
func make_dynamic():
	is_static = false
	freeze = false
	is_stable = false
	is_selectable = true

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

# Highlight the block on hover
func highlight(highlight_on: bool):
	is_hovered = highlight_on
	
	if is_selected:
		# No need to modify hover state when already selected
		return
	
	if highlight_on:
		# Handle shader materials differently
		if is_shader_material and material is ShaderMaterial:
			# Create a smooth tween for the glow parameter
			var tween = create_tween()
			tween.tween_method(func(value): 
				material.set_shader_parameter("selected_glow", value), 
				0.0, 0.5, 0.2).set_trans(Tween.TRANS_SINE)
		else:
			# Apply subtle emission effect for hover state (for standard materials)
			if material is StandardMaterial3D and not material.emission_enabled:
				material.emission_enabled = true
				material.emission = Color(0.9, 0.8, 0.4, 1)
				material.emission_energy = 0.15
		
		# Create subtle scale animation for feedback
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(1.02, 1.02, 1.02), 0.1).set_trans(Tween.TRANS_SINE)
	elif not is_selected:
		# Turn off highlight effects
		if is_shader_material and material is ShaderMaterial:
			var tween = create_tween()
			tween.tween_method(func(value): 
				material.set_shader_parameter("selected_glow", value), 
				0.5, 0.0, 0.2).set_trans(Tween.TRANS_SINE)
		elif material is StandardMaterial3D:
			# Remove highlight effect if not selected
			if not BLOCK_TYPES.has(block_type) or not BLOCK_TYPES[block_type].emissive:
				material.emission_enabled = false
		
		# Reset scale with smooth animation
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(1, 1, 1), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

# Select the block for removal
func select():
	if not is_selectable:
		return
		
	is_selected = true
	
	# Apply the highlight material for a stronger visual effect
	if highlight_material:
		mesh_instance.material_override = highlight_material
		
		# For shader materials, ensure the selected parameter is set
		if is_shader_material and highlight_material is ShaderMaterial:
			highlight_material.set_shader_parameter("selected", true)
			
			# Animate the glow parameter
			var tween = create_tween()
			tween.tween_method(func(value): 
				highlight_material.set_shader_parameter("selected_glow", value), 
				0.0, 1.0, 0.3).set_trans(Tween.TRANS_ELASTIC)
	else:
		# Fallback to emission effect if highlight material isn't available
		if material is StandardMaterial3D:
			material.emission_enabled = true
			material.emission = Color(0, 1, 0.5, 1)
			material.emission_energy = 0.6
	
	# Scale effect with elastic feel for tactile feedback
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3(1.05, 1.05, 1.05), 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Play sound effect
	if SoundManager.has_method("play"):
		SoundManager.play("select_block")
	
	emit_signal("block_selected")

# Deselect the block
func deselect():
	is_selected = false
	
	# Reset to default material
	mesh_instance.material_override = material
	
	# For shader materials, ensure the selected parameter is reset
	if is_shader_material and material is ShaderMaterial:
		material.set_shader_parameter("selected", false)
		
		# Animate the glow parameter
		if is_hovered:
			material.set_shader_parameter("selected_glow", 0.4) # Keep some glow for hover
		else:
			var tween = create_tween()
			tween.tween_method(func(value): 
				material.set_shader_parameter("selected_glow", value), 
				0.5, 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	
	# Reset visual effects with animation
	var tween = create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3(1, 1, 1), 0.15).set_trans(Tween.TRANS_SINE)
	
	if not is_hovered:
		if material is StandardMaterial3D:
			if not BLOCK_TYPES.has(block_type) or not BLOCK_TYPES[block_type].emissive:
				material.emission_enabled = false
	else:
		highlight(true)  # Restore hover effect
	
	emit_signal("block_deselected")

# Remove the block from the tower
func remove_block():
	if not is_removable or not is_selected:
		return
	
	# Play dust particle effect
	if dust_particles:
		dust_particles.emitting = true
		
		# Make particles independent so they continue after block is gone
		if dust_particles.get_parent() == self:
			remove_child(dust_particles)
			get_parent().add_child(dust_particles)
			
			# Set particles to match block's current position
			dust_particles.global_position = global_position
			
			# Create more extensive particle effect for block removal
			dust_particles.amount = 24  # Increase particle count
			dust_particles.lifetime = 1.5
			dust_particles.explosiveness = 0.8  # More explosive effect
			
			# Set up auto-destruction of particles after emission
			var timer = Timer.new()
			dust_particles.add_child(timer)
			timer.wait_time = 2.5
			timer.one_shot = true
			timer.timeout.connect(func(): dust_particles.queue_free())
			timer.start()
	
	# Visual effect - fade out with slight upward motion and rotation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", global_position + Vector3(0, 0.3, 0), 0.3)
	
	# Add a slight rotation for a more dynamic removal effect
	var random_rotation = Vector3(
		randf_range(-0.2, 0.2),
		randf_range(-0.2, 0.2),
		randf_range(-0.2, 0.2)
	)
	tween.tween_property(self, "global_rotation", global_rotation + random_rotation, 0.3)
	
	# Fade out
	if material is StandardMaterial3D:
		tween.tween_property(material, "albedo_color:a", 0.0, 0.3)
	elif is_shader_material and material is ShaderMaterial:
		# For shader materials, animate transparency differently
		tween.tween_method(func(value): 
			material.set_shader_parameter("selected_glow", value), 
			1.0, 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	
	# Play sound effect
	if SoundManager.has_method("play"):
		SoundManager.play("remove_block")
	
	# Make non-collidable
	collision_layer = 0
	collision_mask = 0
	
	# Signal that block has been removed
	emit_signal("block_removed")
	
	# Set up disposal
	await tween.finished
	queue_free()

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
		setup_particles()
		
		if is_preview:
			setup_as_preview()
	
	return self

# Signal handlers
func _on_body_entered(body):
	if body is RigidBody3D and body != self:
		body_entered_count += 1
		
		if is_placed and not is_being_placed:
			# Play impact particles
			if impact_particles and not impact_particles.emitting:
				impact_particles.emitting = true
				impact_particles.restart()
			
			# Determine impact force for sound volume
			var impact_velocity = (linear_velocity - body.linear_velocity).length()
			var impact_volume = clamp(impact_velocity / 10.0, 0.2, 1.0)
			
			if SoundManager.has_method("play"):
				# Pass impact volume to sound manager
				if impact_velocity > 1.0:  # Only play sound if impact is significant
					SoundManager.play("block_hit")
			
			emit_signal("block_hit", body)
			
			# Create impact effect
			if impact_velocity > impact_threshold and is_instance_valid(dust_particles_scene):
				_create_impact_effect(body.global_position, impact_velocity)

func _on_body_exited(_body):
	body_entered_count = max(0, body_entered_count - 1)

func _on_stable_timer_timeout():
	if is_settled():
		is_stable = true
		emit_signal("block_settled", true)
	else:
		stable_timer.start() # Still moving, check again

# Create impact dust effect
func _create_impact_effect(position, impact_force):
	var particles = dust_particles_scene.instantiate()
	get_tree().get_root().add_child(particles)
	
	# Position at impact point
	particles.global_position = position
	
	# Scale based on impact force
	var impact_scale = clamp(impact_force / 10.0, 0.3, 1.5)
	particles.scale = Vector3(impact_scale, impact_scale, impact_scale)
	
	# Set particle parameters based on impact
	if particles.has_method("configure_for_impact"):
		particles.configure_for_impact(impact_force)
	
	# Play the particles
	particles.play()
	
	# Auto-destroy after emission
	var timer = Timer.new()
	particles.add_child(timer)
	timer.wait_time = 2.0  # Time before auto-destruction
	timer.one_shot = true
	timer.timeout.connect(func(): particles.queue_free())
	timer.start()
