# ==============================================================================
# Chunk Manager - Handles Chunk Loading, Unloading, and Frustum Culling
# ==============================================================================
# Manages all active chunks in the world. Responsibilities:
# 1. Load chunks around the player within render distance
# 2. Unload chunks that are too far from the player
# 3. Perform frustum culling to hide chunks outside camera view
# 4. Provide world-level block access across chunk boundaries
#
# CHUNK COORDINATES:
# Chunks are indexed by their chunk position, not world position.
# chunk_pos = floor(world_pos / CHUNK_SIZE)
# ==============================================================================

class_name ChunkManager
extends Node3D

signal chunk_loaded(chunk_pos: Vector3i)
signal chunk_unloaded(chunk_pos: Vector3i)
signal initial_chunks_ready

# Configuration
@export var render_distance: int = 4  # Chunks in each direction
@export var chunk_material: Material = null

# Active chunks dictionary: Vector3i -> Chunk
var chunks: Dictionary = {}

# Reference to world generator
var world_generator: Node = null

# Player reference for distance calculations
var player: Node3D = null

# Chunk loading queue for async loading
var load_queue: Array[Vector3i] = []
var chunks_per_frame: int = 2  # Max chunks to process per frame

# Dirty chunks queue - chunks that need mesh rebuild (for boundary updates)
var dirty_chunks: Dictionary = {}  # Vector3i -> true

# Initialization state
var is_initialized: bool = false

func _ready() -> void:
	# Material will be set by main.gd
	pass

# Generate initial chunks synchronously around a spawn position
# This ensures the player has ground to stand on before spawning
func generate_initial_chunks(spawn_pos: Vector3) -> void:
	var spawn_chunk := Chunk.world_to_chunk(Vector3i(spawn_pos))
	var initial_radius := 2  # Smaller radius for faster initial load
	
	# Generate chunks in a small radius around spawn
	for x in range(-initial_radius, initial_radius + 1):
		for y in range(-2, 2):  # Vertical range
			for z in range(-initial_radius, initial_radius + 1):
				var chunk_pos := spawn_chunk + Vector3i(x, y, z)
				if not chunks.has(chunk_pos):
					_load_chunk(chunk_pos)
	
	is_initialized = true
	emit_signal("initial_chunks_ready")

func _process(_delta: float) -> void:
	if player == null:
		return
	
	_update_loaded_chunks()
	_process_load_queue()
	_process_dirty_chunks()
	_update_frustum_culling()

# Process dirty chunks (rebuild meshes for boundary updates)
func _process_dirty_chunks() -> void:
	if dirty_chunks.is_empty():
		return
	
	# Process only 1 dirty chunk per frame to avoid stuttering
	var chunk_pos: Vector3i = dirty_chunks.keys()[0]
	dirty_chunks.erase(chunk_pos)
	
	if chunks.has(chunk_pos):
		var chunk: Chunk = chunks[chunk_pos]
		chunk.is_dirty = true
		chunk.rebuild_mesh(chunk_material)

# ==============================================================================
# CHUNK LOADING/UNLOADING
# ==============================================================================

# Update which chunks should be loaded based on player position
func _update_loaded_chunks() -> void:
	var player_chunk := Chunk.world_to_chunk(Vector3i(player.global_position))
	
	# Determine chunks that should be loaded
	var desired_chunks: Dictionary = {}
	
	for x in range(-render_distance, render_distance + 1):
		for y in range(-2, 3):  # Vertical range is smaller
			for z in range(-render_distance, render_distance + 1):
				var chunk_pos := player_chunk + Vector3i(x, y, z)
				desired_chunks[chunk_pos] = true
				
				# Queue for loading if not already loaded
				if not chunks.has(chunk_pos) and not load_queue.has(chunk_pos):
					load_queue.append(chunk_pos)
	
	# Unload chunks that are too far
	var chunks_to_unload: Array[Vector3i] = []
	for chunk_pos in chunks.keys():
		if not desired_chunks.has(chunk_pos):
			chunks_to_unload.append(chunk_pos)
	
	for chunk_pos in chunks_to_unload:
		_unload_chunk(chunk_pos)

# Process the chunk loading queue
func _process_load_queue() -> void:
	var loaded_count := 0
	
	while load_queue.size() > 0 and loaded_count < chunks_per_frame:
		var chunk_pos: Vector3i = load_queue.pop_front()
		
		# Skip if already loaded (might have been loaded since queued)
		if chunks.has(chunk_pos):
			continue
		
		_load_chunk(chunk_pos)
		loaded_count += 1

# Load a chunk at the given chunk position
func _load_chunk(chunk_pos: Vector3i) -> void:
	var chunk := Chunk.new()
	chunk.chunk_position = chunk_pos
	chunk.chunk_manager = self
	chunk.name = "Chunk_%d_%d_%d" % [chunk_pos.x, chunk_pos.y, chunk_pos.z]
	
	# Position in world space
	chunk.global_position = Vector3(chunk_pos * Chunk.CHUNK_SIZE)
	
	add_child(chunk)
	chunks[chunk_pos] = chunk
	
	# Generate terrain for this chunk
	if world_generator != null:
		world_generator.generate_chunk(chunk)
	
	# Build the mesh
	chunk.rebuild_mesh(chunk_material)
	
	# Mark adjacent chunks as dirty (they'll rebuild in _process_dirty_chunks)
	_mark_neighbors_dirty(chunk_pos)
	
	emit_signal("chunk_loaded", chunk_pos)

# Mark all 6 adjacent chunks as needing rebuild
func _mark_neighbors_dirty(chunk_pos: Vector3i) -> void:
	var offsets: Array[Vector3i] = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]
	for offset: Vector3i in offsets:
		var neighbor_pos: Vector3i = chunk_pos + offset
		if chunks.has(neighbor_pos):
			dirty_chunks[neighbor_pos] = true

# Unload a chunk
func _unload_chunk(chunk_pos: Vector3i) -> void:
	if not chunks.has(chunk_pos):
		return
	
	var chunk: Chunk = chunks[chunk_pos]
	chunks.erase(chunk_pos)
	chunk.queue_free()
	
	emit_signal("chunk_unloaded", chunk_pos)

# ==============================================================================
# FRUSTUM CULLING
# ==============================================================================

# Update visibility of chunks based on camera frustum
func _update_frustum_culling() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	
	for chunk in chunks.values():
		chunk.visible = _is_chunk_in_frustum(camera, chunk)

# Check if a chunk's AABB is within the camera's view frustum
func _is_chunk_in_frustum(camera: Camera3D, chunk: Chunk) -> bool:
	# TODO: Implement proper frustum culling for performance optimization
	# The old implementation was hiding visible chunks when:
	# - Player is inside or very close to a chunk
	# - Looking at certain angles where corners are outside frustum but faces are visible
	# Consider using frustum planes directly or checking if camera is inside chunk AABB
	# For now, all loaded chunks are always visible (Godot handles rendering efficiently)
	return true

# Get the 8 corners of an AABB
func _get_aabb_corners(aabb: AABB) -> Array[Vector3]:
	var pos := aabb.position
	var size := aabb.size
	
	return [
		pos,
		pos + Vector3(size.x, 0, 0),
		pos + Vector3(0, size.y, 0),
		pos + Vector3(0, 0, size.z),
		pos + Vector3(size.x, size.y, 0),
		pos + Vector3(size.x, 0, size.z),
		pos + Vector3(0, size.y, size.z),
		pos + size
	]

# ==============================================================================
# WORLD-LEVEL BLOCK ACCESS
# ==============================================================================

# Get a block at world coordinates (handles cross-chunk queries)
func get_block_at_world(world_pos: Vector3i) -> Block.Type:
	var chunk_pos := Chunk.world_to_chunk(world_pos)
	
	if not chunks.has(chunk_pos):
		return Block.Type.AIR
	
	var chunk: Chunk = chunks[chunk_pos]
	var local_pos := Chunk.world_to_local(world_pos, chunk_pos)
	
	return chunk.get_block(local_pos.x, local_pos.y, local_pos.z)

# Set a block at world coordinates
func set_block_at_world(world_pos: Vector3i, block_type: Block.Type) -> void:
	var chunk_pos := Chunk.world_to_chunk(world_pos)
	
	if not chunks.has(chunk_pos):
		return
	
	var chunk: Chunk = chunks[chunk_pos]
	var local_pos := Chunk.world_to_local(world_pos, chunk_pos)
	
	chunk.set_block(local_pos.x, local_pos.y, local_pos.z, block_type)
	chunk.rebuild_mesh(chunk_material)
	
	# Also update neighboring chunks if block is on edge
	_update_neighbor_chunks(local_pos, chunk_pos)

# Update neighboring chunks when a block on the edge changes
func _update_neighbor_chunks(local_pos: Vector3i, chunk_pos: Vector3i) -> void:
	# Check if block is on any chunk edge and update neighbors
	if local_pos.x == 0:
		_rebuild_chunk_at(chunk_pos + Vector3i(-1, 0, 0))
	if local_pos.x == Chunk.CHUNK_SIZE - 1:
		_rebuild_chunk_at(chunk_pos + Vector3i(1, 0, 0))
	if local_pos.y == 0:
		_rebuild_chunk_at(chunk_pos + Vector3i(0, -1, 0))
	if local_pos.y == Chunk.CHUNK_SIZE - 1:
		_rebuild_chunk_at(chunk_pos + Vector3i(0, 1, 0))
	if local_pos.z == 0:
		_rebuild_chunk_at(chunk_pos + Vector3i(0, 0, -1))
	if local_pos.z == Chunk.CHUNK_SIZE - 1:
		_rebuild_chunk_at(chunk_pos + Vector3i(0, 0, 1))

# Rebuild a chunk at the given position if it exists
func _rebuild_chunk_at(chunk_pos: Vector3i) -> void:
	if chunks.has(chunk_pos):
		var chunk: Chunk = chunks[chunk_pos]
		chunk.is_dirty = true
		chunk.rebuild_mesh(chunk_material)

# ==============================================================================
# RAYCAST HELPERS
# ==============================================================================

# Get the block position that a ray hits, plus the face it hit
func raycast_block(from: Vector3, direction: Vector3, max_distance: float) -> Dictionary:
	# Use DDA (Digital Differential Analyzer) algorithm for precise voxel raycast
	var step := 0.1
	var current := from
	var prev_block := Vector3i(floor(from.x), floor(from.y), floor(from.z))
	
	var distance := 0.0
	while distance < max_distance:
		current += direction * step
		distance += step
		
		var block_pos := Vector3i(floor(current.x), floor(current.y), floor(current.z))
		var block_type := get_block_at_world(block_pos)
		
		if Block.is_solid(block_type):
			return {
				"hit": true,
				"position": block_pos,
				"previous": prev_block,  # For block placement
				"block_type": block_type
			}
		
		prev_block = block_pos
	
	return {"hit": false}
