# ==============================================================================
# Sheep Mob - Multi-box Entity
# ==============================================================================
# Extends the base Mob class with a unique multi-box visual model.
# ==============================================================================

class_name Sheep
extends Mob

func _ready() -> void:
	super._ready()
	# Sheep move slightly slower than generic mobs
	move_speed = 1.8

# Override visual creation for a sheep-like appearance
func create_visuals(color: Color = Color.WHITE) -> void:
	# Sheep are usually white/creamy
	var sheep_white := Color(0.95, 0.95, 0.9)
	
	# 1. Body (Large horizontal box)
	var body := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(0.9, 0.9, 1.2)
	body.mesh = body_box
	
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = sheep_white
	body.material_override = body_mat
	body.position.y = 0.8
	add_child(body)
	
	# 2. Head (Raised box at the front)
	var head := MeshInstance3D.new()
	var head_box := BoxMesh.new()
	head_box.size = Vector3(0.5, 0.5, 0.5)
	head.mesh = head_box
	
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.9, 0.85, 0.8) # Slightly darker for face
	head.material_override = head_mat
	head.position = Vector3(0, 1.1, 0.6)
	add_child(head)
	
	# 3. Nose/Muzzle
	var muzzle := MeshInstance3D.new()
	var muzzle_box := BoxMesh.new()
	muzzle_box.size = Vector3(0.3, 0.2, 0.2)
	muzzle.mesh = muzzle_box
	
	var muzzle_mat := StandardMaterial3D.new()
	muzzle_mat.albedo_color = Color(0.8, 0.7, 0.6)
	muzzle.material_override = muzzle_mat
	muzzle.position = Vector3(0, 1.0, 0.8)
	add_child(muzzle)
	
	# 4. Legs (4 small boxes)
	var leg_size := Vector3(0.15, 0.6, 0.15)
	var leg_positions = [
		Vector3(0.3, 0.3, 0.4),   # Front Right
		Vector3(-0.3, 0.3, 0.4),  # Front Left
		Vector3(0.3, 0.3, -0.4),  # Back Right
		Vector3(-0.3, 0.3, -0.4)  # Back Left
	]
	
	for pos in leg_positions:
		var leg := MeshInstance3D.new()
		var leg_box := BoxMesh.new()
		leg_box.size = leg_size
		leg.mesh = leg_box
		leg.material_override = head_mat # Same as face
		leg.position = pos
		add_child(leg)
	
	# Update Collision Shape
	for child in get_children():
		if child is CollisionShape3D:
			child.queue_free()
			
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 1.4, 1.3)
	collision.shape = shape
	collision.position.y = 0.7
	add_child(collision)
