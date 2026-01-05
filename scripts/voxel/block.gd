# ==============================================================================
# Block Type Definitions
# ==============================================================================
# Defines all block types and their properties including texture UV coordinates
# for the texture atlas. Each block can have different textures per face.
#
# Texture Atlas Layout (4x4 grid, 16x16 pixels each):
# +-------------+-------------+
# | Grass Top   | Grass Side  |
# +-------------+-------------+
# | Dirt        | Stone       |
# +-------------+-------------+
# ==============================================================================

class_name Block
extends RefCounted

# Block type enumeration
enum Type {
	AIR = 0,      # Empty space, not rendered
	DIRT = 1,     # Brown dirt block
	GRASS = 2,    # Green top, dirt sides
	STONE = 3     # Gray stone block
}

# Face directions for mesh generation
enum Face {
	TOP = 0,      # +Y
	BOTTOM = 1,   # -Y
	FRONT = 2,    # +Z
	BACK = 3,     # -Z
	LEFT = 4,     # -X
	RIGHT = 5     # +X
}

# Direction vectors for each face (used for neighbor checking)
const FACE_DIRECTIONS: Array[Vector3i] = [
	Vector3i(0, 1, 0),   # TOP
	Vector3i(0, -1, 0),  # BOTTOM
	Vector3i(0, 0, 1),   # FRONT
	Vector3i(0, 0, -1),  # BACK
	Vector3i(-1, 0, 0),  # LEFT
	Vector3i(1, 0, 0)    # RIGHT
]

# UV coordinates in the texture atlas (normalized 0-1)
# Atlas is 2x2 grid: each texture occupies 0.5 x 0.5 of the atlas
const ATLAS_SIZE := 2  # 2x2 grid
const UV_SIZE := 1.0 / ATLAS_SIZE  # 0.5

# Texture positions in atlas grid coordinates
const TEX_GRASS_TOP := Vector2(0, 0)
const TEX_GRASS_SIDE := Vector2(1, 0)
const TEX_DIRT := Vector2(0, 1)
const TEX_STONE := Vector2(1, 1)

# Get UV coordinates for a specific block type and face
static func get_uv(block_type: Type, face: Face) -> Rect2:
	var tex_pos: Vector2
	
	match block_type:
		Type.GRASS:
			match face:
				Face.TOP:
					tex_pos = TEX_GRASS_TOP
				Face.BOTTOM:
					tex_pos = TEX_DIRT
				_:  # Sides
					tex_pos = TEX_GRASS_SIDE
		Type.DIRT:
			tex_pos = TEX_DIRT
		Type.STONE:
			tex_pos = TEX_STONE
		_:
			tex_pos = TEX_DIRT  # Default
	
	# Convert grid position to normalized UV coordinates
	return Rect2(
		tex_pos.x * UV_SIZE,
		tex_pos.y * UV_SIZE,
		UV_SIZE,
		UV_SIZE
	)

# Check if a block type is solid (for face culling)
static func is_solid(block_type: Type) -> bool:
	return block_type != Type.AIR

# Check if a block type is transparent
static func is_transparent(block_type: Type) -> bool:
	return block_type == Type.AIR

# Vertex data for each face of a unit cube (1x1x1)
# Vertices are in counter-clockwise order for correct face normals
const FACE_VERTICES: Dictionary = {
	Face.TOP: [
		Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)
	],
	Face.BOTTOM: [
		Vector3(0, 0, 1), Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1)
	],
	Face.FRONT: [
		Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)
	],
	Face.BACK: [
		Vector3(1, 0, 0), Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0)
	],
	Face.LEFT: [
		Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0)
	],
	Face.RIGHT: [
		Vector3(1, 0, 1), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1)
	]
}

# UV coordinates for a quad (maps to atlas region)
const QUAD_UVS: Array[Vector2] = [
	Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)
]

# Triangle indices for a quad (two triangles) - reversed for correct outward normals
const QUAD_INDICES: Array[int] = [0, 2, 1, 0, 3, 2]

# Normal vectors for each face
const FACE_NORMALS: Dictionary = {
	Face.TOP: Vector3(0, 1, 0),
	Face.BOTTOM: Vector3(0, -1, 0),
	Face.FRONT: Vector3(0, 0, 1),
	Face.BACK: Vector3(0, 0, -1),
	Face.LEFT: Vector3(-1, 0, 0),
	Face.RIGHT: Vector3(1, 0, 0)
}
