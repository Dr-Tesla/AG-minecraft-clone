# ==============================================================================
# Chunk - 16x16x16 Voxel Container with Optimized Mesh Generation
# ==============================================================================
# A chunk is a fixed-size container of blocks. We use chunks to:
# 1. Limit memory usage by only loading nearby areas
# 2. Optimize mesh generation (rebuild only affected chunks)
# 3. Enable efficient face culling (check neighbors within chunk)
#
# COORDINATE SYSTEMS:
# - World Position: Global coordinates (e.g., x=35, y=12, z=-47)
# - Chunk Position: Which chunk (floor(world_pos / CHUNK_SIZE))
#   Example: (35, 12, -47) -> chunk (2, 0, -3) with CHUNK_SIZE=16
# - Local Position: Position within chunk (world_pos % CHUNK_SIZE)
#   Example: (35, 12, -47) -> local (3, 12, 1)
#
# FACE CULLING:
# Only render faces that are adjacent to AIR blocks (or transparent blocks).
# This dramatically reduces triangle count since most blocks are underground.
# ==============================================================================

class_name Chunk
extends Node3D

const CHUNK_SIZE := 16  # Width, height, and depth in blocks

# 3D array of block types [x][y][z]
var blocks: Array = []

# Chunk position in chunk coordinates (not world coordinates)
var chunk_position: Vector3i = Vector3i.ZERO

# Reference to chunk manager for neighbor lookups
var chunk_manager: Node = null

# Mesh components
var mesh_instance: MeshInstance3D = null
var static_body: StaticBody3D = null

# Flag to track if mesh needs rebuilding
var is_dirty: bool = true

func _init() -> void:
	# Initialize immediately in constructor (before _ready)
	_initialize_blocks()
	_setup_mesh_instance()
	_setup_collision()

func _ready() -> void:
	# Everything is already initialized in _init()
	pass

# Initialize the 3D block array with AIR
func _initialize_blocks() -> void:
	blocks.resize(CHUNK_SIZE)
	for x in CHUNK_SIZE:
		blocks[x] = []
		blocks[x].resize(CHUNK_SIZE)
		for y in CHUNK_SIZE:
			blocks[x][y] = []
			blocks[x][y].resize(CHUNK_SIZE)
			for z in CHUNK_SIZE:
				blocks[x][y][z] = Block.Type.AIR

# Setup the MeshInstance3D for rendering
func _setup_mesh_instance() -> void:
	mesh_instance = MeshInstance3D.new()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mesh_instance)

# Setup collision detection
func _setup_collision() -> void:
	static_body = StaticBody3D.new()
	# Explicitly set collision layer (layer 1 = terrain)
	static_body.collision_layer = 1
	static_body.collision_mask = 1
	add_child(static_body)

# ==============================================================================
# BLOCK ACCESS METHODS
# ==============================================================================

# Get block at local coordinates (0-15 range)
func get_block(x: int, y: int, z: int) -> Block.Type:
	if _is_valid_local_position(x, y, z):
		return blocks[x][y][z]
	# For positions outside this chunk, query the chunk manager
	return _get_neighbor_block(x, y, z)

# Set block at local coordinates
func set_block(x: int, y: int, z: int, block_type: Block.Type) -> void:
	if _is_valid_local_position(x, y, z):
		blocks[x][y][z] = block_type
		is_dirty = true

# Check if local coordinates are within chunk bounds
func _is_valid_local_position(x: int, y: int, z: int) -> bool:
	return x >= 0 and x < CHUNK_SIZE and \
		   y >= 0 and y < CHUNK_SIZE and \
		   z >= 0 and z < CHUNK_SIZE

# Get block from neighboring chunk when local position is out of bounds
func _get_neighbor_block(x: int, y: int, z: int) -> Block.Type:
	if chunk_manager == null:
		return Block.Type.AIR
	
	# Convert to world position, then find the correct chunk
	var world_pos := local_to_world(Vector3i(x, y, z))
	return chunk_manager.get_block_at_world(world_pos)

# ==============================================================================
# COORDINATE CONVERSION
# ==============================================================================

# Convert local chunk position to world position
func local_to_world(local_pos: Vector3i) -> Vector3i:
	return chunk_position * CHUNK_SIZE + local_pos

# Convert world position to local chunk position
static func world_to_local(world_pos: Vector3i, chunk_pos: Vector3i) -> Vector3i:
	return world_pos - chunk_pos * CHUNK_SIZE

# Get chunk position from world position
static func world_to_chunk(world_pos: Vector3i) -> Vector3i:
	# Use floor division for correct negative coordinate handling
	return Vector3i(
		floori(float(world_pos.x) / CHUNK_SIZE),
		floori(float(world_pos.y) / CHUNK_SIZE),
		floori(float(world_pos.z) / CHUNK_SIZE)
	)

# ==============================================================================
# MESH GENERATION WITH FACE CULLING
# ==============================================================================

# Rebuild the chunk mesh (call when blocks change)
func rebuild_mesh(material: Material) -> void:
	if not is_dirty:
		return
	
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var vertex_count := 0
	
	# Clear existing collision shapes
	for child in static_body.get_children():
		child.queue_free()
	
	# Shared box shape for all block collisions (1x1x1 cube)
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1, 1, 1)
	
	# Iterate through all blocks in the chunk
	for x in CHUNK_SIZE:
		for y in CHUNK_SIZE:
			for z in CHUNK_SIZE:
				var block_type: Block.Type = blocks[x][y][z]
				
				# Skip air blocks - nothing to render
				if not Block.is_solid(block_type):
					continue
				
				# Add collision box for this block
				var col_shape := CollisionShape3D.new()
				col_shape.shape = box_shape
				col_shape.position = Vector3(x + 0.5, y + 0.5, z + 0.5)
				static_body.add_child(col_shape)
				
				# Check each face and only add if neighbor is air/transparent
				vertex_count = _add_visible_faces(
					surface_tool, 
					Vector3i(x, y, z), 
					block_type, 
					vertex_count
				)
	
	# Generate normals and create the mesh
	surface_tool.generate_normals()
	
	var mesh := surface_tool.commit()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	
	is_dirty = false

# Add only the visible faces of a block (face culling)
func _add_visible_faces(
	st: SurfaceTool, 
	local_pos: Vector3i, 
	block_type: Block.Type, 
	vertex_offset: int
) -> int:
	var offset := vertex_offset
	
	# Check each of the 6 faces
	for face_idx in Block.Face.values():
		var face: Block.Face = face_idx as Block.Face
		var dir: Vector3i = Block.FACE_DIRECTIONS[face]
		
		# Get the neighboring block in this direction
		var neighbor_pos := local_pos + dir
		var neighbor_type := get_block(neighbor_pos.x, neighbor_pos.y, neighbor_pos.z)
		
		# Only render this face if the neighbor is transparent (e.g., AIR)
		if Block.is_transparent(neighbor_type):
			offset = _add_face(st, local_pos, block_type, face, offset)
	
	return offset

# Add a single face quad to the mesh
func _add_face(
	st: SurfaceTool, 
	local_pos: Vector3i, 
	block_type: Block.Type, 
	face: Block.Face,
	vertex_offset: int
) -> int:
	var vertices: Array = Block.FACE_VERTICES[face]
	var uv_rect := Block.get_uv(block_type, face)
	var normal: Vector3 = Block.FACE_NORMALS[face]
	
	# Add the 4 vertices of the face
	for i in 4:
		var vertex: Vector3 = vertices[i] + Vector3(local_pos)
		var uv: Vector2 = Block.QUAD_UVS[i]
		
		# Transform UV to atlas coordinates
		uv = Vector2(
			uv_rect.position.x + uv.x * uv_rect.size.x,
			uv_rect.position.y + uv.y * uv_rect.size.y
		)
		
		st.set_normal(normal)
		st.set_uv(uv)
		st.add_vertex(vertex)
	
	# Add indices for the two triangles (quad)
	for idx in Block.QUAD_INDICES:
		st.add_index(vertex_offset + idx)
	
	return vertex_offset + 4

# ==============================================================================
# UTILITY
# ==============================================================================

# Get the AABB (Axis-Aligned Bounding Box) of this chunk in world space
func get_world_aabb() -> AABB:
	var world_origin := Vector3(chunk_position * CHUNK_SIZE)
	return AABB(world_origin, Vector3(CHUNK_SIZE, CHUNK_SIZE, CHUNK_SIZE))
