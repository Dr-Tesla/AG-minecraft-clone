# ==============================================================================
# Mob Manager - Handles Entity Spawning
# ==============================================================================
# Manages the population of mobs in the world.
# - Spawns mobs in loaded chunks around the player
# - Ensures mobs spawn on solid ground
# - Despawns distant mobs to save resources
# ==============================================================================

class_name MobManager
extends Node

# Spawning configuration
@export var max_mobs: int = 20
@export var spawn_radius: float = 30.0
@export var min_spawn_distance: float = 10.0
@export var spawn_interval: float = 5.0 # Seconds between spawn attempts

# State
var mob_list: Array[Mob] = []
var spawn_timer: float = 0.0

# References
var player: Player = null
var chunk_manager: ChunkManager = null

func setup(p_player: Player, p_chunk_manager: ChunkManager) -> void:
	player = p_player
	chunk_manager = p_chunk_manager

func _process(delta: float) -> void:
	if player == null or chunk_manager == null:
		return
	
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = spawn_interval
		_try_spawn_mob()
	
	_update_mobs()

func _try_spawn_mob() -> void:
	if mob_list.size() >= max_mobs:
		return
	
	# Try to find a random spawn point around the player
	var angle := randf() * TAU
	var dist := randf_range(min_spawn_distance, spawn_radius)
	var spawn_pos := player.global_position + Vector3(cos(angle) * dist, 10, sin(angle) * dist)
	
	# Raycast down to find the ground
	# We use the chunk manager to check for solid blocks
	var block_pos := Vector3i(spawn_pos)
	var found_ground := false
	
	# Look down for up to 30 blocks
	for i in range(30):
		var check_pos = block_pos + Vector3i(0, -i, 0)
		var block_type = chunk_manager.get_block_at_world(check_pos)
		
		if block_type != Block.Type.AIR:
			# Found ground! Check if space above is empty
			var space_above = chunk_manager.get_block_at_world(check_pos + Vector3i(0, 1, 0))
			if space_above == Block.Type.AIR:
				_spawn_mob(Vector3(check_pos) + Vector3(0.5, 1.0, 0.5))
				found_ground = true
				break
	
	if not found_ground:
		# print("Debug: Failed to find spawn ground")
		pass

func _spawn_mob(pos: Vector3) -> void:
	# Randomly pick between Mob, Sheep, and Cow
	var mob: Mob
	var rand := randf()
	
	if rand < 0.4:
		mob = Sheep.new()
	elif rand < 0.7:
		mob = Cow.new()
	else:
		mob = Mob.new()
		
	add_child(mob)
	
	# Set visuals based on type
	if mob is Cow:
		mob.create_visuals() # Spotted Cow
	elif mob is Sheep:
		mob.create_visuals() # White Sheep
	else:
		# Generic mobs get random colors
		var color := Color(randf(), randf(), randf())
		mob.create_visuals(color)
	
	mob.global_position = pos
	mob.setup(player, chunk_manager)
	
	mob_list.append(mob)
	# print("Debug: Spawned %s at %s" % [mob.get_class(), pos])

func _update_mobs() -> void:
	# Cull distant mobs
	var i := 0
	while i < mob_list.size():
		var mob := mob_list[i]
		if not is_instance_valid(mob):
			mob_list.remove_at(i)
			continue
			
		var dist := player.global_position.distance_to(mob.global_position)
		if dist > spawn_radius * 2:
			mob.queue_free()
			mob_list.remove_at(i)
			# print("Debug: Despawned mob")
		else:
			i += 1
