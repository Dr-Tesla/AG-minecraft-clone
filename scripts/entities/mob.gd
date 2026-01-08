# ==============================================================================
# Mob Base Class - Entity Physics and AI
# ==============================================================================
# Base class for all mobs in the game. Handles:
# - Simple movement and gravity
# - Collision with voxel terrain
# - Basic AI states (Idle, Wander)
# ==============================================================================

class_name Mob
extends CharacterBody3D

# Movement parameters
@export var move_speed: float = 2.0
@export var gravity: float = 20.0
@export var hop_force: float = 6.0  # Slightly stronger than player jump
@export var hop_interval: float = 0.3 # Time between hops while moving

# AI State
enum State { IDLE, WANDER, CHASE }
var current_state: State = State.IDLE

# AI and Hopping Timer
var state_timer: float = 0.0
var hop_timer: float = 0.0
var move_direction: Vector3 = Vector3.ZERO

# References
var player: Player = null
var chunk_manager: ChunkManager = null

func _ready() -> void:
	# Randomize initial state
	_change_state(State.IDLE)

func setup(p_player: Player, p_chunk_manager: ChunkManager) -> void:
	player = p_player
	chunk_manager = p_chunk_manager

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	_update_ai(delta)
	
	# Apply movement if in WANDER or CHASE state
	if current_state != State.IDLE:
		velocity.x = move_direction.x * move_speed
		velocity.z = move_direction.z * move_speed
		
		# Rhythmic Hopping while moving
		if is_on_floor():
			hop_timer -= delta
			if hop_timer <= 0:
				velocity.y = hop_force
				hop_timer = hop_interval
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * delta * 10)
		velocity.z = move_toward(velocity.z, 0, move_speed * delta * 10)
		hop_timer = 0 # Reset hop timer when stopped
	
	# Rotate towards movement direction
	if velocity.x != 0 or velocity.z != 0:
		var target_rotation = atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 5)
	
	move_and_slide()
	
	# Hurdle jumping (hopping over obstacles)
	if is_on_wall() and is_on_floor():
		velocity.y = hop_force * 1.20
		hop_timer = hop_interval # Reset timer so we don't double-hop immediately after hurdle

func _update_ai(delta: float) -> void:
	state_timer -= delta
	
	if state_timer <= 0:
		# Pick a new state
		if randf() < 0.7:
			_change_state(State.IDLE)
		else:
			_change_state(State.WANDER)

func _change_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.IDLE:
			state_timer = randf_range(1.0, 3.0)
			move_direction = Vector3.ZERO
		State.WANDER:
			state_timer = randf_range(2.0, 5.0)
			var angle = randf() * TAU
			move_direction = Vector3(cos(angle), 0, sin(angle))

# Create a simple visual placeholder (cube-based mob)
func create_visuals(color: Color = Color.WHITE) -> void:
	# Body
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.8, 0.8)
	mesh_instance.mesh = box
	
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	
	mesh_instance.position.y = 0.4 # Offset from ground
	add_child(mesh_instance)
	
	# Eye placeholder to see direction
	var eye := MeshInstance3D.new()
	var eye_box := BoxMesh.new()
	eye_box.size = Vector3(0.4, 0.1, 0.1)
	eye.mesh = eye_box
	
	var eye_material := StandardMaterial3D.new()
	eye_material.albedo_color = Color.BLACK
	eye.material_override = eye_material
	
	eye.position = Vector3(0, 0.6, 0.4)
	add_child(eye)
	
	# Collision Shape
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.8, 0.8, 0.8)
	collision.shape = shape
	collision.position.y = 0.4
	add_child(collision)
