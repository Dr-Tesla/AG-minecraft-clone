# ==============================================================================
# Noise Generator - Perlin Noise Wrapper
# ==============================================================================
# Provides a simple interface to Godot's FastNoiseLite for terrain generation.
# Uses 2D noise for heightmap and 3D noise for caves/features.
# ==============================================================================

class_name NoiseGenerator
extends RefCounted

var noise: FastNoiseLite

# Configuration
var _seed: int = 0
var _frequency: float = 0.02
var _octaves: int = 4

func _init(seed_value: int = 12345) -> void:
	_seed = seed_value
	noise = FastNoiseLite.new()
	noise.seed = _seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = _frequency
	noise.fractal_octaves = _octaves
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM

# Set the noise seed
func set_seed(value: int) -> void:
	_seed = value
	noise.seed = _seed

# Set the frequency (lower = larger features)
func set_frequency(value: float) -> void:
	_frequency = value
	noise.frequency = _frequency

# Set the number of octaves (more = more detail)
func set_octaves(value: int) -> void:
	_octaves = value
	noise.fractal_octaves = _octaves

# Get 2D noise value at (x, z) - returns value in range [-1, 1]
func get_noise_2d(x: float, z: float) -> float:
	return noise.get_noise_2d(x, z)

# Get 3D noise value at (x, y, z) - returns value in range [-1, 1]
func get_noise_3d(x: float, y: float, z: float) -> float:
	return noise.get_noise_3d(x, y, z)

# Get normalized 2D noise (0-1 range)
func get_noise_2d_normalized(x: float, z: float) -> float:
	return (noise.get_noise_2d(x, z) + 1.0) / 2.0

# Get height value at world position (scaled to useful range)
func get_height(x: float, z: float, min_height: int, max_height: int) -> int:
	var normalized := get_noise_2d_normalized(x, z)
	return int(lerp(float(min_height), float(max_height), normalized))
