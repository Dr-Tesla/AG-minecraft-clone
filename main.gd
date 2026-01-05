# ==============================================================================
# Main Game Controller
# ==============================================================================
# Entry point for the Minecraft clone. Initializes all systems:
# - World Generator for procedural terrain
# - Chunk Manager for voxel rendering
# - Player spawning and camera setup
# ==============================================================================

extends Node3D

# References to child nodes (set in _ready or via scene)
@onready var chunk_manager: ChunkManager = $ChunkManager
@onready var world_generator: WorldGenerator = $WorldGenerator
@onready var player: Player = $Player

# World configuration
@export var world_seed: int = 12345

# Block material with texture atlas
var block_material: StandardMaterial3D = null

func _ready() -> void:
	_setup_material()
	_setup_world()
	_generate_spawn_chunks()
	_spawn_player()
	
	# Show FPS in title for debugging
	_setup_debug()

# Generate chunks around spawn before player is active
func _generate_spawn_chunks() -> void:
	var spawn_height := world_generator.get_spawn_height(0, 0)
	var spawn_pos := Vector3(8, spawn_height + 5, 8)
	
	# Generate initial chunks synchronously
	chunk_manager.generate_initial_chunks(spawn_pos)

# Create the material with texture atlas
func _setup_material() -> void:
	block_material = StandardMaterial3D.new()
	
	# Load or create texture atlas
	var atlas_path := "res://textures/atlas.png"
	if ResourceLoader.exists(atlas_path):
		block_material.albedo_texture = load(atlas_path)
	else:
		# Create procedural texture if atlas doesn't exist
		block_material.albedo_texture = _create_procedural_atlas()
	
	# Material settings for voxel rendering
	block_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	block_material.roughness = 1.0
	block_material.metallic = 0.0

# Create a procedural texture atlas (for testing without external textures)
func _create_procedural_atlas() -> ImageTexture:
	var atlas_size := 64  # 2x2 grid of 32x32 textures
	var tile_size := 32
	
	var image := Image.create(atlas_size, atlas_size, false, Image.FORMAT_RGBA8)
	
	# Grass Top (0, 0) - Green
	_fill_tile(image, 0, 0, tile_size, Color(0.2, 0.7, 0.2))
	
	# Grass Side (1, 0) - Green top, brown bottom
	_fill_tile_gradient(image, tile_size, 0, tile_size, 
		Color(0.2, 0.7, 0.2), Color(0.55, 0.35, 0.2))
	
	# Dirt (0, 1) - Brown
	_fill_tile(image, 0, tile_size, tile_size, Color(0.55, 0.35, 0.2))
	
	# Stone (1, 1) - Gray with variation
	_fill_tile_stone(image, tile_size, tile_size, tile_size)
	
	var texture := ImageTexture.create_from_image(image)
	return texture

# Fill a tile with a solid color
func _fill_tile(image: Image, x: int, y: int, size: int, color: Color) -> void:
	for px in size:
		for py in size:
			# Add slight noise for texture
			var noise := randf_range(-0.05, 0.05)
			var c := Color(
				clamp(color.r + noise, 0, 1),
				clamp(color.g + noise, 0, 1),
				clamp(color.b + noise, 0, 1),
				1.0
			)
			image.set_pixel(x + px, y + py, c)

# Fill a tile with vertical gradient (for grass side)
func _fill_tile_gradient(image: Image, x: int, y: int, size: int, 
	top_color: Color, bottom_color: Color) -> void:
	for px in size:
		for py in size:
			var t := float(py) / float(size)
			# Top part is grass, bottom is dirt
			var color: Color
			if py < size / 4:
				color = top_color
			else:
				color = bottom_color
			
			# Add noise
			var noise := randf_range(-0.05, 0.05)
			var c := Color(
				clamp(color.r + noise, 0, 1),
				clamp(color.g + noise, 0, 1),
				clamp(color.b + noise, 0, 1),
				1.0
			)
			image.set_pixel(x + px, y + py, c)

# Fill a tile with stone texture (gray with variation)
func _fill_tile_stone(image: Image, x: int, y: int, size: int) -> void:
	for px in size:
		for py in size:
			var base_gray := 0.5
			var noise := randf_range(-0.15, 0.15)
			var gray: float = clamp(base_gray + noise, 0.3, 0.7)
			image.set_pixel(x + px, y + py, Color(gray, gray, gray, 1.0))

# Initialize world systems
func _setup_world() -> void:
	# Configure world generator
	world_generator.set_world_seed(world_seed)
	
	# Connect chunk manager to world generator
	chunk_manager.world_generator = world_generator
	chunk_manager.chunk_material = block_material

# Spawn player at world center
func _spawn_player() -> void:
	# Get spawn height from world generator
	var spawn_height := world_generator.get_spawn_height(0, 0)
	player.global_position = Vector3(8, spawn_height + 5, 8)
	
	# Connect player to chunk manager
	chunk_manager.player = player
	
	# Connect block interaction to chunk manager
	var block_interaction := player.get_node("BlockInteraction") as BlockInteraction
	if block_interaction:
		block_interaction.set_chunk_manager(chunk_manager)
	
	# Unfreeze player now that chunks are loaded
	player.set_frozen(false)

# Debug display
func _setup_debug() -> void:
	# FPS counter in window title
	pass

func _process(_delta: float) -> void:
	# Update window title with FPS
	var fps := Engine.get_frames_per_second()
	var chunk_count := chunk_manager.chunks.size()
	DisplayServer.window_set_title("Minecraft Clone - FPS: %d | Chunks: %d" % [fps, chunk_count])
