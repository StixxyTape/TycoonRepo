extends Node3D

func _ready():
	for child in get_children():
		child.position = Vector3(
			randf_range(-0.4, 0.4),
			0.1,
			randf_range(-0.4, 0.4),
		)
		child.rotation_degrees.y = randf_range(0, 180)
