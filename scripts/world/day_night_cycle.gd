# ==============================================================================
# Day/Night Cycle Manager
# ==============================================================================
# Manages the day/night cycle including:
# - Sun position (DirectionalLight3D rotation)
# - Sky and ambient lighting colors
# - Time tracking and signals
#
# Timing:
# - Day: 12 minutes (720 seconds) - sun visible
# - Night: 6 minutes (360 seconds) - sun below horizon
# - Total cycle: 18 minutes (1080 seconds)
# ==============================================================================

class_name DayNightCycle
extends Node

# Timing configuration (in seconds)
const DAY_DURATION := 720.0  # 12 minutes
const NIGHT_DURATION := 360.0  # 6 minutes
const TOTAL_CYCLE := DAY_DURATION + NIGHT_DURATION  # 18 minutes

# Time phases (normalized 0-1 within total cycle)
const DAWN_START := 0.0  # 0% - sun rises
const NOON := 0.33  # ~33% - sun at peak (halfway through day)
const DUSK_START := 0.60  # ~60% - sun begins setting
const NIGHT_START := 0.67  # ~67% - day ends, night begins
const NIGHT_END := 1.0  # 100% - cycle restarts

# Signals
signal time_changed(normalized_time: float, is_day: bool)
signal day_started
signal night_started

# References
var sun_light: DirectionalLight3D = null
var world_env: WorldEnvironment = null  # Store WorldEnvironment to access its .environment

# Configuration - adjust starting time from Editor
@export_range(6, 24) var starting_hour: int = 6  # 6 = 6am (sunrise), 12 = noon, 18 = 6pm (sunset)

# State
var current_time: float = 0.0  # 0.0 to TOTAL_CYCLE seconds
var time_scale: float = 1.0  # Multiplier for time speed
var is_paused: bool = false

# Day counter
var day_count: int = 1

# Colors
const SKY_DAY := Color(0.4, 0.7, 1.0)  # Light blue
const SKY_SUNSET := Color(1.0, 0.5, 0.2)  # Orange
const SKY_NIGHT := Color(0.02, 0.02, 0.08)  # Very dark blue/black

const AMBIENT_DAY := Color(1.0, 1.0, 1.0)
const AMBIENT_SUNSET := Color(1.0, 0.7, 0.5)
const AMBIENT_NIGHT := Color(0.1, 0.1, 0.2)  # Much darker ambient at night

const SUN_DAY := Color(1.0, 1.0, 0.9)  # Slightly warm white
const SUN_SUNSET := Color(1.0, 0.6, 0.3)  # Orange
const SUN_NIGHT := Color(0.3, 0.3, 0.5)  # Dim blue (moonlight)

func _ready() -> void:
	# Convert starting_hour to current_time
	# 6am = 0, 12pm = 0.33, 6pm = 0.67 of total cycle
	if starting_hour <= 6:
		current_time = 0.0
	elif starting_hour < 18:
		# Day hours (6-18) map to 0 - NIGHT_START (0.67) of cycle
		var day_progress := float(starting_hour - 6) / 12.0  # 0 to 1 for day
		current_time = day_progress * NIGHT_START * TOTAL_CYCLE
	else:
		# Night hours (18-24/6) map to NIGHT_START (0.67) - 1.0 of cycle
		var night_progress := float(starting_hour - 18) / 12.0  # 0 to 0.5 for evening
		current_time = (NIGHT_START + night_progress * (1.0 - NIGHT_START)) * TOTAL_CYCLE

func setup(light: DirectionalLight3D, world_environment: WorldEnvironment) -> void:
	sun_light = light
	world_env = world_environment
	print("DayNightCycle setup - sun_light: ", sun_light, " world_env: ", world_env)
	_update_lighting()

func _process(delta: float) -> void:
	if is_paused or sun_light == null:
		return
	
	var old_is_day := is_day()
	
	# Advance time
	current_time += delta * time_scale
	
	# Handle cycle wrap
	if current_time >= TOTAL_CYCLE:
		current_time -= TOTAL_CYCLE
		day_count += 1
	
	# Check for day/night transitions
	var new_is_day := is_day()
	if old_is_day != new_is_day:
		if new_is_day:
			emit_signal("day_started")
		else:
			emit_signal("night_started")
	
	# Update lighting
	_update_lighting()
	
	# Emit time update
	emit_signal("time_changed", get_normalized_time(), new_is_day)

func _update_lighting() -> void:
	if sun_light == null:
		return
	
	var t := get_normalized_time()
	
	# Calculate sun angle (0 = sunrise at horizon, 0.5 = noon overhead, 1.0 = set)
	var sun_progress: float
	var light_energy: float
	var sky_color: Color
	var ambient_color: Color
	var sun_color: Color
	
	if t < NIGHT_START:
		# Daytime - sun visible
		sun_progress = t / NIGHT_START  # 0 to 1 during day
		
		if t < NOON:
			# Morning - sun rising
			var morning_t := t / NOON
			light_energy = lerp(0.3, 1.0, morning_t)
			sky_color = SKY_DAY
			ambient_color = AMBIENT_DAY
			sun_color = SUN_DAY.lerp(SUN_DAY, morning_t)
		elif t < DUSK_START:
			# Midday - full sun
			light_energy = 1.0
			sky_color = SKY_DAY
			ambient_color = AMBIENT_DAY
			sun_color = SUN_DAY
		else:
			# Evening - sun setting
			var evening_t := (t - DUSK_START) / (NIGHT_START - DUSK_START)
			light_energy = lerp(1.0, 0.3, evening_t)
			sky_color = SKY_DAY.lerp(SKY_SUNSET, evening_t)
			ambient_color = AMBIENT_DAY.lerp(AMBIENT_SUNSET, evening_t)
			sun_color = SUN_DAY.lerp(SUN_SUNSET, evening_t)
	else:
		# Nighttime - sun below horizon (moon)
		var night_t := (t - NIGHT_START) / (1.0 - NIGHT_START)
		sun_progress = 1.0 + night_t  # Continue rotation
		light_energy = 0.08  # Very dim moonlight (~30% of min day)
		sky_color = SKY_NIGHT
		ambient_color = AMBIENT_NIGHT
		sun_color = SUN_NIGHT
	
	# Rotate sun to match displayed time:
	# In Godot DirectionalLight3D: rotation.x controls elevation
	# - rot.x = 0: sun at horizon (sunrise/sunset)  
	# - rot.x = -90: sun directly overhead (noon)
	# - rot.x = -180: sun at opposite horizon (sunset)
	# - rot.x = -270: sun directly below (midnight)
	var sun_angle: float
	if t < NIGHT_START:
		# Day: 0 (sunrise) -> -90 (noon) -> -180 (sunset)
		sun_angle = lerp(0.0, -180.0, sun_progress)
	else:
		# Night: -180 (sunset) -> -360 (sunrise)
		var night_progress = (t - NIGHT_START) / (1.0 - NIGHT_START)
		sun_angle = lerp(-180.0, -360.0, night_progress)
	
	sun_light.rotation_degrees.x = sun_angle
	
	# Apply lighting
	sun_light.light_energy = light_energy
	sun_light.light_color = sun_color
	
	# Update environment if available
	if world_env and world_env.environment:
		var env := world_env.environment
		# Update sky background color
		env.background_color = sky_color
		
		# Update ambient lighting
		env.ambient_light_color = ambient_color
		
		# Night ambient should be much dimmer
		if light_energy < 0.3:
			env.ambient_light_energy = 0.15  # Very dark night
		else:
			env.ambient_light_energy = lerp(0.4, 0.8, light_energy)

# Get normalized time (0.0 to 1.0 for full cycle)
func get_normalized_time() -> float:
	return current_time / TOTAL_CYCLE

# Check if it's currently day
func is_day() -> bool:
	return get_normalized_time() < NIGHT_START

# Get current time as hours (0-24 scale for display)
func get_hour() -> int:
	var t := get_normalized_time()
	# Map 0-NIGHT_START to 6am-6pm (6-18), NIGHT_START-1.0 to 6pm-6am (18-6)
	if t < NIGHT_START:
		return int(lerp(6.0, 18.0, t / NIGHT_START))
	else:
		var night_progress := (t - NIGHT_START) / (1.0 - NIGHT_START)
		return int(lerp(18.0, 30.0, night_progress)) % 24

# Get current minute (0-59)
func get_minute() -> int:
	var t := get_normalized_time()
	var hours_float: float
	if t < NIGHT_START:
		hours_float = lerp(6.0, 18.0, t / NIGHT_START)
	else:
		var night_progress := (t - NIGHT_START) / (1.0 - NIGHT_START)
		hours_float = lerp(18.0, 30.0, night_progress)
	return int((hours_float - floor(hours_float)) * 60)

# Get formatted time string
func get_time_string() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]

# Get day count
func get_day() -> int:
	return day_count

# Set time (0.0 to 1.0)
func set_normalized_time(t: float) -> void:
	current_time = clamp(t, 0.0, 1.0) * TOTAL_CYCLE
	_update_lighting()

# Skip to next day/night
func skip_to_day() -> void:
	current_time = 0.0
	day_count += 1
	_update_lighting()

func skip_to_night() -> void:
	current_time = NIGHT_START * TOTAL_CYCLE
	_update_lighting()
