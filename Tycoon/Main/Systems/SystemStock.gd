extends Node

#region References
@onready var cam : Camera3D = get_node("../CamMover/Camera3D")

#endregion

#region Raycasting
var rayOrigin = Vector3()
var rayEnd = Vector3()
var rayCol

#endregion

var stockInventory : Dictionary
var categoryDic : Dictionary

var currentShelf : Node3D
var currentShelfLevel : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.switchSignal.connect(ResetEverything)
	
	EstablishCategories()
	EstablishStockInventory()
	
func _process(delta: float) -> void:
	if Global.stockMode:
		MouseRaycast()
		
func EstablishCategories():
	categoryDic["Food"] = {}
	categoryDic["Drink"] = {}
	categoryDic["Snacks"] = {}
	
func EstablishStockInventory():
	stockInventory[000] = {
		"name" : "Empty"
	}
	stockInventory[001] = {
		"name" : "Canned Goods",
		"amount" : 999,
		"category" : "Food",
		"prefab" : preload("res://Models/Stock/CannedGood.gltf")
	}
	stockInventory[002] = {
		"name" : "Fresh Produce",
		"amount" : 999,
		"category" : "Drink"
	}
	stockInventory[003] = {
		"name" : "Snacks",
		"amount" : 999,
		"category" : "Food"
	}
	stockInventory[004] = {
		"name" : "Drinks",
		"amount" : 999,
		"category" : "Drink",
		"prefab" : preload("res://Models/Stock/Drink.gltf")
	}

# A function that handles raycasting to the 3D grid and logic for deleting/building
func MouseRaycast():
	#region Raycast Setup
	var spaceState = cam.get_world_3d().direct_space_state
	var mousePos = get_viewport().get_mouse_position()
	rayOrigin = cam.project_ray_origin(mousePos)
	rayEnd = rayOrigin + cam.project_ray_normal(mousePos) * 100
	
	var query : PhysicsRayQueryParameters3D
	# Only interact with shelves
	if !Global.stocking:
		query = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd, 1);
	# Interact with shelves and shelf levels
	elif Global.stocking:
		query = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd, 9);
		
	var intersection = spaceState.intersect_ray(query)
	
	#endregion 
	
	if !intersection.is_empty():
		var colliderObj = intersection["collider"]
		if Input.is_action_just_pressed("Place"):
			if Global.mouseHover:
				return
			if (!Global.stocking and 
				colliderObj.get_parent().get_parent().is_in_group("Shelf")):
				Global.camCanMove = false
				Global.stocking = true
				currentShelf = colliderObj.get_parent().get_parent()
				cam.TweenCamera(currentShelf, 1.5, .8)
				Global.uiSys.CreateReturnButton()
			elif Global.stocking:
				if colliderObj.get_parent().is_in_group("ShelfLevel"):
					if colliderObj.get_parent().get_parent().get_parent() == currentShelf:
						currentShelfLevel = colliderObj.get_parent()
						Global.uiSys.ShelfUpdate(currentShelfLevel)
						Global.uiSys.CloseStockMenu()
						Global.uiSys.OpenStockMenu(currentShelfLevel)
					else:
						currentShelf = colliderObj.get_parent().get_parent().get_parent()
						cam.TweenCamera(currentShelf, 1.5, .8)
						Global.uiSys.CloseStockMenu()
						Global.uiSys.CreateReturnButton()
						
				elif colliderObj.get_parent().get_parent().is_in_group("Shelf"):
					if colliderObj.get_parent().get_parent() != currentShelf:
						currentShelf = colliderObj.get_parent().get_parent()
						cam.TweenCamera(currentShelf, 1.5, .8)
						Global.uiSys.CloseStockMenu()
						Global.uiSys.CreateReturnButton()
	else:
		ResetRayCol()
		

func ResetEverything():
	ResetRayCol()
	currentShelf = null
	
func ResetRayCol():
	rayCol = null
	
func StockShelf(item : int, shelf : Node3D):
	var itemsToStock = shelf.GetShelfState().maxStock - shelf.GetShelfState().currentStock
	var itemsAvailableToStock = stockInventory[item]["amount"]
	
	if shelf.updating:
		return 
		
	if shelf.stockType == 0:
		shelf.stockType = item 
		shelf.AutoStockCheck()
		itemsToStock = shelf.GetShelfState().maxStock - shelf.GetShelfState().currentStock
		StockCalc(item, shelf, itemsToStock, itemsAvailableToStock)
		
	else:
		if shelf.stockType == item:
			StockCalc(item, shelf, itemsToStock, itemsAvailableToStock)
		else:
			stockInventory[shelf.stockType]["amount"] += shelf.GetShelfState().currentStock
			shelf.stockType = item 
			shelf.AutoStockCheck()
			shelf.GetShelfState().currentStock = 0
			itemsToStock = shelf.GetShelfState().maxStock
			StockCalc(item, shelf, itemsToStock, itemsAvailableToStock)
	
	shelf.ChangeStock()
	Global.UpdateUI()
	Global.uiSys.ShelfUpdate(shelf)
	
func StockCalc(item, shelf, itemsToStock, itemsAvailableToStock):
	# Stock it to the max
	if itemsAvailableToStock >= itemsToStock:
		shelf.GetShelfState().currentStock += itemsToStock
		stockInventory[item]["amount"] -= itemsToStock
	# Stock it with the remaining items left in inventory
	else:
		shelf.GetShelfState().currentStock += itemsAvailableToStock
		stockInventory[item]["amount"] -= itemsAvailableToStock

func ExitStock():
	Global.uiSys.CloseStockMenu()
	currentShelf = null
	currentShelfLevel = null
	cam.ExitTween()
	Global.stocking = false
	Global.camCanMove = true
	
