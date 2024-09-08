extends Node

var stockType : int = 000

func _ready() -> void:
	add_child(get_node("../../ShelfStates").duplicate())
				
func GetShelfState():
	return get_node("ShelfStates/" + Global.stockSys.stockInventory[stockType]["name"])

func AutoStockCheck(item : int):
	if item != stockType:
		print("huh")
		get_node("ShelfStates/" + Global.stockSys.stockInventory[item]["name"]).ClearStock()
	if get_node("ShelfStates/" + Global.stockSys.stockInventory[stockType]["name"]).autoStock:
		get_node("ShelfStates/" + Global.stockSys.stockInventory[stockType]["name"]).AutoStock()

func UpdateStock():
	get_node("ShelfStates/" + Global.stockSys.stockInventory[stockType]["name"]).UpdateStock()
