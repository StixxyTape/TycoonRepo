extends Node

#region References
@onready var cam : Camera3D = get_node("../CamMover/Camera3D")

#endregion

#region Raycasting
var rayOrigin = Vector3()
var rayEnd = Vector3()
var rayCol

#endregion

#region General Building
# 0 Means deleting, 1 means cell building, 2 means edge building, 3 means floor building, 4 means land mode
var buildMode : int = 0

# For keeping track of rotation
var objectRotation : int = 0

var currentCellPref : PackedScene
#var currentCellPreviewPref : PackedScene
var currentEdgePref : PackedScene
var currentFloorPref : PackedScene


#endregion

#region Building Preview
# A reference to the current preview object
var previewStruct : Node3D
# A dictionary for building multiple walls at once
var previewStructures : Dictionary
# The starting position of cell building, for dragging multiple objects at once
var gridPreviewAxis : Array
# The axis and scale of wall building, for dragging multiple walls at once
var edgePreviewAxis : Array
# Same shabang as before but for floors
var floorPreviewAxis : Array

# For visually showing if you can place an object down
var highlightedCells : Array
var resetCol : Color = Color(1, 1, 1, 1)
var greenCellCol : Color = Color(0.5, 1, 0.5, 1)
var redCellCol : Color = Color(1, 0.5, 0.5, 1)

#endregion

#region Structures
var wallPref : PackedScene = preload("res://Models/Building/Structure/WallTile/WallTile.gltf")
var previewWallPref : PackedScene = preload("res://Models/Building/Structure/WallTile/PreviewWallTile.gltf")

var doubleDoorPref : PackedScene = preload("res://Models/Building/Structure/DoubleDoor/DoubleDoor.gltf")
var longWallPref : PackedScene = preload("res://Models/Building/Structure/LongWall/LongWall.gltf")
var megaWallPref : PackedScene = preload("res://Models/Building/Structure/MegaWall/MegaWall.gltf")

var floorPref : PackedScene = preload("res://Models/Building/Structure/FloorTile/FloorTile.gltf")

var stairPref : PackedScene = preload("res://Models/Building/Structure/Stairs/Stairs.gltf")

#endregion

#region Shelves
var basicShelfPreview : PackedScene = preload("res://Models/Building/Shelving/BasicShelf/BasicShelf.gltf")
var singleFridgePref : PackedScene = preload("res://Models/Building/Shelving/SingleFridge/SingleFridge.gltf")
var displayTablePref : PackedScene = preload("res://Models/Building/Shelving/DisplayTable/DisplayTable.gltf")
var longShelfPref : PackedScene = preload("res://Models/Building/Shelving/LongShelf/shelves.gltf")


var basicShelfPref : PackedScene = preload("res://Shelves/BasicShelf.tscn")

#endregion

#region Facilities
var basicCheckoutPref : PackedScene = preload("res://Facilities/Checkouts/BasicCheckout.tscn")

#endregion

#region Delete Mode
# An array containing all selected objects for deletion. Can include walls and floors
var objectsToDelete : Array
# -1 means it isn't set yet, 0 means its for objects, 1 means for edges, 2 for floors
var deleteMode : int = -1
# The red highlighted object when hovering in delete mode
var objToDelPreview : Node3D
# For edge deleting, to save the initial deletion rotation
var deleteEdgeRotation : bool

#endregion

#region MultiSelect
# If set to -1, means origin hasn't been set yet
var ogMultiSelectCell : Vector2 = Vector2(-99, -99)
var ogMultiSelectEdge : Vector2 = Vector2(-99, -99)
# For keeping track of previously selected cells to update them
var previousSelectedCells : Array

#endregion

#region MultiFloor
var currentFloor : int = 0
var currentHeight : float = 0

var floorObjects : Array
var floorEdges : Array
var floorFloors : Array 

#endregion

# For Shopping
var structureDic : Dictionary 
var edgeStructureDic : Dictionary

func _ready() -> void:
	EstablishStructureDic()
	EstablishEdgeDic()
	
	Global.switchSystemSignal.connect(ResetEverything)
	
	currentCellPref = basicShelfPref
	#currentCellPreviewPref = basicShelfPref
	currentEdgePref = wallPref
	currentFloorPref = floorPref
	
	for dic in Global.gridSys.floorGridDics:
		var newObjectArray : Array = []
		floorObjects.append(newObjectArray)
		var newEdgeArray : Array = []
		floorEdges.append(newEdgeArray)
		var newFloorArray : Array = []
		floorFloors.append(newFloorArray)

func _process(delta):
	currentHeight = currentFloor * Global.gridSys.wallHeight
	if Global.currentMode == 1:
		MouseRaycast()
		InputManager()
	
func EstablishStructureDic():
	structureDic[str(basicShelfPref)] = {
		"name" : "Double Shelf",
		"cost" : 100,
		"prefab" : basicShelfPref
	}
	structureDic[str(basicCheckoutPref)] = {
		"name" : "Checkout",
		"cost" : 200,
		"prefab" : basicCheckoutPref
	}
	
func EstablishEdgeDic():
	edgeStructureDic[str(wallPref)] = {
		"name" : "Wall",
		"cost" : 20,
		"prefab" : wallPref
	}
	edgeStructureDic[str(doubleDoorPref)] = {
		"name" : "Double Doors",
		"cost" : 150,
		"prefab" : doubleDoorPref
	}

func SwapBuildPref(prefab : PackedScene, type : int):
	print("BITCH")
	#type 1 is obj, 2 is edge, 3 is floor
	if type == 1:
		currentCellPref = prefab
	elif type == 2:
		currentEdgePref = prefab
	elif type == 3:
		currentFloorPref = prefab
		
func InputManager():
	if Input.is_action_just_pressed("Rotate"):
		objectRotation += 90
		objectRotation = wrapf(objectRotation, 0, 360)
		print(objectRotation)
	if Input.is_action_just_pressed("DeleteMode"):
		ResetDeletionObjects()
		ResetHighlightedCells()
		ResetDeletionObj()
		ResetDeletionCells()
		ResetPreview()
		buildMode = 0
		SwapBuildMode(0)
	if buildMode == 0 and Input.is_action_just_released("Place"):
		ResetDeletionCells()
		ResetDeletionObj()
		if objectsToDelete.size() > 0:
			DeleteObjects()
	#if Input.is_action_just_pressed("Floor Up"):
		#ResetDeletionObjects()
		#ResetHighlightedCells()
		#ResetDeletionObj()
		#ResetDeletionCells()
		#ResetPreview()
		#currentFloor += 1
		#currentFloor = clampi(currentFloor, 0, Global.gridSys.maxFloor)
		#Global.gridSys.gridBody.position.y += Global.gridSys.wallHeight
		#Global.gridSys.gridBody.position.y = clampi(
			#Global.gridSys.gridBody.position.y,
			#0,
			#Global.gridSys.maxFloor * Global.gridSys.wallHeight
		#)
		#HideFloors()
	#if Input.is_action_just_pressed("Floor Down"):
		#ResetDeletionObjects()
		#ResetHighlightedCells()
		#ResetDeletionObj()
		#ResetDeletionCells()
		#ResetPreview()
		#currentFloor -= 1
		#currentFloor = clampi(currentFloor, 0, Global.gridSys.maxFloor)
		#Global.gridSys.gridBody.position.y -= Global.gridSys.wallHeight
		#Global.gridSys.gridBody.position.y = clampi(
			#Global.gridSys.gridBody.position.y,
			#0,
			#Global.gridSys.maxFloor * Global.gridSys.wallHeight
		#)
		#HideFloors()

func SwapBuildMode(mode : int):
	buildMode = mode
	#if mode == 3:
		#Global.floatingGridSys.ShowBuildGrid()
	#else:
		#Global.floatingGridSys.HideBuildGrid()
	ResetHighlightedCells()
	ResetPreview()
	ResetDeletionObj()
	ResetDeletionObjects()
	ResetDeletionCells()
	
func ResetEverything():
	ResetDeletionCells()
	ResetDeletionObj()
	ResetDeletionObjects()
	ResetHighlightedCells()
	ResetPreview()
	ResetRayCol()
	
# A function that handles raycasting to the 3D grid and logic for deleting/building
func MouseRaycast():
	#region Raycast Setup
	var spaceState = cam.get_world_3d().direct_space_state
	var mousePos = get_viewport().get_mouse_position()
	rayOrigin = cam.project_ray_origin(mousePos)
	rayEnd = rayOrigin + cam.project_ray_normal(mousePos) * 100
	
	var query : PhysicsRayQueryParameters3D
	
	# Set the collision value to 6 so it only affects floors
	# And the gridCollider (incase of being on a new floor)
	if buildMode != 0:
		query = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd, 6);
	# Set the collision value to 3 so it also intersects with objects for deletion
	else:
		query = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd, 7);
		
	var intersection = spaceState.intersect_ray(query)
	
	#endregion 
	
	if !intersection.is_empty():
		var colPoint : Vector2 = Vector2(
			intersection["position"].x, 
			intersection["position"].z
			)
		if Global.mouseHover or buildMode == 4:
			ResetEverything()
			return
		if round(colPoint) not in Global.landSys.ownedCells:
			if (buildMode == 0 and objectsToDelete.size() == 0 and 
			intersection["collider"].get_parent().get_parent() not in floorEdges[currentFloor]):
				ResetEverything()
				return
		if buildMode == 0:
			if ((intersection["collider"].get_parent().get_parent() in floorObjects[currentFloor]
			or intersection["collider"].get_parent().get_parent() in floorEdges[currentFloor]
			or intersection["collider"].get_parent().get_parent() in floorFloors[currentFloor])
			or intersection["collider"].is_in_group("GridFloor")):
				var objMesh : MeshInstance3D
				
				if Input.is_action_pressed("Place"):
					ResetDeletionObj()
					
					if intersection["collider"].is_in_group("GridFloor"):
						if deleteMode == -1:
							deleteMode = 2
					else:
						objMesh = intersection["collider"].get_parent()
					
					if deleteMode == -1:
						deleteMode = 0
						if objMesh.get_parent().is_in_group("Edge"):
							deleteMode = 1
							deleteEdgeRotation = ObjectRotationCheck(objMesh.get_parent())
						elif objMesh.get_parent().is_in_group("Floor"):
							deleteMode = 2
							
					if deleteMode == 0:
						GridDelete(colPoint)
								
					elif deleteMode == 1:
						EdgeDelete(colPoint,
						deleteEdgeRotation
						)
					elif deleteMode == 2:
						FloorDelete(colPoint)
				else:
					if !intersection["collider"].is_in_group("GridFloor"):
						objMesh = intersection["collider"].get_parent()
						objMesh.get_active_material(0).albedo_color = redCellCol
						# An edge case if the mouse jumps from one object to another
						if objMesh.get_parent() != objToDelPreview:
							ResetDeletionObj()
							objToDelPreview = objMesh.get_parent()
					else:
						ResetDeletionObj()
					
		elif buildMode == 1:
			# We establish a gridpoint for dictionary access
			var gridPoint : Vector2 = Global.gridSys.GlobalToGrid(colPoint)
				# We sub in the actual colPoint for complex meshes
			CellPreview(colPoint)
			if (Input.is_action_just_pressed("ui_accept")
			and gridPoint in Global.gridSys.floorGridDics[currentFloor]):
				print(Global.gridSys.floorGridDics[currentFloor][gridPoint])
		elif buildMode == 2:
			# We establish an edgePoint for dictionary access
			var edgePoint : Vector2 = Global.gridSys.GlobalToEdge(colPoint, RotationCheck())
			#if Global.gridSys.floorEdgeDics[currentFloor].has(edgePoint):
			if intersection["collider"].get_parent().get_parent().is_in_group("Floor"):
				if intersection["collider"].get_parent().get_parent() in floorFloors[currentFloor]:
					EdgePreview(colPoint)
			else:
				EdgePreview(colPoint)
			if (Input.is_action_just_pressed("ui_accept")
			and edgePoint in Global.gridSys.floorEdgeDics[currentFloor]):
				print(Global.gridSys.floorEdgeDics[currentFloor][edgePoint])
		elif buildMode == 3:
			var gridPoint : Vector2 = Global.gridSys.GlobalToGrid(colPoint)
			#if Global.gridSys.floorGridDics[currentFloor].has(gridPoint):
			if round(intersection["position"].y) == currentHeight:
				FloorPreview(colPoint)
			if (Input.is_action_just_pressed("ui_accept")
			and gridPoint in Global.gridSys.floorGridDics[currentFloor]):
				print(Global.gridSys.floorGridDics[currentFloor][gridPoint])
	else:
		# If the raycast doesn't hit anything, reset most grid variables
		ResetRayCol()
		ResetDeletionObj()
		if Input.is_action_just_released("Place"):
			ResetHighlightedCells()
			ResetPreview()
		
func ResetRayCol():
	rayCol = null
	if is_instance_valid(previewStruct):
		previewStruct.queue_free()

func RotationCheck():
	if objectRotation % 180 == 0:
		return false
	else:
		return true

func ObjectRotationCheck(obj : Node3D):
	if int(obj.rotation_degrees.y) % 180 == 0:
		return false
	else:
		return true
		
func GridDelete(colPoint : Vector2):
	var selectionResults : Array = MultiSelectGrid(colPoint)
	var intersectingCells : Array = selectionResults[0]
	var intersectingEdges : Array = selectionResults[1]
	
	if previousSelectedCells.size() > 0:
		for cell in previousSelectedCells:
			if Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]:
				Global.gridSys.GetMaterial(
					Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]
					).albedo_color = resetCol
	
	previousSelectedCells = intersectingCells
	
	for obj in objectsToDelete:
		obj.get_active_material(0).albedo_color = resetCol
	objectsToDelete.clear()
	
	for cell in intersectingCells:
		#Global.gridSys.GetMaterial(
			#Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]
			#).albedo_color = redCellCol
		if Global.gridSys.floorGridDics[currentFloor][cell]["cellData"]:
			Global.gridSys.GetMaterial(
				Global.gridSys.floorGridDics[currentFloor][cell]["cellData"]
				).albedo_color = redCellCol
			if Global.gridSys.floorGridDics[currentFloor][cell]["cellData"].get_child(0) not in objectsToDelete:
				objectsToDelete.append(Global.gridSys.floorGridDics[currentFloor][cell]["cellData"].get_child(0))

func EdgeDelete(colPoint : Vector2, rotated : bool):
	var intersectingEdges = MultiSelectEdge(colPoint)

	for obj in objectsToDelete:
		obj.get_active_material(0).albedo_color = resetCol
	objectsToDelete.clear()
	
	for edge in intersectingEdges:
		if Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"] != null:
			Global.gridSys.GetMaterial(
				Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"]
			).albedo_color = redCellCol
			if Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"] not in objectsToDelete:
				objectsToDelete.append(Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"].get_child(0))
				
func FloorDelete(colPoint : Vector2):
	var selectionResults : Array = MultiSelectGrid(colPoint)
	var intersectingCells : Array = selectionResults[0]
	
	if previousSelectedCells.size() > 0:
		for cell in previousSelectedCells:
			if Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]:
				Global.gridSys.GetMaterial(
					Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]
					).albedo_color = resetCol
	
	previousSelectedCells = intersectingCells
	
	for obj in objectsToDelete:
		obj.get_active_material(0).albedo_color = resetCol
	objectsToDelete.clear()
	
	for cell in intersectingCells:
		if cell not in Global.landSys.ownedCells:
			continue
		if Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]:
			Global.gridSys.GetMaterial(
				Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]
				).albedo_color = redCellCol
			if Global.gridSys.floorGridDics[currentFloor][cell]["floorData"].get_child(0) not in objectsToDelete:
				objectsToDelete.append(Global.gridSys.floorGridDics[currentFloor][cell]["floorData"].get_child(0))

func ResetDeletionCells():
	if previousSelectedCells.size() > 0:
		for cell in previousSelectedCells:
			if Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]:
				Global.gridSys.GetMaterial(
					Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]
					).albedo_color = resetCol
				
		previousSelectedCells.clear()
		
	deleteMode = -1
	ogMultiSelectCell = Vector2(-99, -99)
	ogMultiSelectEdge = Vector2(-99, -99)
		
func ResetDeletionObj():
	if objToDelPreview and is_instance_valid(objToDelPreview):
		Global.gridSys.GetMaterial(objToDelPreview).albedo_color = resetCol
		objToDelPreview = null

func ResetDeletionObjects():
	if objectsToDelete.size() > 0:
		for object in objectsToDelete:
			object.get_active_material(0).albedo_color = resetCol
		objectsToDelete.clear()
		
func ResetPreview():
	if is_instance_valid(previewStruct):
		previewStruct.queue_free()
	
	gridPreviewAxis.clear()
	edgePreviewAxis.clear()
	
	if previewStructures.size() > 0:
		for struct in previewStructures:
			if is_instance_valid(previewStructures[struct]["previewObj"]):
				previewStructures[struct]["previewObj"].queue_free()
			else:
				previewStructures[struct]["previewObj"] = null
				
	previewStructures.clear()

func ResetHighlightedCells():
	if highlightedCells.size() > 0:
		for cell in highlightedCells:
			Global.gridSys.GetMaterial(cell).albedo_color = resetCol
		highlightedCells.clear()
		
func CellPreview(point : Vector2):
	if Input.is_action_just_pressed("Rotate"):
		ResetPreview()
		return
		
	if is_instance_valid(previewStruct):
		previewStruct.queue_free()

	ResetHighlightedCells()
	
	# We spawn in the object and set it's rotation for an accurate size calc
	#var newObj = currentCellPreviewPref.instantiate()
	var newObj = currentCellPref.instantiate()
	newObj.rotation_degrees.y = objectRotation
	add_child(newObj)
	
	var newObjSize : Vector3 = (
		newObj.get_child(0).global_transform * 
		newObj.get_child(0).get_aabb()
		).size
	var newPoint : Vector3 = Global.gridSys.GlobalToComplex(point, newObjSize)
	newObj.position = Vector3(newPoint.x, currentHeight, newPoint.z)
	previewStruct = newObj
	
	var objIntersection : Array
	objIntersection = HighlightCells(
		newObjSize, 
		Vector2(newPoint.x, newPoint.z)
		)
	
	var objectCells : Array = objIntersection[0]
	var objectEdges : Array = objIntersection[1]
	
	HighlightInteractionSpots(
		objectCells,
		newObj
	)
	
	var newGridPoint : Vector2 = Vector2(newPoint.x, newPoint.z)
	
	if Input.is_action_pressed("Place"):
		newObj.visible = false
			
		ResetHighlightedCells()
		
		if previewStructures.size() > 0:
			for struct in previewStructures:
				if is_instance_valid(previewStructures[struct]["previewObj"]):
					previewStructures[struct]["previewObj"].queue_free()
						
		if gridPreviewAxis.size() <= 0:
			gridPreviewAxis.append(newGridPoint)
			gridPreviewAxis.append(Vector2(newObjSize.x, newObjSize.z))
		
		if gridPreviewAxis[0].x > -99:
			var gridDist : Vector2 = Vector2(
				int(newPoint.x - gridPreviewAxis[0].x),
				int(newPoint.z - gridPreviewAxis[0].y)
				)
			var originalIntersections : Array = HighlightCells(
				newObjSize, 
				Vector2(gridPreviewAxis[0].x, gridPreviewAxis[0].y)
				)
			
			# If the original shelf is placed in an incorrect position
			if !originalIntersections[2]:
				return
				
			CreatePreviewStruct(
				Vector3(gridPreviewAxis[0].x, currentHeight, gridPreviewAxis[0].y),
				[objectCells, objectEdges]
			)
			var negXDist : bool = gridDist.x < 0
			var negYDist : bool = gridDist.y < 0
			var xDist : int = abs(gridDist.x)
			var yDist : int = abs(gridDist.y)
			
			for x in xDist:
				if (x + 1) % ceili(gridPreviewAxis[1].x) == 0:
					var newXPos : float
					if negXDist:
						newXPos = gridPreviewAxis[0].x - (x + 1)
					else:
						newXPos = gridPreviewAxis[0].x + (x + 1)
					var previewIntersections : Array = HighlightCells(
						newObjSize, 
						Vector2(newXPos, gridPreviewAxis[0].y)
						)
					if !previewIntersections[2]:
						continue
					
					CreatePreviewStruct(
						Vector3(newXPos, currentHeight, gridPreviewAxis[0].y),
						[previewIntersections[0], previewIntersections[1]]
					)
				
			for y in yDist:
				if (y + 1) % ceili(gridPreviewAxis[1].y) == 0:
					var newYPos : float
					if negYDist:
						newYPos = gridPreviewAxis[0].y - (y + 1)
					else:
						newYPos = gridPreviewAxis[0].y + (y + 1)
					var previewIntersections : Array = HighlightCells(
						newObjSize, 
						Vector2(gridPreviewAxis[0].x, newYPos)
						)
					if !previewIntersections[2]:
						continue
					CreatePreviewStruct(
						Vector3(gridPreviewAxis[0].x, currentHeight, newYPos),
						[previewIntersections[0], previewIntersections[1]]
					)
					
			for x in xDist:
				var newXPos : float
				if (x + 1) % ceili(gridPreviewAxis[1].x) == 0:
					if negXDist:
						newXPos = gridPreviewAxis[0].x - (x + 1)
					else:
						newXPos = gridPreviewAxis[0].x + (x + 1)
				for y in yDist:
					if (y + 1) % ceili(gridPreviewAxis[1].y) == 0:
						var newYPos : float
						if negYDist:
							newYPos = gridPreviewAxis[0].y - (y + 1)
						else:
							newYPos = gridPreviewAxis[0].y + (y + 1)
						var previewIntersections : Array = HighlightCells(
							newObjSize, 
							Vector2(newXPos, newYPos)
							)
						if !previewIntersections[2]:
							continue
							
						CreatePreviewStruct(
							Vector3(newXPos, currentHeight, newYPos),
							[previewIntersections[0], previewIntersections[1]]
						)
			
	if Input.is_action_just_released("Place"):
		gridPreviewAxis.clear()
		if previewStructures.size() > 0:
			for struct in previewStructures:
				if is_instance_valid(previewStructures[struct]["previewObj"]):
					previewStructures[struct]["previewObj"].queue_free()
					
					#For clearing space for interaction spots
					if !previewStructures[struct]["interactionCanPlace"]:
						continue
						
					var blockingInteractionSpot : bool = false
					var notInOwnedCells : bool = false
					
					for cell in previewStructures[struct]["cells"]:
						if cell not in Global.landSys.ownedCells:
							notInOwnedCells = true
							break
						if Global.gridSys.floorGridDics[currentFloor][cell]["interactionSpot"] > 0:
							blockingInteractionSpot = true
							break
					for cell in previewStructures[struct]["interactionCells"]:
						if Global.gridSys.floorGridDics[currentFloor][cell]["cellData"] != null:
							blockingInteractionSpot = true
							break
					if blockingInteractionSpot or notInOwnedCells:
						continue
					
					var price : int = structureDic[str(currentCellPref)]["cost"]
					if Global.playerMoney < price:
						continue
					else:
						Global.playerMoney -= price
					Global.UpdateUI()
					
					var gridPos : Vector2 = Vector2(struct.x, struct.z)
					var newStruct = currentCellPref.instantiate()
					
					# For saving
					newStruct.add_to_group("Persist", true)
					newStruct.set_meta("cells", previewStructures[struct]["cells"])
					newStruct.set_meta("edges", previewStructures[struct]["edges"])
					newStruct.set_meta("currentFloor", currentFloor)
					newStruct.set_meta("dicKey", str(currentCellPref))
					
					# To group certain structures
					if newStruct.is_in_group("Shelf"):
						get_node("Shelves").add_child(newStruct)
					elif newStruct.is_in_group("Checkout"):
						get_node("Checkouts").add_child(newStruct)
					else:
						add_child(newStruct)
					
					floorObjects[currentFloor].append(newStruct)
					newStruct.rotation_degrees = previewStructures[struct]["rotation"]
					newStruct.position = struct
					Global.gridSys.DuplicateMaterial(newStruct)
					# The cell that stores the rotation and cells the object takes up, used for deletion
					var storageCell : Vector2 = Global.gridSys.GlobalToGrid(gridPos)
					
					if previewStructures[struct]["interactionCells"]:
						for cell in previewStructures[struct]["interactionCells"]:
							Global.gridSys.floorGridDics[currentFloor][cell]["interactionSpot"] += 1
					if previewStructures[struct]["interactionEdges"]:
						for edge in previewStructures[struct]["interactionEdges"]:
							Global.gridSys.floorEdgeDics[currentFloor][edge]["interactionEdge"] += 1
					for cell in previewStructures[struct]["cells"]:
						Global.gridSys.floorGridDics[currentFloor][cell]["cellData"] = newStruct
						if cell != storageCell:
							Global.gridSys.floorGridDics[currentFloor][storageCell]["cells"].append(cell)
					if previewStructures[struct]["cells"].size() > 1:
						Global.gridSys.floorGridDics[currentFloor][storageCell]["storageEdge"] = Vector2(
							previewStructures[struct]["edges"][0]
							)
						
						var storageEdge : Vector2 = Vector2(
							previewStructures[struct]["edges"][0]
							)
				
						for edge in previewStructures[struct]["edges"]:
							Global.gridSys.floorEdgeDics[currentFloor][edge]["cellData"] = newStruct
							if edge != storageEdge:
								Global.gridSys.floorEdgeDics[currentFloor][storageEdge]["edges"].append(edge)
						for edge in previewStructures[struct]["interactionEdges"]:
							if edge != storageEdge:
								Global.gridSys.floorEdgeDics[currentFloor][storageEdge]["interactionEdges"].append(edge)

		previewStructures.clear()
				
func CreatePreviewStruct(newPos : Vector3, intersections : Array):
	#var tempObj = currentCellPreviewPref.instantiate()
	var tempObj = currentCellPref.instantiate()
	tempObj.position = newPos
	tempObj.rotation_degrees.y = objectRotation
	if tempObj.position in previewStructures:
		previewStructures[tempObj.position]["previewObj"] = tempObj
	else:
		previewStructures[tempObj.position] = {
			"rotation" : tempObj.rotation_degrees,
			"previewObj" : tempObj,
			"cells" : intersections[0],
			"edges" : intersections[1],
			"interactionCanPlace" : true,
			"interactionCells" : null,
			"interactionEdges" : null
		}
		
	tempObj.scale.x = 0.998
	
	Global.gridSys.DuplicateMaterial(tempObj)
	var objMat = Global.gridSys.GetMaterial(tempObj)
	objMat.set_transparency(1)
	objMat.set_cull_mode(0)
	objMat.set_depth_draw_mode(1)
	objMat.albedo_color = Color(1, 1, 1, 0.4)
	
	add_child(tempObj)
	
	var interactionsCheck : Array = HighlightInteractionSpots(
		previewStructures[tempObj.position]["cells"],
		tempObj
	)
	previewStructures[tempObj.position]["interactionCells"] = interactionsCheck[0]
	previewStructures[tempObj.position]["interactionEdges"] = interactionsCheck[1]
	previewStructures[tempObj.position]["interactionCanPlace"] = interactionsCheck[2]
	
func EdgePreview(point : Vector2):
	if Input.is_action_just_pressed("Rotate"):
		ResetPreview()
		return
	if is_instance_valid(previewStruct):
		previewStruct.queue_free()
	if edgePreviewAxis.size() > 0:
		if edgePreviewAxis[0]:
			point.x = edgePreviewAxis[1].x
		else:
			point.y = edgePreviewAxis[1].y
	
	var newObj = currentEdgePref.instantiate()
	add_child(newObj)
	previewStruct = newObj
	newObj.rotation_degrees.y = objectRotation
	newObj.scale.x = 1.006
	var newObjSize : Vector3 = (newObj.get_child(0).global_transform * newObj.get_child(0).get_aabb()).size
	var newObjPoint : Vector3 = Global.gridSys.GlobalToComplexEdge(point, newObjSize, RotationCheck())
	newObjPoint.y = currentHeight
	newObj.position = newObjPoint
	
	var newGridPoint : Vector2 = Vector2(newObjPoint.x, newObjPoint.z)
	var edgeResults : Array = IntersectEdges(newObjSize, newGridPoint, RotationCheck())
	var intersectingEdges : Array = edgeResults[0]
	var canPlace : bool = edgeResults[1]
	
	if Input.is_action_pressed("Place"):
		newObj.visible = false
		if !canPlace:
			return
		for edge in intersectingEdges:
			if Global.gridSys.floorEdgeDics[currentFloor][edge]["cellData"]:
				return
				
		if edgePreviewAxis.size() <= 0:
			if !RotationCheck():
				edgePreviewAxis.append(true)
				edgePreviewAxis.append(newGridPoint)
				edgePreviewAxis.append(roundi(newObjSize.z))
			else:
				edgePreviewAxis.append(false)
				edgePreviewAxis.append(newGridPoint)
				edgePreviewAxis.append(roundi(newObjSize.x))
		
		if previewStructures.size() > 0:
			for struct in previewStructures:
				if is_instance_valid(previewStructures[struct]["previewObj"]):
					previewStructures[struct]["previewObj"].queue_free()
		
		if edgePreviewAxis.size() > 0:
			if edgePreviewAxis[0]:
				var gridDist : int = int(newObjPoint.z - edgePreviewAxis[1].y)
				var negDist : bool = gridDist < 0
				CreatePreviewEdge(
					Vector3(newGridPoint.x, currentHeight, edgePreviewAxis[1].y),
					intersectingEdges
					)
				for x in abs(gridDist):
					if (x + 1) % edgePreviewAxis[2] == 0:
						var newPos : float
						if negDist:
							newPos = edgePreviewAxis[1].y - (x + 1)
						else:
							newPos = edgePreviewAxis[1].y + (x + 1)
						
						var newIntersection : Array = IntersectEdges(
							newObjSize, 
							Vector2(newGridPoint.x, newPos), 
							RotationCheck()
							)
						if !newIntersection[1]:
							continue
						CreatePreviewEdge(
							Vector3(newGridPoint.x, currentHeight, newPos),
							newIntersection[0]
							)
			else:
				var gridDist : int = int(newObjPoint.x - edgePreviewAxis[1].x)
				var negDist : bool = gridDist < 0
				CreatePreviewEdge(
					Vector3(edgePreviewAxis[1].x, currentHeight, newGridPoint.y),
					intersectingEdges
					)
				for x in abs(gridDist):
					if (x + 1) % edgePreviewAxis[2] == 0:
						var newPos : float
						if negDist:
							newPos = edgePreviewAxis[1].x - (x + 1)
						else:
							newPos = edgePreviewAxis[1].x + (x + 1)
						var newIntersection : Array = IntersectEdges(
							newObjSize, 
							Vector2(newPos, newGridPoint.y), 
							RotationCheck()
							)
						if !newIntersection[1]:
							continue
						CreatePreviewEdge(
							Vector3(newPos, currentHeight, newGridPoint.y),
							newIntersection[0]
							)
			
	if Input.is_action_just_released("Place"):
		edgePreviewAxis.clear()
		if previewStructures.size() > 0:
			for struct in previewStructures:
				if is_instance_valid(previewStructures[struct]["previewObj"]):
					previewStructures[struct]["previewObj"].queue_free()
					
					var notInOwnedCells : bool = false
					
					for edge in previewStructures[struct]["edges"]:
						if round(edge.x) - edge.x != 0:
							var cellsToCheck : Array = [Vector2(edge.x + .5, edge.y), Vector2(edge.x - .5, edge.y)]
							if (cellsToCheck[0] not in Global.landSys.ownedCells and 
								cellsToCheck[1] not in Global.landSys.ownedCells):
								notInOwnedCells = true
								
							if (cellsToCheck[0] in Global.gridSys.floorGridDics[currentFloor] and 
								cellsToCheck[1] in Global.gridSys.floorGridDics[currentFloor]):
								if (Global.gridSys.floorGridDics[currentFloor][cellsToCheck[0]]["floorData"] == null and 
									Global.gridSys.floorGridDics[currentFloor][cellsToCheck[1]]["floorData"] == null):
									notInOwnedCells = true
							elif (cellsToCheck[0] in Global.gridSys.floorGridDics[currentFloor] and 
								Global.gridSys.floorGridDics[currentFloor][cellsToCheck[0]]["floorData"] == null):
								notInOwnedCells = true
							elif (cellsToCheck[1] in Global.gridSys.floorGridDics[currentFloor] and 
								Global.gridSys.floorGridDics[currentFloor][cellsToCheck[1]]["floorData"] == null):
								notInOwnedCells = true
								
						elif round(edge.y) - edge.y != 0:
							var cellsToCheck : Array = [Vector2(edge.x, edge.y + .5), Vector2(edge.x, edge.y - .5)]
							if (cellsToCheck[0] not in Global.landSys.ownedCells and 
								cellsToCheck[1] not in Global.landSys.ownedCells):
								notInOwnedCells = true
								
							if (cellsToCheck[0] in Global.gridSys.floorGridDics[currentFloor] and 
								cellsToCheck[1] in Global.gridSys.floorGridDics[currentFloor]):
								if (Global.gridSys.floorGridDics[currentFloor][cellsToCheck[0]]["floorData"] == null and 
									Global.gridSys.floorGridDics[currentFloor][cellsToCheck[1]]["floorData"] == null):
									notInOwnedCells = true
							elif (cellsToCheck[0] in Global.gridSys.floorGridDics[currentFloor] and 
								Global.gridSys.floorGridDics[currentFloor][cellsToCheck[0]]["floorData"] == null):
								notInOwnedCells = true
							elif (cellsToCheck[1] in Global.gridSys.floorGridDics[currentFloor] and 
								Global.gridSys.floorGridDics[currentFloor][cellsToCheck[1]]["floorData"] == null):
								notInOwnedCells = true
					
					if notInOwnedCells:
						continue
					
					var price : int = edgeStructureDic[str(currentEdgePref)]["cost"]
					print(price)
					if Global.playerMoney < price:
						continue
					else:
						Global.playerMoney -= price
					Global.UpdateUI()
					
					var gridPos : Vector2 = Vector2(struct.x, struct.z)
					var newWall = currentEdgePref.instantiate()
					
					#if currentEdgePref == wallPref:
						
					newWall.set_meta("edges", previewStructures[struct]["edges"])
					newWall.set_meta("currentFloor", currentFloor)
					newWall.set_meta("dicKey", str(currentEdgePref))
					
					floorEdges[currentFloor].append(newWall)
					newWall.rotation_degrees = previewStructures[struct]["rotation"]
					newWall.position = struct
					newWall.add_to_group("Edge", true)
					newWall.add_to_group("Persist", true)
					Global.gridSys.DuplicateMaterial(newWall)
					
					var storageEdge : Vector2 
					if !RotationCheck():
						storageEdge = Global.gridSys.GlobalToEdge(gridPos, false)
					else:
						storageEdge = Global.gridSys.GlobalToEdge(gridPos, true)
					
					newWall.scale = ZFightFix(storageEdge, Global.gridSys.floorEdgeDics[currentFloor])
					if currentEdgePref == doubleDoorPref:
						newWall.scale.y = .998
						
					var wallHiderName : String 
					if round(storageEdge.x) - storageEdge.x != 0:
						wallHiderName = "X" + str(storageEdge.x * 100)
					elif round(storageEdge.y) - storageEdge.y != 0:
						wallHiderName = "Y" + str(storageEdge.y * 100)
						
					get_node(str("Walls/" + wallHiderName)).add_child(newWall)
					
					for edge in previewStructures[struct]["edges"]:
						if Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"]:
							objectsToDelete.append(
								Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"].get_child(0)
							)
							DeleteObjects()
							
						Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"] = newWall
						Global.gridSys.floorEdgeDics[currentFloor][edge]["scale"] = newWall.scale
						
						if edge != storageEdge:
							Global.gridSys.floorEdgeDics[currentFloor][storageEdge]["edges"].append(edge)
						
						if currentEdgePref == doubleDoorPref:
							Global.gridSys.floorEdgeDics[currentFloor][edge]["door"] = true
						else:
							Global.gridSys.floorEdgeDics[currentFloor][edge]["door"] = false
								
					var edgesToCheck : Array = []
					
					if round(storageEdge.x) - storageEdge.x != 0:
						for edge in previewStructures[struct]["edges"]:
							edgesToCheck.append(edge + Vector2(0.5, 0.5))
							edgesToCheck.append(edge + Vector2(-0.5, 0.5))
							edgesToCheck.append(edge + Vector2(0.5, -0.5))
							edgesToCheck.append(edge + Vector2(-0.5, -0.5))
							edgesToCheck.append(edge + Vector2(0, 1))
							edgesToCheck.append(edge + Vector2(0, -1))
						
						var insideCount : int = 0
						for edgeToCheck in edgesToCheck:
							if edgeToCheck not in Global.gridSys.floorEdgeDics[currentFloor]:
								continue
							if Global.gridSys.floorEdgeDics[currentFloor][edgeToCheck]["edgeData"] != null:
								insideCount += 1
						if insideCount >= 2:
							InsideCellCheck(storageEdge)
							
					elif round(storageEdge.y) - storageEdge.y != 0:
						for edge in previewStructures[struct]["edges"]:
							edgesToCheck.append(edge + Vector2(0.5, 0.5))
							edgesToCheck.append(edge + Vector2(-0.5, 0.5))
							edgesToCheck.append(edge + Vector2(0.5, -0.5))
							edgesToCheck.append(edge + Vector2(-0.5, -0.5))
							edgesToCheck.append(edge + Vector2(1, 0))
							edgesToCheck.append(edge + Vector2(-1, -0))
						
						var insideCount : int = 0
						for edgeToCheck in edgesToCheck:
							if edgeToCheck not in Global.gridSys.floorEdgeDics[currentFloor]:
								continue
							if Global.gridSys.floorEdgeDics[currentFloor][edgeToCheck]["edgeData"] != null:
								insideCount += 1
						if insideCount >= 2:
							InsideCellCheck(storageEdge)
						

		previewStructures.clear()
		
func CreatePreviewEdge(newPos : Vector3, intersectingEdges : Array):
	var tempObj = currentEdgePref.instantiate()
	tempObj.position = newPos
	tempObj.rotation_degrees.y = objectRotation
	if tempObj.position in previewStructures:
		previewStructures[tempObj.position]["previewObj"] = tempObj
	else:
		previewStructures[tempObj.position] = {
			"rotation" : tempObj.rotation_degrees,
			"previewObj" : tempObj,
			"edges" : intersectingEdges
		}
		
	tempObj.scale.x = 0.998
	
	Global.gridSys.DuplicateMaterial(tempObj)
	var objMat = Global.gridSys.GetMaterial(tempObj)
	objMat.set_transparency(1)
	objMat.set_cull_mode(0)
	objMat.set_depth_draw_mode(1)
	objMat.albedo_color = Color(1, 1, 1, 0.4)
	
	add_child(tempObj)

func FloorPreview(point : Vector2):
	if Input.is_action_just_pressed("Rotate"):
		ResetPreview()
		return
		
	if is_instance_valid(previewStruct):
		previewStruct.queue_free()

	# We spawn in the object and set it's rotation for an accurate size calc
	var newObj = currentFloorPref.instantiate()
	newObj.rotation_degrees.y = objectRotation
	add_child(newObj)
	var newPoint : Vector2 = Global.gridSys.GlobalToGrid(point)
	newObj.position = Vector3(newPoint.x, currentHeight, newPoint.y)
	previewStruct = newObj
	
	if Input.is_action_pressed("Place"):
		newObj.visible = false
			
		ResetHighlightedCells()
		
		if previewStructures.size() > 0:
			for struct in previewStructures:
				if is_instance_valid(previewStructures[struct]["previewObj"]):
					previewStructures[struct]["previewObj"].queue_free()
						
		if floorPreviewAxis.size() <= 0:
			gridPreviewAxis.append(newPoint)
		
		if gridPreviewAxis[0].x > -99:
			var gridDist : Vector2 = Vector2(
				int(newPoint.x - gridPreviewAxis[0].x),
				int(newPoint.y - gridPreviewAxis[0].y)
				)
			if Vector2(gridPreviewAxis[0].x, gridPreviewAxis[0].y) in Global.gridSys.floorGridDics[currentFloor]:
				CreatePreviewFloor(
					Vector3(gridPreviewAxis[0].x, currentHeight, gridPreviewAxis[0].y)
				)
			var negXDist : bool = gridDist.x < 0
			var negYDist : bool = gridDist.y < 0
			var xDist : int = abs(gridDist.x)
			var yDist : int = abs(gridDist.y)
			
			for x in xDist:
				var newXPos : float
				if negXDist:
					newXPos = gridPreviewAxis[0].x - (x + 1)
				else:
					newXPos = gridPreviewAxis[0].x + (x + 1)
				if Vector2(newXPos, gridPreviewAxis[0].y) in Global.gridSys.floorGridDics[currentFloor]:
					CreatePreviewFloor(
						Vector3(newXPos, currentHeight, gridPreviewAxis[0].y)
					)
				
			for y in yDist:
				var newYPos : float
				if negYDist:
					newYPos = gridPreviewAxis[0].y - (y + 1)
				else:
					newYPos = gridPreviewAxis[0].y + (y + 1)
				if Vector2(gridPreviewAxis[0].x, newYPos) in Global.gridSys.floorGridDics[currentFloor]:
					CreatePreviewFloor(
						Vector3(gridPreviewAxis[0].x, currentHeight, newYPos),
					)
					
			for x in xDist:
				var newXPos : float
				if negXDist:
					newXPos = gridPreviewAxis[0].x - (x + 1)
				else:
					newXPos = gridPreviewAxis[0].x + (x + 1)
				for y in yDist:
					var newYPos : float
					if negYDist:
						newYPos = gridPreviewAxis[0].y - (y + 1)
					else:
						newYPos = gridPreviewAxis[0].y + (y + 1)
					if Vector2(newXPos, newYPos) in Global.gridSys.floorGridDics[currentFloor]:
						CreatePreviewFloor(
							Vector3(newXPos, currentHeight, newYPos)
						)
			
	if Input.is_action_just_released("Place"):
		gridPreviewAxis.clear()
		if previewStructures.size() > 0:
			for struct in previewStructures:
				if is_instance_valid(previewStructures[struct]["previewObj"]):
					previewStructures[struct]["previewObj"].queue_free()
					
					if Vector2(struct.x, struct.z) not in Global.landSys.ownedCells:
						continue
						
					var gridPos : Vector2 = Vector2(struct.x, struct.z)
					var newStruct = currentFloorPref.instantiate()
					
					add_child(newStruct)
					newStruct.set_meta("cells", gridPos)
					newStruct.set_meta("currentFloor", currentFloor)
					
					floorFloors[currentFloor].append(newStruct)
					newStruct.rotation_degrees = previewStructures[struct]["rotation"]
					newStruct.position = struct
					newStruct.add_to_group("Floor", true)
					newStruct.add_to_group("Persist", true)
					Global.gridSys.DuplicateMaterial(newStruct)
					
					if Global.gridSys.floorGridDics[currentFloor][gridPos]["floorData"]:
						floorFloors[currentFloor].erase(Global.gridSys.floorGridDics[currentFloor][gridPos]["floorData"])
						Global.gridSys.floorGridDics[currentFloor][gridPos]["floorData"].queue_free()
					Global.gridSys.floorGridDics[currentFloor][gridPos]["floorData"] = newStruct
					
		previewStructures.clear()
		
func CreatePreviewFloor(newPos : Vector3):
	var tempObj = currentFloorPref.instantiate()
	tempObj.position = newPos
	tempObj.rotation_degrees.y = objectRotation
	if tempObj.position in previewStructures:
		previewStructures[tempObj.position]["previewObj"] = tempObj
	else:
		previewStructures[tempObj.position] = {
			"rotation" : tempObj.rotation_degrees,
			"previewObj" : tempObj,
		}
		
	tempObj.scale.y = 1.02
	
	Global.gridSys.DuplicateMaterial(tempObj)
	var objMat = Global.gridSys.GetMaterial(tempObj)
	objMat.set_transparency(1)
	objMat.set_cull_mode(0)
	objMat.set_depth_draw_mode(1)
	objMat.albedo_color = Color(1, 1, 1, 0.4)
	
	add_child(tempObj)
	
func HighlightCells(size : Vector3, position : Vector2):
			
	var sizeX = ceili(size.x)
	var sizeY = ceili(size.z)
	
	var xCells : Array
	var yCells : Array
	var intersectingCells : Array
			
	# The X size is odd
	if ceili(sizeX) % 2 != 0:
		xCells.append(Vector2(position.x, 0))
		for num in floori(float(sizeX) / 2):
			xCells.append(Vector2(position.x + num, 0))
			xCells.append(Vector2(position.x - num, 0))
	else:
		for num in floor(float(sizeX) / 2):
			xCells.append(Vector2(position.x + (num + 0.5), 0))
			xCells.append(Vector2(position.x - (num + 0.5), 0))
	
	if ceili(sizeY) % 2 != 0:
		yCells.append(Vector2(0, position.y))
		for num in floori(float(sizeY) / 2):
			yCells.append(Vector2(0, position.y + num))
			yCells.append(Vector2(0, position.y - num))
	else:
		for num in floor(float(sizeY) / 2):
			yCells.append(Vector2(0, position.y + (num + 0.5)))
			yCells.append(Vector2(0, position.y - (num + 0.5)))
	
	for xCell in xCells:
		for yCell in yCells:
			intersectingCells.append(Vector2(xCell.x, yCell.y))
		
	# Ensure that the x and y cells originate from where the object is, and not the world origin
	for cell in xCells:
		xCells[xCells.find(cell)].y = yCells[yCells.size() - 1].y
		
	for cell in yCells:
		yCells[yCells.find(cell)].x = xCells[xCells.size() - 1].x
	
	xCells.reverse()
	yCells.reverse()
	intersectingCells.reverse()
	
	var intersectingEdges : Array
	var intersectingEdgeDic : Dictionary
	
	var xDifference : float = xCells[0].x - xCells[xCells.size() - 1].x
	var yDifference : float = yCells[0].y - yCells[yCells.size() - 1].y
	
	for xCell in xCells:
		var previousCell 
		for yCell in yCells:
			var currentCell = Vector2(xCell.x, yCell.y)
			if previousCell != null:
				intersectingEdges.append(Vector2(currentCell.x, currentCell.y - .5))
				intersectingEdgeDic[Vector2(currentCell.x, currentCell.y - .5)] = {
					"EdgeCells" : [previousCell, currentCell]
				}
			previousCell = currentCell
			
	for yCell in yCells:
		var previousCell 
		for xCell in xCells:
			var currentCell = Vector2(xCell.x, yCell.y)
			if previousCell != null:
				intersectingEdges.append(Vector2(currentCell.x - .5, currentCell.y))
				intersectingEdgeDic[Vector2(currentCell.x - .5, currentCell.y)] = {
					"EdgeCells" : [previousCell, currentCell]
				}
			previousCell = currentCell
	
	var canPlace : bool = true
	
	for cell in intersectingCells:
		if Global.gridSys.floorGridDics[currentFloor].has(cell):
			var floorData = Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]
			if Global.gridSys.floorGridDics[currentFloor][cell]["floorData"] == null:
				canPlace = false
				continue
			else:
				if (Global.gridSys.floorGridDics[currentFloor][cell]["cellData"] == null
				and Global.gridSys.floorGridDics[currentFloor][cell]["interactionSpot"] <= 0):
					Global.gridSys.GetMaterial(floorData).albedo_color = greenCellCol
				else:
					Global.gridSys.GetMaterial(floorData).albedo_color = redCellCol
					canPlace = false
				if floorData not in highlightedCells:
					highlightedCells.append(floorData)
		else:
			canPlace = false
			
	for edge in intersectingEdges:
		if Global.gridSys.floorEdgeDics[currentFloor].has(edge):
			var gridData = Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"]
			var edgeCells : Array = intersectingEdgeDic[edge]["EdgeCells"]
			if gridData != null:
				for edgeCell in edgeCells:
					if Global.gridSys.floorGridDics[currentFloor].has(edgeCell):
						var floorData = Global.gridSys.floorGridDics[currentFloor][edgeCell]["floorData"]
						if floorData:
							Global.gridSys.GetMaterial(floorData).albedo_color = redCellCol
				canPlace = false
			for cell in edgeCells:
				if Global.gridSys.floorGridDics[currentFloor].has(cell):
					var floorData = Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]
					if !highlightedCells.has(floorData) and floorData != null:
						highlightedCells.append(floorData)
		else:
			canPlace = false
	

	return [intersectingCells, intersectingEdges, canPlace]

func HighlightInteractionSpots(objectCells : Array, object : Node3D):
	var intersectingCells : Array
	 
	var intersectingEdges : Array
	var intersectingEdgeDic : Dictionary
	
	var cellsToEdgeCheck : Array = objectCells.duplicate()
		
	if object.is_in_group("HasInteractionSpots"):
		var interactionSpots : Array
		if object.is_in_group("Shelf"):
			interactionSpots = object.get_node("InteractionSpots").get_children()
		elif object.is_in_group("Checkout"):
			interactionSpots = object.get_node("VanityInteractionSpots").get_children()
		
		for spot in interactionSpots:
			cellsToEdgeCheck.append(round(Vector2(spot.global_position.x, spot.global_position.z)))
		for spot in interactionSpots:
			var childCellPos : Vector2 = round(Vector2(spot.global_position.x, spot.global_position.z))
			if childCellPos not in intersectingCells:
				intersectingCells.append(childCellPos)
			for cell in cellsToEdgeCheck:
				if (childCellPos + cell) / 2 in Global.gridSys.edgeDic:
					if (childCellPos + cell) / 2 not in intersectingEdges:
						intersectingEdges.append((childCellPos + cell) / 2)
						intersectingEdgeDic[(childCellPos + cell) / 2] = {
							"EdgeCells" : [childCellPos, cell]
						}
						
	var canPlace : bool = true
	
	for cell in intersectingCells:
		if Global.gridSys.floorGridDics[currentFloor].has(cell):
			var floorData = Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]
			if Global.gridSys.floorGridDics[currentFloor][cell]["floorData"] == null:
				canPlace = false
				continue
			else:
				if Global.gridSys.floorGridDics[currentFloor][cell]["cellData"] == null:
					Global.gridSys.GetMaterial(floorData).albedo_color = greenCellCol
				else:
					Global.gridSys.GetMaterial(floorData).albedo_color = redCellCol
					canPlace = false
				if floorData not in highlightedCells:
					highlightedCells.append(floorData)
		else:
			canPlace = false
			
	for edge in intersectingEdges:
		if Global.gridSys.floorEdgeDics[currentFloor].has(edge):
			var gridData = Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"]
			var edgeCells : Array = intersectingEdgeDic[edge]["EdgeCells"]
			if gridData != null:
				for edgeCell in edgeCells:
					if Global.gridSys.floorGridDics[currentFloor].has(edgeCell):
						var floorData = Global.gridSys.floorGridDics[currentFloor][edgeCell]["floorData"]
						if floorData:
							Global.gridSys.GetMaterial(floorData).albedo_color = redCellCol
				canPlace = false
			for cell in edgeCells:
				if Global.gridSys.floorGridDics[currentFloor].has(cell):
					var floorData = Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]
					if !highlightedCells.has(floorData) and floorData != null:
						highlightedCells.append(floorData)
		else:
			canPlace = false

	return [intersectingCells, intersectingEdges, canPlace]
	
func IntersectEdges(size : Vector3, position : Vector2, rotated : bool):
	
	# To prevent floating point errors in scale
	size = Vector3(round(size.x), size.y, round(size.z))
	
	var edges : Array
	var canPlace : bool = true
	
	if rotated:
		var sizeX = ceili(size.x)
		if sizeX % 2 != 0:
			edges.append(Vector2(position.x, position.y))
			for num in floori(float(sizeX) / 2):
				edges.append(Vector2(position.x + (num + 1), position.y))
				edges.append(Vector2(position.x - (num + 1), position.y))
		else:
			for num in floor(float(sizeX) / 2):
				edges.append(Vector2(position.x + (num + 0.5), position.y))
				edges.append(Vector2(position.x - (num + 0.5), position.y))
	
	else:
		var sizeY = ceili(size.z)
		if sizeY % 2 != 0:
			edges.append(Vector2(position.x, position.y))
			for num in floori(float(sizeY) / 2):
				edges.append(Vector2(position.x, position.y + (num + 1)))
				edges.append(Vector2(position.x, position.y - (num + 1)))
		else:
			for num in floor(float(sizeY) / 2):
				edges.append(Vector2(position.x, position.y + (num + 0.5)))
				edges.append(Vector2(position.x, position.y - (num + 0.5)))
				
	for edge in edges:
		if Global.gridSys.floorEdgeDics[currentFloor].has(edge):
			if (Global.gridSys.floorEdgeDics[currentFloor][edge]["cellData"] != null
			or Global.gridSys.floorEdgeDics[currentFloor][edge]["interactionEdge"] > 0):
				canPlace = false
		else:
			canPlace = false
			
	return([edges, canPlace])

func MultiSelectGrid(newPos : Vector2):
	newPos = Global.gridSys.GlobalToGrid(newPos)
	
	if ogMultiSelectCell.x <= -99:
		ogMultiSelectCell = Vector2(newPos.x, newPos.y)
	
	var xDiff : int = newPos.x - ogMultiSelectCell.x
	var yDiff : int = newPos.y - ogMultiSelectCell.y
	
	var negX : bool = xDiff < 0
	var negY : bool = yDiff < 0
	
	xDiff = abs(xDiff)
	yDiff = abs(yDiff)
	
	var xCells : Array = [ogMultiSelectCell.x]
	var yCells : Array = [ogMultiSelectCell.y]
	
	for diff in xDiff:
		if negX:
			xCells.append(ogMultiSelectCell.x - (diff + 1))
		else:
			xCells.append(ogMultiSelectCell.x + (diff + 1))
			
	for diff in yDiff:
		if negY:
			yCells.append(ogMultiSelectCell.y - (diff + 1))
		else:
			yCells.append(ogMultiSelectCell.y + (diff + 1))
	
	var intersectingCells : Array 
	
	for xCell in xCells:
		for yCell in yCells:
			if Vector2(xCell, yCell) in Global.gridSys.floorGridDics[currentFloor]:
				intersectingCells.append(Vector2(xCell, yCell))
	
	var intersectingEdges : Array 
	
	for xCell in xCells:
		var previousCell 
		for yCell in yCells:
			var currentCell = Vector2(xCell, yCell)
			if previousCell != null:
				if negX:
					intersectingEdges.append(Vector2(currentCell.x, currentCell.y + .5))
				else:
					intersectingEdges.append(Vector2(currentCell.x, currentCell.y - .5))
			previousCell = currentCell
			
	for yCell in yCells:
		var previousCell 
		for xCell in xCells:
			var currentCell = Vector2(xCell, yCell)
			if previousCell != null:
				if negY:
					intersectingEdges.append(Vector2(currentCell.x + .5, currentCell.y))
				else:
					intersectingEdges.append(Vector2(currentCell.x - .5, currentCell.y))
					
			previousCell = currentCell
	
	return [intersectingCells, intersectingEdges]
	
func MultiSelectEdge(newPos : Vector2):
	newPos = Global.gridSys.GlobalToUniversalEdge(newPos)
	
	if ogMultiSelectEdge.x <= -99:
		ogMultiSelectEdge = Vector2(newPos.x, newPos.y)
	
	var xDiff : float = newPos.x - ogMultiSelectEdge.x
	var yDiff : float = newPos.y - ogMultiSelectEdge.y
	
	var negX : bool = xDiff < 0
	var negY : bool = yDiff < 0
	
	xDiff = abs(xDiff)
	yDiff = abs(yDiff)
	
	var xEdges : Array = [ogMultiSelectEdge.x]
	var yEdges : Array = [ogMultiSelectEdge.y]
	
	for diff in (xDiff * 2):
		diff += 1 
		if negX:
			xEdges.append(ogMultiSelectEdge.x - (diff / 2))
		else:
			xEdges.append(ogMultiSelectEdge.x + (diff / 2))
			
	for diff in (yDiff * 2):
		diff += 1
		if negY:
			yEdges.append(ogMultiSelectEdge.y - (diff / 2))
		else:
			yEdges.append(ogMultiSelectEdge.y + (diff / 2))
	
	var intersectingEdges : Array
	
	for xEdge in xEdges:
		for yEdge in yEdges:
			if Vector2(xEdge, yEdge) in Global.gridSys.floorEdgeDics[currentFloor]:
				intersectingEdges.append(Vector2(xEdge, yEdge))
	
	return intersectingEdges
	
func DeleteObjects():
	for objMesh in objectsToDelete:
		# Ensure edge objects don't accidentally delete cell objects
		if objMesh.get_parent().is_in_group("Floor"):
			var gridPoint : Vector2 = Global.gridSys.GlobalToGrid(Vector2(
				objMesh.get_parent().position.x,
				objMesh.get_parent().position.z
			))
			
			Global.gridSys.floorGridDics[currentFloor][gridPoint]["floorData"] = null
			floorFloors[currentFloor].erase(objMesh.get_parent())
			
		elif objMesh.get_parent().is_in_group("Edge"):
			var priceRefund : int = edgeStructureDic[objMesh.get_parent().get_meta("dicKey")]["cost"] * .8
			Global.playerMoney += priceRefund
			Global.UpdateUI()
			
			var edgePoint : Vector2 
			edgePoint = Global.gridSys.GlobalToEdge(Vector2(
				objMesh.get_parent().position.x, 
				objMesh.get_parent().position.z), 
			ObjectRotationCheck(objMesh.get_parent()))
			
			for edgeToDel in Global.gridSys.floorEdgeDics[currentFloor][edgePoint]["edges"]:
				ResetDicEntry(edgeToDel)
				InsideCellCheck(edgeToDel, true)
			ResetDicEntry(edgePoint)
			InsideCellCheck(edgePoint, true)
			floorEdges[currentFloor].erase(objMesh.get_parent())
			
		else:
			var priceRefund : int = structureDic[objMesh.get_parent().get_meta("dicKey")]["cost"] * .8
			Global.playerMoney += priceRefund
			Global.UpdateUI()
			if objMesh.get_parent().is_in_group("HasInteractionSpots"):
				if objMesh.get_parent().is_in_group("Shelf"):
					for spot in objMesh.get_parent().get_node("InteractionSpots").get_children():
						var roundSpot = round(Vector2(spot.global_position.x, spot.global_position.z))
						ResetDicEntry(round(Vector2(spot.global_position.x, spot.global_position.z)))
				elif objMesh.get_parent().is_in_group("Checkout"):
					for spot in objMesh.get_parent().get_node("VanityInteractionSpots").get_children():
						var roundSpot = round(Vector2(spot.global_position.x, spot.global_position.z))
						ResetDicEntry(round(Vector2(spot.global_position.x, spot.global_position.z)))
			
			var gridPoint : Vector2 = Global.gridSys.GlobalToGrid(Vector2(
				objMesh.get_parent().position.x,
				objMesh.get_parent().position.z
			 ))
			for cellToDel in Global.gridSys.floorGridDics[currentFloor][gridPoint]["cells"]:
				ResetDicEntry(cellToDel)
			if Global.gridSys.floorGridDics[currentFloor][gridPoint]["storageEdge"] != null:
				var edgePoint : Vector2 = Global.gridSys.floorGridDics[currentFloor][gridPoint]["storageEdge"]
				for edgeToDel in Global.gridSys.floorEdgeDics[currentFloor][edgePoint]["edges"]:
					ResetDicEntry(edgeToDel)
				for edgeToDel in Global.gridSys.floorEdgeDics[currentFloor][edgePoint]["interactionEdges"]:
					ResetDicEntry(edgeToDel)
				ResetDicEntry(edgePoint)
			ResetDicEntry(gridPoint)
			floorObjects[currentFloor].erase(objMesh.get_parent())
			
		objMesh.get_parent().queue_free()
		
	ResetDeletionObjects()
	
func ResetDicEntry(dicKey : Vector2):
	var edge : bool = false
	if (abs(dicKey.x - int(dicKey.x)) > 0
	 or abs(dicKey.y - int(dicKey.y)) > 0):
		edge = true
		
	if edge:
		Global.gridSys.floorEdgeDics[currentFloor][dicKey]["cellData"] = null
		Global.gridSys.floorEdgeDics[currentFloor][dicKey]["edgeData"] = null
		Global.gridSys.floorEdgeDics[currentFloor][dicKey]["scale"] = Vector3(1, 1, 1)
		Global.gridSys.floorEdgeDics[currentFloor][dicKey]["edges"].clear()
		Global.gridSys.floorEdgeDics[currentFloor][dicKey]["interactionEdges"].clear()
		Global.gridSys.floorEdgeDics[currentFloor][dicKey]["interactionEdge"] -= 1
		if Global.gridSys.floorEdgeDics[currentFloor][dicKey]["interactionEdge"] < 0:
			Global.gridSys.floorEdgeDics[currentFloor][dicKey]["interactionEdge"] = 0
		Global.gridSys.floorEdgeDics[currentFloor][dicKey]["door"] = false
		
	else:
		Global.gridSys.floorGridDics[currentFloor][dicKey]["cellData"] = null
		Global.gridSys.floorGridDics[currentFloor][dicKey]["cells"].clear()
		Global.gridSys.floorGridDics[currentFloor][dicKey]["storageEdge"] = null
		Global.gridSys.floorGridDics[currentFloor][dicKey]["interactionSpot"] -= 1
		if Global.gridSys.floorGridDics[currentFloor][dicKey]["interactionSpot"] < 0:
			Global.gridSys.floorGridDics[currentFloor][dicKey]["interactionSpot"] = 0
			
# A function to prevent Z fighting
func ZFightFix(victim : Vector2, dic : Dictionary):
	var newScale : Vector3 = Vector3(1, 1, 1)
	
	# Reduce the z scale for to prevent edge fighting on corners
	newScale.z = .998

	var neighbourNeg : Vector2
	var neighbourPos : Vector2
	
	# An edge on the X axis
	if abs(victim.x - int(victim.x)) > 0:
		neighbourNeg = Vector2(victim.x, victim.y - 1)
		neighbourPos = Vector2(victim.x, victim.y + 1)
	else:
		neighbourNeg = Vector2(victim.x - 1, victim.y)
		neighbourPos = Vector2(victim.x + 1, victim.y)
		
	var neighbourNegXScale : float
	var neighbourPosXScale : float
	
	if dic.has(neighbourNeg) and dic[neighbourNeg]["edgeData"]:
		neighbourNegXScale = dic[neighbourNeg]["scale"].x
		neighbourNegXScale *= 1000
		neighbourNegXScale = round(neighbourNegXScale)
		neighbourNegXScale /= 1000
	if dic.has(neighbourPos) and dic[neighbourPos]["edgeData"]:
		neighbourPosXScale = dic[neighbourPos]["scale"].x
		neighbourPosXScale *= 1000
		neighbourPosXScale = round(neighbourPosXScale)
		neighbourPosXScale /= 1000
	
	var scales : Array = [1.002, 1, 0.998]
	
	for scale in scales:
		if neighbourNegXScale == scale or neighbourPosXScale == scale:
			continue
		newScale.x = scale
		break
	return newScale

# A function that handles hiding floors when in build/delete mode
func HideFloors():
	for floor in Global.gridSys.maxFloor:
		floor += 1
		if floor <= currentFloor:
			for obj in floorObjects[floor]:
				obj.visible = true
				obj.get_child(0).get_child(0).get_child(0).disabled = false
			for edge in floorEdges[floor]:
				edge.visible = true
				edge.get_child(0).get_child(0).get_child(0).disabled = false
			for floorObj in floorFloors[floor]:
				floorObj.visible = true
				floorObj.get_child(0).get_child(0).get_child(0).disabled = false
		else:
			for obj in floorObjects[floor]:
				obj.visible = false
				obj.get_child(0).get_child(0).get_child(0).disabled = true
			for edge in floorEdges[floor]:
				edge.visible = false
				edge.get_child(0).get_child(0).get_child(0).disabled = true
			for floorObj in floorFloors[floor]:
				floorObj.visible = false
				floorObj.get_child(0).get_child(0).get_child(0).disabled = true

func InsideCellCheck(edge, deleting : bool = false):
	var neighbours : Array = [
		Vector2(0, 1),
		Vector2(0, -1),
		Vector2(1, 0),
		Vector2(-1, 0)
	]
	
	var startingCells : Array 
	
	if round(edge.x) - edge.x != 0:
		startingCells.append(Vector2(edge.x + .5, edge.y))
		startingCells.append(Vector2(edge.x - .5, edge.y))
	elif round(edge.y) - edge.y != 0:
		startingCells.append(Vector2(edge.x, edge.y + .5))
		startingCells.append(Vector2(edge.x, edge.y - .5))
	
	
	for startCell in startingCells:
		if startCell not in Global.landSys.ownedCells:
			continue
		if deleting and !Global.gridSys.floorGridDics[currentFloor][startCell]["inside"]:
			continue
		if !deleting and Global.gridSys.floorGridDics[currentFloor][startCell]["inside"]:
			continue
			
		var checkedCells : Array 
		var cellsToCheck : Array
		
		checkedCells.append(startCell)
		for neighbour in neighbours:
			var newCell = startCell + neighbour
			if (Global.gridSys.floorEdgeDics[currentFloor][(newCell + startCell) / 2]["edgeData"] != null):
				continue
			cellsToCheck.append(newCell)
			
		var outsidePlot : bool = false
		var insidePlot : bool = false

		
		while true:
			var tempCellsToCheck : Array
			print(cellsToCheck)
			if cellsToCheck.size() == 0:
				insidePlot = true
				break
			for cell in cellsToCheck:
				if cell in checkedCells:
					continue
				if cell not in Global.landSys.ownedCells:
					if deleting:
						continue
					elif !deleting:
						outsidePlot = true
						break
				checkedCells.append(cell)
				#Global.gridSys.GetMaterial(Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]).albedo_color = redCellCol
				for neighbour in neighbours:
					var newCell = cell + neighbour
					if Global.gridSys.floorEdgeDics[currentFloor][(newCell + cell) / 2]["edgeData"] != null:
						continue
					if newCell not in checkedCells:
						tempCellsToCheck.append(newCell)
				
			if outsidePlot:
				break
				
			cellsToCheck.clear()
			cellsToCheck = tempCellsToCheck.duplicate()
		
		if deleting: # We only need to set inside cells to outside if deleting
			for cell in checkedCells:
				Global.gridSys.floorGridDics[currentFloor][cell]["inside"] = false
		
		if !deleting :# We only need to set outside cells to inside if building
			if insidePlot:
				for cell in checkedCells:
					Global.gridSys.floorGridDics[currentFloor][cell]["inside"] = true
				
#func Undo():
	#for dicEntry in undoList[undoList.size() - 1]:
		#var newObj : Node3D
		#
		#if dicEntry["Building"]:
			#var packedObj : PackedScene = PackedScene.new()
			#SetPackedSceneOwnership(dicEntry["Object"], dicEntry["Object"])
			#packedObj.pack(dicEntry["Object"])
			#newObj = packedObj.instantiate()
			#for group in dicEntry["Groups"]:
				#newObj.add_to_group(group, true)
			#if newObj.is_in_group("Shelf"):
				#get_node("Shelves").add_child(newObj)
			#elif newObj.is_in_group("Checkout"):
				#get_node("Checkouts").add_child(newObj)
			#else:
				#add_child(newObj)
				#
		#if "Cells" in dicEntry:
			#for cell in dicEntry["Cells"]:
				#
				## To make sure that it doesn't set freed objects as floorData or cellData
				#var skipFloorData : bool = false
				#var skipCellData : bool = false
					#
				#if !dicEntry["Building"]:
					#if "Edges" not in dicEntry: 
						#var floorData = Global.gridSys.floorGridDics[currentFloor][cell]["floorData"]
						#if is_instance_valid(floorData):
							#floorFloors[currentFloor].erase(floorData)
							#highlightedCells.erase(floorData)
							#floorData.queue_free()
						#skipCellData = true
					#else:
						#var cellData = Global.gridSys.floorGridDics[currentFloor][cell]["cellData"]
						#if is_instance_valid(cellData):
							#floorObjects[currentFloor].erase(cellData)
							#cellData.queue_free()
						#skipFloorData = true
						#
				#elif dicEntry["Building"]:
					#if "Edges" not in dicEntry: 
						#skipCellData = true
					#else:
						#skipFloorData = true
						#
				#for entry in dicEntry["Cells"][cell]:
					#if (skipFloorData and entry == "floorData") or (skipCellData and entry == "cellData"):
						#continue
					#Global.gridSys.floorGridDics[currentFloor][cell][entry] = dicEntry["Cells"][cell][entry]
					#
				#if dicEntry["Building"]:
					#if "Edges" not in dicEntry: 
						#Global.gridSys.floorGridDics[currentFloor][cell]["floorData"] = newObj
						#floorFloors[currentFloor].append(newObj)
					#else:
						#Global.gridSys.floorGridDics[currentFloor][cell]["cellData"] = newObj
						#floorObjects[currentFloor].append(newObj)
							#
					#
		#if "Edges" in dicEntry:
			#for edge in dicEntry["Edges"]:
				#if !dicEntry["Building"]:
					#if "Cells" not in dicEntry:
						#var edgeData = Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"]
						#if is_instance_valid(edgeData):
							#floorEdges[currentFloor].erase(edgeData)
							#edgeData.queue_free()
						## For replaced walls
						#if !is_instance_valid(dicEntry["Edges"][edge]["edgeData"]):
							#dicEntry["Edges"][edge]["edgeData"] = null
							#dicEntry["Edges"][edge]["scale"] = Vector3(1, 1, 1)
							#
					#elif "Cells" in dicEntry:
						#var cellData = Global.gridSys.floorEdgeDics[currentFloor][edge]["cellData"]
						#if is_instance_valid(cellData):
							#floorEdges[currentFloor].erase(cellData)
							#cellData.queue_free()
							#
				#Global.gridSys.floorEdgeDics[currentFloor][edge] = dicEntry["Edges"][edge]
				#
				#if dicEntry["Building"]:
					#if "Cells" not in dicEntry:
						#Global.gridSys.floorEdgeDics[currentFloor][edge]["edgeData"] = newObj
					#else:
						#Global.gridSys.floorEdgeDics[currentFloor][edge]["cellData"] = newObj
					#floorEdges[currentFloor].append(newObj)
					#
		#
	#print(floorEdges)
	#undoList.remove_at(undoList.size() - 1)
			#
#func StoreFloorState():
	#var undoDicEntry : Dictionary = {}
	#undoDicEntry["currentFloor"] = currentFloor
	#undoDicEntry["gridDicState"] = Global.gridSys.floorGridDics[currentFloor]
	#undoDicEntry["edgeDicState"] = Global.gridSys.floorEdgeDics[currentFloor]
	#undoDicEntry["objects"] = floorObjects[currentFloor]
	#undoDicEntry["edges"] = floorEdges[currentFloor]
	#undoDicEntry["floors"] = floorFloors[currentFloor]
	#undoDicEntry = undoDicEntry.duplicate(true)
	#undoList.append(undoDicEntry)

#func Undo():
	#for obj in undoList[undoIndex]["objects"]:
		#var newObj : PackedScene = PackedScene.new()
		#SetPackedSceneOwnership(obj, obj)
		#newObj.pack(obj)
		#var addedObj = newObj.instantiate()
		#if addedObj.is_in_group("Shelf"):
			#get_node("Shelves").add_child(addedObj)
		#elif addedObj.is_in_group("Checkout"):
			#get_node("Checkouts").add_child(addedObj)
		#else:
			#add_child(addedObj)
	#for obj in undoList[undoIndex]["edges"]:
		#var newObj : PackedScene = PackedScene.new()
		#SetPackedSceneOwnership(obj, obj)
		#newObj.pack(obj)
		#add_child(newObj.instantiate())
	#for obj in undoList[undoIndex]["floors"]:
		#var newObj : PackedScene = PackedScene.new()
		#SetPackedSceneOwnership(obj, obj)
		#newObj.pack(obj)
		#add_child(newObj.instantiate())
		#
		

	
