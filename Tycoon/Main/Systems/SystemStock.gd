extends Node

#region References
@onready var cam : Camera3D = get_node("../CamMover/Camera3D")
@onready var uiSys : Control = get_tree().current_scene.get_node("UISystem")

#endregion

#region Raycasting
var rayOrigin = Vector3()
var rayEnd = Vector3()
var rayCol

#endregion

var stockInventory : Dictionary

var currentShelf : Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.switchSignal.connect(ResetEverything)
	
	stockInventory[000] = {
		"name" : "Empty"
	}
	stockInventory[001] = {
		"name" : "Canned Goods",
		"amount" : 10
	}
	stockInventory[002] = {
		"name" : "Fresh Produce",
		"amount" : 5
	}
	stockInventory[003] = {
		"name" : "Snacks",
		"amount" : 15
	}
	stockInventory[004] = {
		"name" : "Drinks",
		"amount" : 10
	}
	
func _process(delta: float) -> void:
	if Global.stockMode:
		MouseRaycast()
		InputManager()

func InputManager():
	if Input.is_action_just_pressed("Place"):
		pass
		
# A function that handles raycasting to the 3D grid and logic for deleting/building
func MouseRaycast():
	#region Raycast Setup
	var spaceState = cam.get_world_3d().direct_space_state
	var mousePos = get_viewport().get_mouse_position()
	rayOrigin = cam.project_ray_origin(mousePos)
	rayEnd = rayOrigin + cam.project_ray_normal(mousePos) * 100
	
	var query : PhysicsRayQueryParameters3D
	query = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd, 1);
		
	var intersection = spaceState.intersect_ray(query)
	
	#endregion 
	
	if !intersection.is_empty():
		var colliderObj = intersection["collider"].get_parent().get_parent()
		if Input.is_action_just_pressed("Place") and colliderObj.is_in_group("Shelf"):
			if Global.mouseHover:
				return
			var shelf = colliderObj
			currentShelf = shelf
			uiSys.ShelfUpdate(currentShelf)
			uiSys.CloseStockMenu()
			uiSys.OpenStockMenu(currentShelf)
			Global.camCanMove = false
			Global.stocking = true
			cam.TweenCamera(currentShelf, 1.5, .8)
	else:
		ResetRayCol()
		

func ResetEverything():
	ResetRayCol()
	currentShelf = null
	
func ResetRayCol():
	rayCol = null
	
func StockShelf(item : int, shelf : Node3D):
	var itemsToStock = shelf.maxStock - shelf.currentStock
	var itemsAvailableToStock = stockInventory[item]["amount"]
	
	if shelf.stockType == 0:
		shelf.stockType = item 
		StockCalc(item, shelf, itemsToStock, itemsAvailableToStock)
		
	else:
		if shelf.stockType == item:
			StockCalc(item, shelf, itemsToStock, itemsAvailableToStock)
		else:
			stockInventory[shelf.stockType]["amount"] += shelf.currentStock
			shelf.stockType = item 
			shelf.currentStock = 0
			itemsToStock = shelf.maxStock
			StockCalc(item, shelf, itemsToStock, itemsAvailableToStock)
	
	Global.UpdateUI()
	uiSys.ShelfUpdate(currentShelf)
	
func StockCalc(item, shelf, itemsToStock, itemsAvailableToStock):
	# Stock it to the max
	if itemsAvailableToStock >= itemsToStock:
		shelf.currentStock += itemsToStock
		stockInventory[item]["amount"] -= itemsToStock
	# Stock it with the remaining items left in inventory
	else:
		shelf.currentStock += itemsAvailableToStock
		stockInventory[item]["amount"] -= itemsAvailableToStock

func ExitStock():
	uiSys.CloseStockMenu()
	currentShelf = null
	cam.ExitTween()
	Global.stocking = false
	Global.camCanMove = true
	
