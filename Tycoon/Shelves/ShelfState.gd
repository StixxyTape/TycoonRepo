extends Node3D

## If enabled, maxStock, currentStock, and
## stock positions are automatically assigned
## by calculating the width of the shelf
@export var autoStock : bool = false

@export var maxStock : int = 10
@export var currentStock : int = 0

@export var objBuffer : float = 0.2

var stockPref : PackedScene

var stockDic : Dictionary = {}
var zSlots : Array
var horizontalSlots : Array 
var verticalSlots : Array 

var rowAmount : int
var rowsAmount : int
var columnAmount : int

func AutoStock():
	
	zSlots = []
	horizontalSlots = []
	verticalSlots = []
	
	rowAmount = 0
	rowsAmount = 1
	columnAmount = 1
	
	var objRot = get_node(
			"../../../ShelfLevels"
			).get_parent().rotation_degrees.y
			
	var collider : CollisionShape3D = get_node(
			"../StaticBody3D"
			).get_child(0)
			
	var newObj = stockPref.instantiate()
	newObj.rotation_degrees.y = objRot
	add_child(newObj)
	var newObjSize : Vector3 = (
		newObj.get_child(0).global_transform * 
		newObj.get_child(0).get_aabb()
		).size
	newObj.queue_free()
	
	#print("Stock Size: ", newObjSize)
	#print("Shelf Size: ", collider.shape.size)
	
	#print(floor(collider.shape.size.z / newObjSize.z))
	
	#print("Normal Pos: ", collider.global_position.x)
	var objAmount : float = floor(collider.shape.size.z / newObjSize.z)
	var objGap = objBuffer * newObjSize.z
	objAmount = floor(collider.shape.size.z / (newObjSize.z + objGap))
	var objOffsetZ : float = objGap
	objOffsetZ += ((
		collider.shape.size.z / (newObjSize.z + objGap) - objAmount
		) / 2) / objAmount
	for num in objAmount:
		rowAmount += 1
		var newShelfObj = stockPref.instantiate()
		newShelfObj.rotation_degrees.y = objRot
		#add_child(newShelfObj)
		newShelfObj.position.z = collider.position.z - (
			(collider.shape.size.z - newObjSize.z) / 2) + objOffsetZ
		newShelfObj.position.x = collider.position.x - (
			(collider.shape.size.x - newObjSize.x) / 2)
		newShelfObj.position.y = collider.position.y - (collider.shape.size.y / 2)
		objOffsetZ += (newObjSize.z + objGap)
		zSlots.append(newShelfObj.position)
	
	var objAmountX : float = floor(collider.shape.size.x / newObjSize.x)
	var objGapX = objBuffer * newObjSize.x
	objAmountX = floor(collider.shape.size.x / (newObjSize.x + objGapX))
	objGapX += newObjSize.x
	#print(newObjSize.x)
	#print(objAmountX)
	for slot in zSlots:
		horizontalSlots.append(slot)
	for num in objAmountX - 1:
		rowsAmount += 1
		for slot in zSlots:
			var newShelfObj = stockPref.instantiate()
			newShelfObj.rotation_degrees.y = objRot
			#add_child(newShelfObj)
			newShelfObj.position.z = slot.z
			newShelfObj.position.y = slot.y
			newShelfObj.position.x = slot.x + objGapX
			horizontalSlots.append(newShelfObj.position)
		objGapX += newObjSize.x + (objBuffer * newObjSize.x)

	var objAmountY : float = floor(collider.shape.size.y / newObjSize.y)
	var objGapY = objBuffer * newObjSize.y
	objAmountY = floor(collider.shape.size.y / (newObjSize.y + objGapY))
	objGapY = newObjSize.y
	for slot in horizontalSlots:
		verticalSlots.append(slot)
	for num in objAmountY - 1:
		columnAmount += 1
		for slot in horizontalSlots:
			var newShelfObj = stockPref.instantiate()
			newShelfObj.rotation_degrees.y = objRot
			#add_child(newShelfObj)
			newShelfObj.position.z = slot.z
			newShelfObj.position.y = slot.y + objGapY
			newShelfObj.position.x = slot.x
			verticalSlots.append(newShelfObj.position)
		objGapY += newObjSize.y
	
	if verticalSlots.size() == 0:
		for slot in horizontalSlots:
			if slot not in stockDic:
				stockDic[slot] = {
					"object" : null
				}
	else:
		for slot in verticalSlots:
			if slot not in stockDic:
				stockDic[slot] = {
					"object" : null
				}
	maxStock = stockDic.size()
	
func ChangeStock():
	get_parent().updating = true
	for obj in currentStock:
		for entry in stockDic:
			if stockDic[entry]["object"] == null:
				#await get_tree().create_timer(.1).timeout
				stockDic[entry]["object"] = stockPref.instantiate()
				add_child(stockDic[entry]["object"])
				stockDic[entry]["object"].position = entry
				break
	get_parent().updating = false

func ClearStock():
	for entry in stockDic:
		if stockDic[entry]["object"] != null:
			stockDic[entry]["object"].queue_free()
			stockDic[entry]["object"] = null
	
	stockDic.clear()

# When customers grab from the shelf
func CustomerUpdateStock(amountTaken : int):
	for obj in amountTaken:
		while true:
			var entryPos : int = randi_range(0, stockDic.size() - 1)
			var entry : Vector3 = stockDic.keys()[entryPos]
			if stockDic[entry]["object"] != null:
				var verticalPos : int = entryPos + (rowAmount * rowsAmount)
				var verticalCheck : Vector3 
				if verticalPos < stockDic.size():
					verticalCheck = stockDic.keys()[verticalPos]
					
				var horizontalPos : int = entryPos + rowAmount
				var horizontalCheck : Vector3 
				if horizontalPos < stockDic.size():
					horizontalCheck = stockDic.keys()[horizontalPos]
					
				if (verticalPos >= stockDic.size() or 
				(verticalPos < stockDic.size() and stockDic[verticalCheck]["object"] == null)):
					var entryColumn : int = 0
					for x in columnAmount:
						x += 1
						if entryPos <= (maxStock / columnAmount) * x:
							entryColumn = x
					var horizontalCheckColumn : int = 0
					for x in columnAmount:
						x += 1
						if horizontalPos <= (maxStock / columnAmount) * x:
							horizontalCheckColumn = x
					if (horizontalPos >= stockDic.size() 
					or (horizontalCheckColumn != entryColumn)
					or (stockDic[horizontalCheck]["object"] == null)):
						stockDic[entry]["object"].queue_free()
						stockDic[entry]["object"] = null
						break
					
