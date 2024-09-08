extends Node

#region References
@onready var cam : Camera3D = get_node("../CamMover/Camera3D")
@onready var gridSys : Node3D = get_node("../GridSystem")

#endregion

#region Raycasting
var rayOrigin = Vector3()
var rayEnd = Vector3()
var rayCol

#endregion

#region General Building
# 0 Means deleting, 1 means cell building, 2 means edge building, 3 means floor building
var buildMode : int = 0

# For keeping track of rotation
var objectRotation : int = 0

var currentCellPref : PackedScene
var currentCellPreviewPref : PackedScene
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

#endregion

#region Shelves
var basicShelfPreview : PackedScene = preload("res://Models/Building/Shelving/BasicShelf/BasicShelf.gltf")
var singleFridgePref : PackedScene = preload("res://Models/Building/Shelving/SingleFridge/SingleFridge.gltf")
var displayTablePref : PackedScene = preload("res://Models/Building/Shelving/DisplayTable/DisplayTable.gltf")
var longShelfPref : PackedScene = preload("res://Models/Building/Shelving/LongShelf/shelves.gltf")


var basicShelfPref : PackedScene = preload("res://Shelves/BasicShelf.tscn")
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

func _ready() -> void:
	Global.switchSignal.connect(ResetEverything)
	
	currentCellPref = basicShelfPref
	currentCellPreviewPref = basicShelfPreview
	currentEdgePref = wallPref
	currentFloorPref = floorPref
	
	for dic in gridSys.floorGridDics:
		var newObjectArray : Array = []
		floorObjects.append(newObjectArray)
		var newEdgeArray : Array = []
		floorEdges.append(newEdgeArray)
		var newFloorArray : Array = []
		floorFloors.append(newFloorArray)
		
	for floor in gridSys.floorGridDics[0]:
		floorFloors[0].append(gridSys.floorGridDics[0][floor]["floorData"])
	
func _process(delta):
	currentHeight = currentFloor * gridSys.wallHeight
	if Global.buildMode:
		MouseRaycast()
		InputManager()
	
func InputManager():
	if Input.is_action_just_pressed("Rotate"):
		objectRotation += 90
		objectRotation = wrapf(objectRotation, 0, 360)
		print(objectRotation)
	if Input.is_action_just_pressed("Swap"):
		buildMode += 1
		buildMode = wrapi(buildMode, 0, 4)
		ResetHighlightedCells()
		ResetPreview()
		ResetDeletionObj()
		ResetDeletionObjects()
		ResetDeletionCells()
	if Input.is_action_just_pressed("DeleteMode"):
		ResetDeletionObjects()
		ResetHighlightedCells()
		ResetDeletionObj()
		ResetDeletionCells()
		ResetPreview()
		buildMode = 0
	if buildMode == 0 and Input.is_action_just_released("Place"):
		ResetDeletionCells()
		ResetDeletionObj()
		if objectsToDelete.size() > 0:
			DeleteObjects()
	if Input.is_action_just_pressed("Floor Up"):
		ResetDeletionObjects()
		ResetHighlightedCells()
		ResetDeletionObj()
		ResetDeletionCells()
		ResetPreview()
		currentFloor += 1
		currentFloor = clampi(currentFloor, 0, gridSys.maxFloor)
		gridSys.gridBody.position.y += gridSys.wallHeight
		gridSys.gridBody.position.y = clampi(
			gridSys.gridBody.position.y,
			0,
			gridSys.maxFloor * gridSys.wallHeight
		)
		HideFloors()
	if Input.is_action_just_pressed("Floor Down"):
		ResetDeletionObjects()
		ResetHighlightedCells()
		ResetDeletionObj()
		ResetDeletionCells()
		ResetPreview()
		currentFloor -= 1
		currentFloor = clampi(currentFloor, 0, gridSys.maxFloor)
		gridSys.gridBody.position.y -= gridSys.wallHeight
		gridSys.gridBody.position.y = clampi(
			gridSys.gridBody.position.y,
			0,
			gridSys.maxFloor * gridSys.wallHeight
		)
		HideFloors()

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
			var gridPoint : Vector2 = gridSys.GlobalToGrid(colPoint)
			#if gridSys.floorGridDics[currentFloor].has(gridPoint):
				# We sub in the actual colPoint for complex meshes
			CellPreview(colPoint)
			if (Input.is_action_just_pressed("ui_accept")
			and gridPoint in gridSys.floorGridDics[currentFloor]):
				print(gridSys.floorGridDics[currentFloor][gridPoint])
		elif buildMode == 2:
			# We establish an edgePoint for dictionary access
			var edgePoint : Vector2 = gridSys.GlobalToEdge(colPoint, RotationCheck())
			#if gridSys.floorEdgeDics[currentFloor].has(edgePoint):
			if intersection["collider"].get_parent().get_parent().is_in_group("Floor"):
				if intersection["collider"].get_parent().get_parent() in floorFloors[currentFloor]:
					EdgePreview(colPoint)
			else:
				EdgePreview(colPoint)
			if (Input.is_action_just_pressed("ui_accept")
			and edgePoint in gridSys.floorEdgeDics[currentFloor]):
				print(gridSys.floorEdgeDics[currentFloor][edgePoint])
		elif buildMode == 3:
			var gridPoint : Vector2 = gridSys.GlobalToGrid(colPoint)
			#if gridSys.floorGridDics[currentFloor].has(gridPoint):
			if round(intersection["position"].y) == currentHeight:
				FloorPreview(colPoint)
			if (Input.is_action_just_pressed("ui_accept")
			and gridPoint in gridSys.floorGridDics[currentFloor]):
				print(gridSys.floorGridDics[currentFloor][gridPoint])
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
			if gridSys.floorGridDics[currentFloor][cell]["floorData"]:
				gridSys.GetMaterial(
					gridSys.floorGridDics[currentFloor][cell]["floorData"]
					).albedo_color = resetCol
	
	previousSelectedCells = intersectingCells
	
	for obj in objectsToDelete:
		obj.get_active_material(0).albedo_color = resetCol
	objectsToDelete.clear()
	
	for cell in intersectingCells:
		#gridSys.GetMaterial(
			#gridSys.floorGridDics[currentFloor][cell]["floorData"]
			#).albedo_color = redCellCol
		if gridSys.floorGridDics[currentFloor][cell]["cellData"]:
			gridSys.GetMaterial(
				gridSys.floorGridDics[currentFloor][cell]["cellData"]
				).albedo_color = redCellCol
			if gridSys.floorGridDics[currentFloor][cell]["cellData"].get_child(0) not in objectsToDelete:
				objectsToDelete.append(gridSys.floorGridDics[currentFloor][cell]["cellData"].get_child(0))

func EdgeDelete(colPoint : Vector2, rotated : bool):
	var intersectingEdges = MultiSelectEdge(colPoint)

	for obj in objectsToDelete:
		obj.get_active_material(0).albedo_color = resetCol
	objectsToDelete.clear()
	
	for edge in intersectingEdges:
		if gridSys.floorEdgeDics[currentFloor][edge]["edgeData"] != null:
			gridSys.GetMaterial(
				gridSys.floorEdgeDics[currentFloor][edge]["edgeData"]
			).albedo_color = redCellCol
			if gridSys.floorEdgeDics[currentFloor][edge]["edgeData"] not in objectsToDelete:
				objectsToDelete.append(gridSys.floorEdgeDics[currentFloor][edge]["edgeData"].get_child(0))
				
func FloorDelete(colPoint : Vector2):
	var selectionResults : Array = MultiSelectGrid(colPoint)
	var intersectingCells : Array = selectionResults[0]
	
	if previousSelectedCells.size() > 0:
		for cell in previousSelectedCells:
			if gridSys.floorGridDics[currentFloor][cell]["floorData"]:
				gridSys.GetMaterial(
					gridSys.floorGridDics[currentFloor][cell]["floorData"]
					).albedo_color = resetCol
	
	previousSelectedCells = intersectingCells
	
	for obj in objectsToDelete:
		obj.get_active_material(0).albedo_color = resetCol
	objectsToDelete.clear()
	
	for cell in intersectingCells:
		if gridSys.floorGridDics[currentFloor][cell]["floorData"]:
			gridSys.GetMaterial(
				gridSys.floorGridDics[currentFloor][cell]["floorData"]
				).albedo_color = redCellCol
			if gridSys.floorGridDics[currentFloor][cell]["floorData"].get_child(0) not in objectsToDelete:
				objectsToDelete.append(gridSys.floorGridDics[currentFloor][cell]["floorData"].get_child(0))

func ResetDeletionCells():
	if previousSelectedCells.size() > 0:
		for cell in previousSelectedCells:
			if gridSys.floorGridDics[currentFloor][cell]["floorData"]:
				gridSys.GetMaterial(
					gridSys.floorGridDics[currentFloor][cell]["floorData"]
					).albedo_color = resetCol
				
		previousSelectedCells.clear()
		
	deleteMode = -1
	ogMultiSelectCell = Vector2(-99, -99)
	ogMultiSelectEdge = Vector2(-99, -99)
		
func ResetDeletionObj():
	if objToDelPreview:
		gridSys.GetMaterial(objToDelPreview).albedo_color = resetCol
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
			gridSys.GetMaterial(cell).albedo_color = resetCol
		highlightedCells.clear()
		
func CellPreview(point : Vector2):
	if Input.is_action_just_pressed("Rotate"):
		ResetPreview()
		return
		
	if is_instance_valid(previewStruct):
		previewStruct.queue_free()

	ResetHighlightedCells()
	
	# We spawn in the object and set it's rotation for an accurate size calc
	var newObj = currentCellPreviewPref.instantiate()
	newObj.rotation_degrees.y = objectRotation
	add_child(newObj)
	var newObjSize : Vector3 = (
		newObj.get_child(0).global_transform * 
		newObj.get_child(0).get_aabb()
		).size
	var newPoint : Vector3 = gridSys.GlobalToComplex(point, newObjSize)
	newObj.position = Vector3(newPoint.x, currentHeight, newPoint.z)
	previewStruct = newObj
	
	var objIntersection : Array
	objIntersection = HighlightCells(
		newObjSize, 
		Vector2(newPoint.x, newPoint.z)
		)
	
	var newGridPoint : Vector2 = Vector2(newPoint.x, newPoint.z)
	var objectCells : Array = objIntersection[0]
	var objectEdges : Array = objIntersection[1]
	
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
				
					var gridPos : Vector2 = Vector2(struct.x, struct.z)
					
					var newStruct = currentCellPref.instantiate()
					add_child(newStruct)
					floorObjects[currentFloor].append(newStruct)
					newStruct.rotation_degrees = previewStructures[struct]["rotation"]
					newStruct.position = struct
					gridSys.DuplicateMaterial(newStruct)
					# The cell that stores the rotation and cells the object takes up, used for deletion
					var storageCell : Vector2 = gridSys.GlobalToGrid(gridPos)
					
					for cell in previewStructures[struct]["cells"]:
						gridSys.floorGridDics[currentFloor][cell]["cellData"] = newStruct
						if cell != storageCell:
							gridSys.floorGridDics[currentFloor][storageCell]["cells"].append(cell)
					if previewStructures[struct]["cells"].size() > 1:
						gridSys.floorGridDics[currentFloor][storageCell]["storageEdge"] = Vector2(
							previewStructures[struct]["edges"][0]
							)
						
						var storageEdge : Vector2 = Vector2(
							previewStructures[struct]["edges"][0]
							)
				
						for edge in previewStructures[struct]["edges"]:
							gridSys.floorEdgeDics[currentFloor][edge]["cellData"] = newStruct
							if edge != storageEdge:
								gridSys.floorEdgeDics[currentFloor][storageEdge]["edges"].append(edge)
							
		previewStructures.clear()
		#var tempObj = currentCellPref.instantiate()
		#tempObj.position = newPoint
		#tempObj.rotation_degrees.y = objectRotation
		#gridSys.DuplicateMaterial(tempObj)
		#add_child(tempObj)
		#
		
				
func CreatePreviewStruct(newPos : Vector3, intersections : Array):
	var tempObj = currentCellPreviewPref.instantiate()
	tempObj.position = newPos
	tempObj.rotation_degrees.y = objectRotation
	if tempObj.position in previewStructures:
		previewStructures[tempObj.position]["previewObj"] = tempObj
	else:
		previewStructures[tempObj.position] = {
			"rotation" : tempObj.rotation_degrees,
			"previewObj" : tempObj,
			"cells" : intersections[0],
			"edges" : intersections[1]
		}
		
	tempObj.scale.x = 0.998
	
	gridSys.DuplicateMaterial(tempObj)
	var objMat = gridSys.GetMaterial(tempObj)
	objMat.set_transparency(1)
	objMat.set_cull_mode(0)
	objMat.set_depth_draw_mode(1)
	objMat.albedo_color = Color(1, 1, 1, 0.4)
	
	add_child(tempObj)
	
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
	var newObjPoint : Vector3 = gridSys.GlobalToComplexEdge(point, newObjSize, RotationCheck())
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
			if gridSys.floorEdgeDics[currentFloor][edge]["cellData"]:
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
				
					var gridPos : Vector2 = Vector2(struct.x, struct.z)
					
					var newWall = currentEdgePref.instantiate()
					add_child(newWall)
					floorEdges[currentFloor].append(newWall)
					newWall.rotation_degrees = previewStructures[struct]["rotation"]
					newWall.scale = ZFightFix(gridPos, gridSys.floorEdgeDics[currentFloor])
					newWall.position = struct
					newWall.add_to_group("Edge")
					gridSys.DuplicateMaterial(newWall)
					
					var storageEdge : Vector2 
					if !RotationCheck():
						storageEdge = gridSys.GlobalToEdge(gridPos, false)
					else:
						storageEdge = gridSys.GlobalToEdge(gridPos, true)
						
					for edge in previewStructures[struct]["edges"]:
						if gridSys.floorEdgeDics[currentFloor][edge]["edgeData"]:
							objectsToDelete.append(
								gridSys.floorEdgeDics[currentFloor][edge]["edgeData"].get_child(0)
								)
							DeleteObjects()
							
						gridSys.floorEdgeDics[currentFloor][edge]["edgeData"] = newWall
						gridSys.floorEdgeDics[currentFloor][edge]["scale"] = newWall.scale
						
						if edge != storageEdge:
							gridSys.floorEdgeDics[currentFloor][storageEdge]["edges"].append(edge)
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
	
	gridSys.DuplicateMaterial(tempObj)
	var objMat = gridSys.GetMaterial(tempObj)
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
	var newPoint : Vector2 = gridSys.GlobalToGrid(point)
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
			if Vector2(gridPreviewAxis[0].x, gridPreviewAxis[0].y) in gridSys.floorGridDics[currentFloor]:
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
				if Vector2(newXPos, gridPreviewAxis[0].y) in gridSys.floorGridDics[currentFloor]:
					CreatePreviewFloor(
						Vector3(newXPos, currentHeight, gridPreviewAxis[0].y)
					)
				
			for y in yDist:
				var newYPos : float
				if negYDist:
					newYPos = gridPreviewAxis[0].y - (y + 1)
				else:
					newYPos = gridPreviewAxis[0].y + (y + 1)
				if Vector2(gridPreviewAxis[0].x, newYPos) in gridSys.floorGridDics[currentFloor]:
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
					if Vector2(newXPos, newYPos) in gridSys.floorGridDics[currentFloor]:
						CreatePreviewFloor(
							Vector3(newXPos, currentHeight, newYPos)
						)
			
	if Input.is_action_just_released("Place"):
		gridPreviewAxis.clear()
		if previewStructures.size() > 0:
			for struct in previewStructures:
				if is_instance_valid(previewStructures[struct]["previewObj"]):
					previewStructures[struct]["previewObj"].queue_free()
				
					var gridPos : Vector2 = Vector2(struct.x, struct.z)
					
					var newStruct = currentFloorPref.instantiate()
					add_child(newStruct)
					floorFloors[currentFloor].append(newStruct)
					newStruct.rotation_degrees = previewStructures[struct]["rotation"]
					newStruct.position = struct
					newStruct.add_to_group("Floor")
					gridSys.DuplicateMaterial(newStruct)
					
					if gridSys.floorGridDics[currentFloor][gridPos]["floorData"]:
						floorFloors[currentFloor].erase(gridSys.floorGridDics[currentFloor][gridPos]["floorData"])
						gridSys.floorGridDics[currentFloor][gridPos]["floorData"].queue_free()
					gridSys.floorGridDics[currentFloor][gridPos]["floorData"] = newStruct
								
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
	
	gridSys.DuplicateMaterial(tempObj)
	var objMat = gridSys.GetMaterial(tempObj)
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
		if gridSys.floorGridDics[currentFloor].has(cell):
			var floorData = gridSys.floorGridDics[currentFloor][cell]["floorData"]
			if gridSys.floorGridDics[currentFloor][cell]["floorData"] == null:
				canPlace = false
				continue
			else:
				if gridSys.floorGridDics[currentFloor][cell]["cellData"] == null:
					gridSys.GetMaterial(floorData).albedo_color = greenCellCol
				else:
					gridSys.GetMaterial(floorData).albedo_color = redCellCol
					canPlace = false
				highlightedCells.append(floorData)
		else:
			canPlace = false
			
	for edge in intersectingEdges:
		if gridSys.floorEdgeDics[currentFloor].has(edge):
			var gridData = gridSys.floorEdgeDics[currentFloor][edge]["edgeData"]
			var edgeCells : Array = intersectingEdgeDic[edge]["EdgeCells"]
			if gridData != null:
				for edgeCell in edgeCells:
					if gridSys.floorGridDics[currentFloor].has(edgeCell):
						var floorData = gridSys.floorGridDics[currentFloor][edgeCell]["floorData"]
						if floorData:
							gridSys.GetMaterial(floorData).albedo_color = redCellCol
				canPlace = false
			for cell in edgeCells:
				if gridSys.floorGridDics[currentFloor].has(cell):
					var floorData = gridSys.floorGridDics[currentFloor][cell]["floorData"]
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
		if gridSys.floorEdgeDics[currentFloor].has(edge):
			if gridSys.floorEdgeDics[currentFloor][edge]["cellData"] != null:
				canPlace = false
		else:
			canPlace = false
			
	return([edges, canPlace])

func MultiSelectGrid(newPos : Vector2):
	newPos = gridSys.GlobalToGrid(newPos)
	
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
			if Vector2(xCell, yCell) in gridSys.floorGridDics[currentFloor]:
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
	newPos = gridSys.GlobalToUniversalEdge(newPos)
	
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
			if Vector2(xEdge, yEdge) in gridSys.floorEdgeDics[currentFloor]:
				intersectingEdges.append(Vector2(xEdge, yEdge))
	
	return intersectingEdges
	
func DeleteObjects():
	for objMesh in objectsToDelete:
		# Ensure edge objects don't accidentally delete cell objects
		if objMesh.get_parent().is_in_group("Floor"):
			var gridPoint : Vector2 = gridSys.GlobalToGrid(Vector2(
				objMesh.get_parent().position.x,
				objMesh.get_parent().position.z
			 ))	
			gridSys.floorGridDics[currentFloor][gridPoint]["floorData"] = null
			floorFloors[currentFloor].erase(objMesh.get_parent())
		elif objMesh.get_parent().is_in_group("Edge"):
			var edgePoint : Vector2 
			edgePoint = gridSys.GlobalToEdge(Vector2(
				objMesh.get_parent().position.x, 
				objMesh.get_parent().position.z), 
			ObjectRotationCheck(objMesh.get_parent()))

			for edgeToDel in gridSys.floorEdgeDics[currentFloor][edgePoint]["edges"]:
				ResetDicEntry(edgeToDel)
			ResetDicEntry(edgePoint)
			floorEdges[currentFloor].erase(objMesh.get_parent())
		else:
			var gridPoint : Vector2 = gridSys.GlobalToGrid(Vector2(
				objMesh.get_parent().position.x,
				objMesh.get_parent().position.z
			 ))
			for cellToDel in gridSys.floorGridDics[currentFloor][gridPoint]["cells"]:
				ResetDicEntry(cellToDel)
			
			if gridSys.floorGridDics[currentFloor][gridPoint]["storageEdge"] != null:
				var edgePoint : Vector2 = gridSys.floorGridDics[currentFloor][gridPoint]["storageEdge"]
				for edgeToDel in gridSys.floorEdgeDics[currentFloor][edgePoint]["edges"]:
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
		gridSys.floorEdgeDics[currentFloor][dicKey]["cellData"] = null
		gridSys.floorEdgeDics[currentFloor][dicKey]["edgeData"] = null
		gridSys.floorEdgeDics[currentFloor][dicKey]["scale"] = Vector3(1, 1, 1)
		gridSys.floorEdgeDics[currentFloor][dicKey]["edges"].clear()
	else:
		gridSys.floorGridDics[currentFloor][dicKey]["cellData"] = null
		gridSys.floorGridDics[currentFloor][dicKey]["cells"].clear()
		gridSys.floorGridDics[currentFloor][dicKey]["storageEdge"] = null
		
		
# A function to prevent Z fighting
func ZFightFix(victim : Vector2, dic : Dictionary):
	var newScale : Vector3 = Vector3(1, 1, 1)
	
	# Reduce the z scale for to prevent edge fighting on corners
	newScale.z = .999

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
	
	var scales : Array = [1.001, 1, 0.999]
	
	for scale in scales:
		if neighbourNegXScale == scale or neighbourPosXScale == scale:
			continue
		newScale.x = scale
		break
	return newScale

# A function that handles hiding floors when in build/delete mode
func HideFloors():
	for floor in gridSys.maxFloor:
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
