extends Node3D

var objSize : Vector3
var cellExtents : PackedVector2Array

signal extentsCalculated

func _ready() -> void:
	objSize = (global_transform * get_child(0).get_aabb()).size
	cellExtents = [
		round(Vector2(global_position.x - objSize.x / 2, global_position.z - objSize.z / 2)),
		round(Vector2(global_position.x + objSize.x / 2, global_position.z + objSize.z / 2)),
	]
	
	extentsCalculated.emit()
	
	for edge : MeshInstance3D in $Edges.get_children():
		edge.set_surface_override_material(
			0, 
			edge.get_surface_override_material(0).duplicate()
		) 
