extends Node3D

@export var categories : Dictionary = {}

func UpdateOverview():
	categories.clear()
	for child in get_node("ShelfLevels").get_children():
		if child.stockType != 000 and Global.stockSys.stockInventory[child.stockType]["category"] not in categories:
			categories[Global.stockSys.stockInventory[child.stockType]["category"]] = {
				"currentStock" : child.GetShelfState().currentStock
			}
