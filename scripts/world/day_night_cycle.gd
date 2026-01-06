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
	
	# Transition thresholds
	const DAWN_END := 0.1
	const DAY_END := 0.6
	const SUNSET_END := 0.67 # NIGHT_START
	const DUSK_END := 0.75
	
	var light_energy: float
	var sky_color: Color
	var ambient_color: Color
	var sun_color: Color
	
	# Five-Phase Interpolation
	if t < DAWN_END:
		# Dawn: Night to Day
		var factor := t / DAWN_END
		sky_color = SKY_NIGHT.lerp(SKY_DAY, factor)
		ambient_color = AMBIENT_NIGHT.lerp(AMBIENT_DAY, factor)
		light_energy = lerp(0.08, 1.0, factor)
		sun_color = SUN_NIGHT.lerp(SUN_DAY, factor)
	elif t < DAY_END:
		# Full Day
		sky_color = SKY_DAY
		ambient_color = AMBIENT_DAY
		light_energy = 1.0
		sun_color = SUN_DAY
	elif t < SUNSET_END:
		# Sunset: Day to Sunset Orange
		var factor := (t - DAY_END) / (SUNSET_END - DAY_END)
		sky_color = SKY_DAY.lerp(SKY_SUNSET, factor)
		ambient_color = AMBIENT_DAY.lerp(AMBIENT_SUNSET, factor)
		light_energy = lerp(1.0, 0.3, factor)
		sun_color = SUN_DAY.lerp(SUN_SUNSET, factor)
	elif t < DUSK_END:
		# Dusk: Sunset Orange to Deep Night
		var factor := (t - SUNSET_END) / (DUSK_END - SUNSET_END)
		sky_color = SKY_SUNSET.lerp(SKY_NIGHT, factor)
		ambient_color = AMBIENT_SUNSET.lerp(AMBIENT_NIGHT, factor)
		light_energy = lerp(0.3, 0.08, factor)
		sun_color = SUN_SUNSET.lerp(SUN_NIGHT, factor)
	else:
		# Deep Night
		sky_color = SKY_NIGHT
		ambient_color = AMBIENT_NIGHT
		light_energy = 0.08
		sun_color = SUN_NIGHT
	
	# Rotate sun continuously throughout the whole cycle (0 to -360)
	sun_light.rotation_degrees.x = lerp(0.0, -360.0, t)
	
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
		
		# Smooth ambient energy lerp (avoids code jumps)
		# Maps light_energy 0.08 - 1.0 to ambient 0.15 - 0.8
		var ambient_factor := (light_energy - 0.08) / (1.0 - 0.08)
		env.ambient_light_energy = lerp(0.15, 0.8, ambient_factor)

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
