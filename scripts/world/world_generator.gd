# ==============================================================================
# World Generator - Procedural Terrain Generation
# ==============================================================================
# Generates terrain using Perlin noise for natural-looking landscapes.
# 
# TERRAIN LAYERS:
# - Stone: Base layer, fills everything below terrain surface - 3
# - Dirt: Middle layer, 3 blocks below surface
# - Grass: Top layer, only on the surface
#
# HEIGHT CALCULATION:
# height = noise_2d(x, z) * amplitude + base_height
# ==============================================================================

class_name WorldGenerator
extends Node

# Terrain configuration
@export var world_seed: int = 12345
@export var base_height: int = 20      # Average terrain height
@export var height_amplitude: int = 15  # Max deviation from base
@export var min_height: int = 5        # Minimum terrain height
@export var max_height: int = 40       # Maximum terrain height

# Layer depths
const GRASS_DEPTH := 1   # 1 block of grass on top
const DIRT_DEPTH := 3    # 3 blocks of dirt below grass

var noise: NoiseGenerator

func _ready() -> void:
	noise = NoiseGenerator.new(world_seed)
	noise.set_frequency(0.02)
	noise.set_octaves(4)

# Set the world seed
func set_world_seed(seed_value: int) -> void:
	world_seed = seed_value
	if noise:
		noise.set_seed(seed_value)

# Generate terrain for a chunk
func generate_chunk(chunk: Chunk) -> void:
	var chunk_world_pos: Vector3i = chunk.chunk_position * Chunk.CHUNK_SIZE
	
	# Iterate through each column (x, z) in the chunk
	for local_x in Chunk.CHUNK_SIZE:
		for local_z in Chunk.CHUNK_SIZE:
			# Calculate world coordinates for noise sampling
			var world_x: int = chunk_world_pos.x + local_x
			var world_z: int = chunk_world_pos.z + local_z
			
			# Get terrain height at this column
			var terrain_height: int = _get_terrain_height(world_x, world_z)
			
			# Fill the column with blocks
			_fill_column(chunk, local_x, local_z, terrain_height, chunk_world_pos.y)

# Get the terrain height at a world (x, z) position
func _get_terrain_height(world_x: int, world_z: int) -> int:
	return noise.get_height(float(world_x), float(world_z), min_height, max_height)

# Fill a column of blocks in the chunk
func _fill_column(
	chunk: Chunk, 
	local_x: int, 
	local_z: int, 
	terrain_height: int,
	chunk_world_y: int
) -> void:
	for local_y in Chunk.CHUNK_SIZE:
		# Calculate world Y coordinate
		var world_y: int = chunk_world_y + local_y
		
		# Determine block type based on height relative to terrain surface
		var block_type := _get_block_type(world_y, terrain_height)
		
		chunk.set_block(local_x, local_y, local_z, block_type)

# Determine block type based on Y position and terrain height
func _get_block_type(world_y: int, terrain_height: int) -> Block.Type:
	# Above terrain = air
	if world_y > terrain_height:
		return Block.Type.AIR
	
	# At terrain surface = grass
	if world_y == terrain_height:
		return Block.Type.GRASS
	
	# Within dirt layer (1-3 blocks below surface)
	if world_y > terrain_height - DIRT_DEPTH:
		return Block.Type.DIRT
	
	# Below dirt layer = stone
	return Block.Type.STONE

# Get spawn height at a world (x, z) position (for player spawning)
func get_spawn_height(world_x: int, world_z: int) -> int:
	return _get_terrain_height(world_x, world_z) + 2
