# ==============================================================================
# Player Controller - First-Person Movement and Physics
# ==============================================================================
# Handles player movement, jumping, and physics using Godot's CharacterBody3D.
# Uses input actions defined in project.godot for WASD movement.
# ==============================================================================

class_name Player
extends CharacterBody3D

# Movement parameters
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 20.0

# References
var camera: PlayerCamera = null
var block_interaction: Node = null

# Current movement state
var current_speed: float = 5.0

# Whether physics is frozen (waiting for world to load)
var is_frozen: bool = true

func _ready() -> void:
	# Camera is a child node
	camera = $PlayerCamera as PlayerCamera
	
	# Block interaction component
	block_interaction = $BlockInteraction
	
	# Configure floor detection for voxel terrain
	floor_snap_length = 0.5  # Snap to floor within 0.5 units
	floor_max_angle = deg_to_rad(60)  # Allow 60 degree slopes as floor

# Freeze or unfreeze player physics
func set_frozen(frozen: bool) -> void:
	is_frozen = frozen

func _physics_process(delta: float) -> void:
	# Don't process physics while frozen
	if is_frozen:
		return
	
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	move_and_slide()

# Apply gravity when not on floor
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

# Handle jump input
func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

# Handle WASD movement
func _handle_movement() -> void:
	# Get input direction
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_forward", "move_backward")
	
	# Convert to 3D direction relative to camera's horizontal facing
	var direction := Vector3.ZERO
	if camera and input_dir != Vector2.ZERO:
		# Get camera's forward direction (ignoring pitch)
		var cam_basis := camera.global_transform.basis
		var forward := -Vector3(cam_basis.z.x, 0, cam_basis.z.z).normalized()
		var right := Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
		
		direction = right * input_dir.x + forward * (-input_dir.y)
		direction = direction.normalized()
	
	# Apply movement
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Decelerate when no input
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

# Get camera for external access
func get_camera() -> PlayerCamera:
	return camera
