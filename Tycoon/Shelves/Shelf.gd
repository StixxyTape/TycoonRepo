extends Node

var stockType : int = 000
var updating : bool = false

func _ready() -> void:
	add_child(get_node("../../ShelfStates").duplicate())
				
func GetShelfState():
	return get_node("ShelfStates/" + Global.stockSys.stockInventory[stockType]["name"])

func AutoStockCheck(item : int):
	if item != stockType:
		get_node("ShelfStates/" + Global.stockSys.stockInventory[item]["name"]).ClearStock()
	if get_node("ShelfStates/" + Global.stockSys.stockInventory[stockType]["name"]).autoStock:
		get_node("ShelfStates/" + Global.stockSys.stockInventory[stockType]["name"]).AutoStock()

func ChangeStock():
	GetShelfState().ChangeStock()
	get_parent().get_parent().UpdateOverview()

func CustomerUpdate(amountTaken : int):
	GetShelfState().CustomerUpdateStock(amountTaken)
	get_parent().get_parent().UpdateOverview()
