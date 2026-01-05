# ==============================================================================
# Player Camera - First-Person View Controller
# ==============================================================================
# Handles mouse look for first-person camera control.
# Captures mouse input and rotates the camera/player accordingly.
# ==============================================================================

class_name PlayerCamera
extends Camera3D

# Mouse sensitivity
@export var mouse_sensitivity: float = 0.002

# Vertical look limits (in radians)
const MAX_PITCH := PI / 2.0 - 0.1  # ~85 degrees up
const MIN_PITCH := -PI / 2.0 + 0.1  # ~85 degrees down

# Reference to parent player node
var player: CharacterBody3D = null

func _ready() -> void:
	# Capture the mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Get parent player reference
	player = get_parent() as CharacterBody3D

func _input(event: InputEvent) -> void:
	# Handle mouse movement for looking around
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event.relative)
	
	# Toggle mouse capture with Escape
	if event.is_action_pressed("ui_cancel"):
		_toggle_mouse_capture()

# Process mouse movement for camera rotation
func _handle_mouse_look(mouse_delta: Vector2) -> void:
	# Horizontal rotation (yaw) - rotate the player body
	if player:
		player.rotate_y(-mouse_delta.x * mouse_sensitivity)
	
	# Vertical rotation (pitch) - rotate only the camera
	rotate_x(-mouse_delta.y * mouse_sensitivity)
	
	# Clamp vertical rotation to prevent flipping
	rotation.x = clamp(rotation.x, MIN_PITCH, MAX_PITCH)

# Toggle mouse capture mode
func _toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Get the direction the camera is looking
func get_look_direction() -> Vector3:
	return -global_transform.basis.z

# Get the camera's global position
func get_camera_position() -> Vector3:
	return global_position
