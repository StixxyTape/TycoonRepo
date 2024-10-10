extends Node

var stockType : int = 000
var updating : bool = false
				
func GetShelfState():
	return get_node("ShelfState")

func AutoStockCheck():
	GetShelfState().ClearStock()
	if GetShelfState().autoStock and stockType != 000:
		GetShelfState().stockPref = Global.stockSys.stockInventory[stockType]["prefab"]
		GetShelfState().AutoStock()

func ChangeStock():
	GetShelfState().ChangeStock()
	get_parent().get_parent().UpdateOverview()

func CustomerUpdate(amountTaken : int):
	GetShelfState().CustomerUpdateStock(amountTaken)
	get_parent().get_parent().UpdateOverview()
