extends Node3D

var shelfColliders : Array

func _ready() -> void:
	for level in get_children():
		shelfColliders.append(level.get_node("StaticBody3D/CollisionShape3D"))
	DeactivateShelfLevels()	
	
func ActivateShelfLevels():
	for collider in shelfColliders:
		collider.disabled = false

func DeactivateShelfLevels():
	for collider in shelfColliders:
		collider.disabled = true
