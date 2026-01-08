# ==============================================================================
# Main Game Controller
# ==============================================================================
# Entry point for the Minecraft clone. Initializes all systems:
# - World Generator for procedural terrain
# - Chunk Manager for voxel rendering
# - Player spawning and camera setup
# - Day/Night cycle with lighting
# ==============================================================================

extends Node3D

# References to child nodes (set in _ready or via scene)
@onready var chunk_manager: ChunkManager = $ChunkManager
@onready var world_generator: WorldGenerator = $WorldGenerator
@onready var player: Player = $Player

# World configuration
@export var world_seed: int = 12345
@export_range(6, 24) var starting_hour: int = 6  # 6 = 6am, 12 = noon, 18 = 6pm

# Block material with texture atlas
var block_material: StandardMaterial3D = null

# Day/night cycle components
var day_night_cycle: DayNightCycle = null
var sun_light: DirectionalLight3D = null
var world_environment: WorldEnvironment = null
var time_widget: TimeWidget = null
var hotbar: Hotbar = null
var mob_manager: MobManager = null

func _ready() -> void:
	_setup_lighting()
	_setup_material()
	_setup_world()
	_setup_day_night_cycle()
	_generate_spawn_chunks()
	_spawn_player()
	_setup_ui()
	_setup_mobs()
	
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
	
	# Use procedural atlas (external atlas.png not required)
	# To use an external texture, create textures/atlas.png and uncomment:
	# var texture = load("res://textures/atlas.png")
	var texture = _create_procedural_atlas()
	
	block_material.albedo_texture = texture
	
	# Material settings for voxel rendering
	block_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	block_material.roughness = 1.0
	block_material.metallic = 0.0
	block_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides of faces

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

# Setup DirectionalLight3D for sun and WorldEnvironment
func _setup_lighting() -> void:
	# Create sun light
	sun_light = DirectionalLight3D.new()
	sun_light.name = "SunLight"
	sun_light.light_energy = 1.0
	sun_light.light_color = Color(1.0, 1.0, 0.9)
	sun_light.shadow_enabled = true
	sun_light.rotation_degrees = Vector3(-45, 45, 0)
	add_child(sun_light)
	
	# Find existing WorldEnvironment from scene (don't create new one)
	world_environment = $WorldEnvironment as WorldEnvironment
	
	# If found, ensure it's using BG_COLOR mode for dynamic color changes
	if world_environment and world_environment.environment:
		var env := world_environment.environment
		# Switch from Sky to Color mode for easier color updates
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.4, 0.7, 1.0)  # Start with sky blue
		print("Using existing WorldEnvironment, switched to BG_COLOR mode")

# Setup day/night cycle
func _setup_day_night_cycle() -> void:
	day_night_cycle = DayNightCycle.new()
	day_night_cycle.name = "DayNightCycle"
	day_night_cycle.starting_hour = starting_hour  # Use export variable
	add_child(day_night_cycle)
	
	# Connect to lighting - pass WorldEnvironment directly
	if world_environment:
		day_night_cycle.setup(sun_light, world_environment)

# Setup UI elements
func _setup_ui() -> void:
	# Create CanvasLayer for UI
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	add_child(canvas)
	
	# Create time widget
	time_widget = TimeWidget.new()
	time_widget.name = "TimeWidget"
	canvas.add_child(time_widget)
	
	# Connect to day/night cycle
	if day_night_cycle:
		time_widget.setup(day_night_cycle)
	
	# Create hotbar
	hotbar = Hotbar.new()
	hotbar.name = "Hotbar"
	canvas.add_child(hotbar)
	
	# Connect to player selection
	if player:
		player.block_selected.connect(func(index, _type): hotbar.update_selection(index))

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

# Setup Mob Manager
func _setup_mobs() -> void:
	mob_manager = MobManager.new()
	mob_manager.name = "MobManager"
	add_child(mob_manager)
	
	# Pass references
	mob_manager.setup(player, chunk_manager)

# Debug display
func _setup_debug() -> void:
	# FPS counter in window title
	pass

func _process(_delta: float) -> void:
	# Update window title with FPS
	var fps := Engine.get_frames_per_second()
	var chunk_count := chunk_manager.chunks.size()
	DisplayServer.window_set_title("Minecraft Clone - FPS: %d | Chunks: %d" % [fps, chunk_count])
