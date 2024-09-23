extends Node3D

var interactionDic : Dictionary = {}

func _ready() -> void:
	for child in get_children():
		interactionDic[child] = {
			"Occupied" : false
		}
	
func SetInteractionSpot(spot : Node3D, value : bool):
	interactionDic[spot]["Occupied"] = value
