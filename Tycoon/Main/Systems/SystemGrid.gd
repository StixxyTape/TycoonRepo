extends Node3D

@onready var gridBody : StaticBody3D = $StaticBody3D

# Set to multiples of six for land plots
var gridSize : Vector2 = Vector2(24, 24)

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

#region Cells
@onready var floorPref : PackedScene = preload("res://Models/Building/Structure/FloorTile/FloorTile.gltf")
@onready var grassText : CompressedTexture2D = preload("res://Models/Building/Structure/FloorTile/Textures/Grass.png")
@onready var grassEffect : PackedScene = preload("res://VFX/Grass/GrassEffect.tscn")
@onready var wallHider : PackedScene = preload("res://VFX/WallHide/WallHider.tscn")

#endregion

#region Signals
signal finishedAssigningLands

#endregion

func _ready():
	finishedAssigningLands.connect(Global.landSys.EstablishPlots)
	EstablishGrid()

func EstablishGrid():
	# We set the size slightly smaller to prevent conflicts
	gridBody.get_child(0).get_shape().size = Vector3(gridSize.x * 4, .04, gridSize.y * 4)
	gridBody.position = Vector3((gridSize.x / 2) - 0.5, -.05, (gridSize.y / 2) - 0.5)
	
	for x in gridSize.x + 1:
		x -= .5
		var wallHiderName : String = "X" + str(x * 100)
		var newWallHider : Node3D = wallHider.instantiate()
		newWallHider.name = wallHiderName
		print(newWallHider.name)
		Global.buildSys.get_node("Walls").add_child(newWallHider)
	
	for y in gridSize.y + 1:
		y -= .5
		var wallHiderName : String = "Y" + str(y * 100)
		var newWallHider : Node3D = wallHider.instantiate()
		newWallHider.name = wallHiderName
		print(newWallHider.name)
		Global.buildSys.get_node("Walls").add_child(newWallHider)
			
	for x in gridSize.x:
		for y in gridSize.y:
			gridDic[Vector2(x, y)] = {
				"floorData" : null,
				"cellData" : null,
				"cells" : [],
				"storageEdge" : null,
				"interactionSpot" : 0,
				"inside" : false
			}
			
			if (((int(x) - 3) % 6 == 0 or (x-3) == 0) and
				((int(y) -3) % 6 == 0 or (y-3) == 0)):
				Global.landSys.availableLandPlots.append(Vector2(x -1, y - 1))
				
	finishedAssigningLands.emit()
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
					"interactionEdge" : 0,
					"door" : false
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
					"interactionSpot" : 0,
					"inside" : false
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
						"interactionEdge" : 0,
						"door" : false
					}
	
		floorEdgeDics.append(newEdgeDic)

func EstablishGrass(cells):
	for cell in cells:
		if Vector2(cell.x, cell.y) in Global.landSys.ownedCells:
			# Visualise Grid
			var newFloor = floorPref.instantiate()
			newFloor.get_child(0).get_child(0).set_collision_layer_value(1, false)
			newFloor.get_child(0).get_child(0).set_collision_layer_value(2, true)
			DuplicateMaterial(newFloor)
			newFloor.position = Vector3(cell.x, -.01, cell.y)
			newFloor.add_to_group("Floor", true)
			newFloor.add_to_group("Persist", true)
			newFloor.set_meta("currentFloor", 0)
			newFloor.set_meta("cells", Vector2(cell.x, cell.y))
			gridDic[Vector2(cell.x, cell.y)]["floorData"] = newFloor
			newFloor.scale = Vector3(1, 1, 1)
			get_node("../BuildSystem").add_child(newFloor)

			GetMaterial(newFloor).albedo_texture = grassText
		
			var newGrass = grassEffect.instantiate()
			newFloor.add_child(newGrass)
				
	for floor in floorGridDics[0]:
		Global.buildSys.floorFloors[0].append(floorGridDics[0][floor]["floorData"])
	
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
	
