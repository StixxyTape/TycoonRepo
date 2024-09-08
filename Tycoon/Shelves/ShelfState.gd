extends Node3D

## If enabled, maxStock, currentStock, and
## stock positions are automatically assigned
## by calculating the width of the shelf
@export var autoStock : bool = false
@export var stockPref : PackedScene 

@export var maxStock : int = 10
@export var currentStock : int = 0

@export var objBuffer : float = 0.2

var stockDic : Dictionary = {}
var zSlots : Array = []
var horizontalSlots : Array = []
var verticalSlots : Array = []

func AutoStock():
	var objRot = get_node(
			"../../../../ShelfLevels"
			).get_parent().rotation_degrees.y
			
	var collider : CollisionShape3D = get_node(
			"../../StaticBody3D"
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
	print(objAmountY)
	for slot in horizontalSlots:
		verticalSlots.append(slot)
	for num in objAmountY - 1:
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
	
func UpdateStock():
	for obj in currentStock:
		for entry in stockDic:
			if stockDic[entry]["object"] == null:
				stockDic[entry]["object"] = stockPref.instantiate()
				add_child(stockDic[entry]["object"])
				stockDic[entry]["object"].position = entry
				break

func ClearStock():
	for entry in stockDic:
		if stockDic[entry]["object"] != null:
			stockDic[entry]["object"].queue_free()
			stockDic[entry]["object"] = null
