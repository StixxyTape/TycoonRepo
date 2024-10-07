extends Node3D

@onready var gridBody : StaticBody3D = $StaticBody3D

var gridSize : Vector2 = Vector2(15, 15)

# A dictionary for storing all the grid data
var gridDic : Dictionary

# A seperate grid for wall objects
var edgeDic : Dictionary

# A vector 2 array for getting neighbouring edges of tiles
var edges : PackedVector2Array = ([
		Vector2(0.5, 0),
		Vector2(-0.5, 0),
		Vector2(0, 0.5),
		Vector2(0, -0.5)
		])

var wallHeight : int = 2
var maxFloor : int = 0

var floorGridDics : Array = []
var floorEdgeDics : Array = []

#region DEBUG
@onready var floorPref : PackedScene = preload("res://Models/Building/Structure/FloorTile/FloorTile.gltf")

#endregion

func _ready():
	EstablishGrid()

func EstablishGrid():
	# We set the size slightly smaller to prevent conflicts
	gridBody.get_child(0).get_shape().size = Vector3(gridSize.x * 4, .04, gridSize.y * 4)
	gridBody.position = Vector3((gridSize.x / 2) - 0.5, 0, (gridSize.y / 2) - 0.5)
	
	for x in gridSize.x:
		for y in gridSize.y:
			gridDic[Vector2(x, y)] = {
				"floorData" : null,
				"cellData" : null,
				"cells" : [],
				"storageEdge" : null,
				"interactionSpot" : 0
			}
			
			# Visualise Grid
			var newFloor = floorPref.instantiate()
			newFloor.get_child(0).get_child(0).set_collision_layer_value(1, false)
			newFloor.get_child(0).get_child(0).set_collision_layer_value(2, true)
			DuplicateMaterial(newFloor)
			newFloor.position = Vector3(x, 0, y)
			newFloor.add_to_group("Floor")
			gridDic[Vector2(x, y)]["floorData"] = newFloor
			newFloor.scale = Vector3(1, 1, 1)
			get_node("../BuildSystem").add_child(newFloor)
			
	floorGridDics.append(gridDic)
	
	for cell in gridDic:
		for edge in edges:
			var edgeX : float = edge.x + cell.x
			var edgeY : float = edge.y + cell.y
			if !edgeDic.has(Vector2(edgeX, edgeY)):
				edgeDic[Vector2(edgeX, edgeY)] = {
					"scale" : Vector3(1, 1, 1),
					"edgeData" : null,
					"cellData" : null,
					"edges" : [],
					"interactionEdges" : [],
					"interactionEdge" : 0
				}
	floorEdgeDics.append(edgeDic)
	
	for floor in maxFloor:
		## Skip the first one as we already have the base floor established
		#if x == 0:
			#continue
			
		floor += 1
		
		var newGridDic : Dictionary
		
		for x in gridSize.x:
			for y in gridSize.y:
				newGridDic[Vector2(x, y)] = {
					"floorData" : null,
					"cellData" : null,
					"cells" : [],
					"storageEdge" : null,
					"interactionSpot" : 0
				}
			
		floorGridDics.append(newGridDic)
		
		var newEdgeDic : Dictionary
		
		for cell in gridDic:
			for edge in edges:
				var edgeX : float = edge.x + cell.x
				var edgeY : float = edge.y + cell.y
				if !newEdgeDic.has(Vector2(edgeX, edgeY)):
					newEdgeDic[Vector2(edgeX, edgeY)] = {
						"scale" : Vector3(1, 1, 1),
						"edgeData" : null,
						"cellData" : null,
						"edges" : [],
						"interactionEdges" : [],
						"interactionEdge" : 0
					}
	
		floorEdgeDics.append(newEdgeDic)
		
func GlobalToGrid(pos : Vector2):
	return round(pos)
	
func GlobalToEdge(pos : Vector2, rotated : bool):
	var cellPos = round(pos)
	
	var closestEdge : Vector2
	
	for edge in edges:
		var edgePos : Vector2
		if rotated:
			if edge.x != 0:
				continue
			edgePos = Vector2(edge.x + cellPos.x, edge.y + cellPos.y)
		else:
			if edge.y != 0:
				continue
			edgePos = Vector2(edge.x + cellPos.x, edge.y + cellPos.y)
		if !closestEdge:
			closestEdge = edgePos
		else:
			if pos.distance_to(edgePos) < pos.distance_to(closestEdge):
				closestEdge = edgePos
				
	return closestEdge
	
# Doesn't care about rotation
func GlobalToUniversalEdge(pos : Vector2):
	var cellPos = round(pos)
	
	var closestEdge : Vector2
	
	for edge in edges:
		var edgePos : Vector2
		edgePos = Vector2(edge.x + cellPos.x, edge.y + cellPos.y)
		if !closestEdge:
			closestEdge = edgePos
		else:
			if pos.distance_to(edgePos) < pos.distance_to(closestEdge):
				closestEdge = edgePos
				
	return closestEdge

func GlobalToComplex(pos : Vector2, size : Vector3):
	var xPoint
	var yPoint
	var cellPoint = GlobalToGrid(pos)
	
	var evenX : bool = ceili(size.x) % 2 == 0
	var evenY : bool = ceili(size.z) % 2 == 0
	
	var edgePoint : Vector2 = Vector2(GlobalToEdge(pos, !evenX).x, GlobalToEdge(pos, evenY).y)
	
	if ceili(size.x) % 2 == 0:
		xPoint = edgePoint.x
	else:
		xPoint = cellPoint.x
	
	if ceili(size.z) % 2 == 0:
		yPoint = edgePoint.y
	else:
		yPoint = cellPoint.y
	
	return Vector3(xPoint, 0, yPoint)

func GlobalToComplexEdge(pos : Vector2, size : Vector3, rotated : bool):
	#print(size.z)
	# To prevent floating point errors in scale
	size = Vector3(round(size.x), size.y, round(size.z))
	#print(size)
	var xPoint = pos.x
	var yPoint = pos.y
	var edgePoint : float
	
	if !rotated:
		xPoint = GlobalToEdge(pos, false).x
		var evenX : bool = ceili(size.z) % 2 == 0
		edgePoint = GlobalToEdge(pos, evenX).y
		if roundi(size.z) % 2 == 0:
			yPoint = edgePoint
		else:
			yPoint = round(yPoint)
	else:
		yPoint = GlobalToEdge(pos, true).y
		var evenY : bool = ceili(size.x) % 2 == 0
		edgePoint = GlobalToEdge(pos, !evenY).x
		if roundi(size.x) % 2 == 0:
			xPoint = edgePoint
		else:
			xPoint = round(xPoint)
	
	return Vector3(xPoint, 0, yPoint)
	
func GetMaterial(object : Node3D):
	return object.get_child(0).get_active_material(0)
	
func DuplicateMaterial(object : Node3D):
	object.get_child(0).set_surface_override_material(
		0, 
		GetMaterial(object).duplicate()
		) 
	
