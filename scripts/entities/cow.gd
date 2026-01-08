# ==============================================================================
# Cow Mob - Spotted Multi-box Entity
# ==============================================================================
# Extends the base Mob class with a unique multi-box visual model with spots.
# ==============================================================================

class_name Cow
extends Mob

func _ready() -> void:
	super._ready()
	# Cows are slower than sheep
	move_speed = 1.4

# Override visual creation for a spotted cow appearance
func create_visuals(color: Color = Color.WHITE) -> void:
	var cow_white := Color(1.0, 1.0, 1.0)
	var cow_black := Color(0.1, 0.1, 0.1)
	
	# 1. Body (Large horizontal box)
	var body := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(1.0, 1.0, 1.4)
	body.mesh = body_box
	
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = cow_white
	body.material_override = body_mat
	body.position.y = 0.9
	add_child(body)
	
	# 2. Add Black Spots to Body
	_add_spot(body, Vector3(0.5, 0.3, 0.2), Vector3(0.1, 0.4, 0.4), cow_black)
	_add_spot(body, Vector3(-0.5, -0.2, -0.3), Vector3(0.1, 0.3, 0.3), cow_black)
	_add_spot(body, Vector3(0.5, -0.4, -0.1), Vector3(0.1, 0.2, 0.2), cow_black)
	_add_spot(body, Vector3(0, 0.5, -0.2), Vector3(0.5, 0.1, 0.5), cow_black) # Top spot
	
	# 3. Head (Raised box at the front)
	var head := MeshInstance3D.new()
	var head_box := BoxMesh.new()
	head_box.size = Vector3(0.6, 0.7, 0.7)
	head.mesh = head_box
	
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = cow_white
	head.material_override = head_mat
	head.position = Vector3(0, 1.3, 0.8)
	add_child(head)
	
	# Black spots on head
	_add_spot(head, Vector3(0.3, 0.3, 0.3), Vector3(0.1, 0.2, 0.2), cow_black)
	
	# 4. Nose/Muzzle
	var muzzle := MeshInstance3D.new()
	var muzzle_box := BoxMesh.new()
	muzzle_box.size = Vector3(0.45, 0.35, 0.2)
	muzzle.mesh = muzzle_box
	
	var muzzle_mat := StandardMaterial3D.new()
	muzzle_mat.albedo_color = Color(0.9, 0.7, 0.7) # Pinkish nose
	muzzle.material_override = muzzle_mat
	muzzle.position = Vector3(0, 1.15, 1.15)
	add_child(muzzle)
	
	# 5. Legs (4 small boxes)
	var leg_size := Vector3(0.25, 0.7, 0.25)
	var leg_positions = [
		Vector3(0.35, 0.35, 0.5),   # Front Right
		Vector3(-0.35, 0.35, 0.5),  # Front Left
		Vector3(0.35, 0.35, -0.5),  # Back Right
		Vector3(-0.35, 0.35, -0.5)  # Back Left
	]
	
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.2, 0.2, 0.2) # Dark legs
	
	for pos in leg_positions:
		var leg := MeshInstance3D.new()
		var leg_box := BoxMesh.new()
		leg_box.size = leg_size
		leg.mesh = leg_box
		leg.material_override = leg_mat
		leg.position = pos
		add_child(leg)
	
	# Update Collision Shape
	for child in get_children():
		if child is CollisionShape3D:
			child.queue_free()
			
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.1, 1.6, 1.6)
	collision.shape = shape
	collision.position.y = 0.8
	add_child(collision)

# Helper for adding spots
func _add_spot(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var spot := MeshInstance3D.new()
	var spot_box := BoxMesh.new()
	spot_box.size = size
	spot.mesh = spot_box
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	spot.material_override = mat
	spot.position = pos
	parent.add_child(spot)
