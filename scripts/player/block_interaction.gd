# ==============================================================================
# Block Interaction - Add and Remove Blocks
# ==============================================================================
# Handles player interaction with the voxel world:
# - Left-click: Remove (break) the targeted block
# - Right-click: Place a block on the face of the targeted block
#
# Uses raycasting from the camera to detect which block is being looked at.
# ==============================================================================

class_name BlockInteraction
extends Node

# Interaction range in blocks
@export var reach_distance: float = 5.0

# Block type to place (could be extended to inventory system)
var current_block_type: Block.Type = Block.Type.DIRT

# References
var player: Player = null
var chunk_manager: ChunkManager = null

# Visual feedback
var highlight_mesh: MeshInstance3D = null

func _ready() -> void:
	player = get_parent() as Player
	_create_highlight_mesh()

func _process(_delta: float) -> void:
	if chunk_manager == null:
		return
	
	_update_highlight()
	_handle_input()

# Create a wireframe cube to highlight the targeted block
func _create_highlight_mesh() -> void:
	highlight_mesh = MeshInstance3D.new()
	
	# Create wireframe box
	var box := BoxMesh.new()
	box.size = Vector3(1.01, 1.01, 1.01)  # Slightly larger than block
	highlight_mesh.mesh = box
	
	# Create wireframe material
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1, 1, 1, 0.3)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_mesh.material_override = material
	
	highlight_mesh.visible = false
	add_child(highlight_mesh)

# Update the highlight cube position
func _update_highlight() -> void:
	var camera := player.get_camera()
	if camera == null:
		highlight_mesh.visible = false
		return
	
	var ray_origin := camera.get_camera_position()
	var ray_dir := camera.get_look_direction()
	
	var result := chunk_manager.raycast_block(ray_origin, ray_dir, reach_distance)
	
	if result.hit:
		highlight_mesh.visible = true
		highlight_mesh.global_position = Vector3(result.position) + Vector3(0.5, 0.5, 0.5)
	else:
		highlight_mesh.visible = false

# Handle mouse click input for block interaction
func _handle_input() -> void:
	var camera := player.get_camera()
	if camera == null:
		return
	
	# Only process when mouse is captured
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	var ray_origin := camera.get_camera_position()
	var ray_dir := camera.get_look_direction()
	var result := chunk_manager.raycast_block(ray_origin, ray_dir, reach_distance)
	
	if not result.hit:
		return
	
	# Left-click to break block
	if Input.is_action_just_pressed("break_block"):
		_break_block(result.position)
	
	# Right-click to place block
	if Input.is_action_just_pressed("place_block"):
		_place_block(result.previous)

# Remove a block at the given position
func _break_block(block_pos: Vector3i) -> void:
	chunk_manager.set_block_at_world(block_pos, Block.Type.AIR)

# Place a block at the given position
func _place_block(block_pos: Vector3i) -> void:
	# Don't place block if it would be inside the player
	var player_pos := Vector3i(player.global_position)
	var player_feet := player_pos
	var player_head := player_pos + Vector3i(0, 1, 0)
	
	if block_pos == player_feet or block_pos == player_head:
		return
	
	chunk_manager.set_block_at_world(block_pos, current_block_type)

# Set the chunk manager reference
func set_chunk_manager(manager: ChunkManager) -> void:
	chunk_manager = manager

# Set the current block type to place
func set_current_block(block_type: Block.Type) -> void:
	current_block_type = block_type
