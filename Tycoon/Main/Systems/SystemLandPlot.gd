extends Node3D

var landPlotPref : PackedScene = preload("res://LandPlots/LandPlot.tscn")

var availableLandPlots : PackedVector2Array = []

var ownedCells : PackedVector2Array = []
var ownedPlots : PackedVector2Array = []

var startingPlots : Array = []
var startingPlotPositions : PackedVector2Array = [
	Vector2(2.5, 8.5),
	Vector2(2.5, 14.5),
	Vector2(8.5, 8.5),
	Vector2(8.5, 14.5)
]

#var sideWalkTiles : PackedVector2Array = [
	#Vector2(0, 6), Vector2(0, 7), Vector2(0, 8),
	#Vector2(0, 15), Vector2(0, 16), Vector2(0, 17),
	#Vector2(1, 6), Vector2(1, 17), Vector2(2, 6), Vector2(2, 17),
	#Vector2(3, 6), Vector2(3, 17), Vector2(4, 6), Vector2(4, 17),
	#Vector2(5, 6), Vector2(5, 7), Vector2(5, 8), Vector2(5, 9),
	#Vector2(5, 10), Vector2(5, 11), Vector2(5, 12), Vector2(5, 13),
	#Vector2(5, 14), Vector2(5, 15), Vector2(5, 16), Vector2(5, 17)
#]
#
#var asphaltTiles : PackedVector2Array = [
	#Vector2(0, 9), Vector2(0, 10), Vector2(0, 11), Vector2(0, 12), 
	#Vector2(0, 13), Vector2(0, 14),
	#Vector2(1, 7), Vector2(1, 8), Vector2(1, 9), Vector2(1, 10),
	#Vector2(1, 11), Vector2(1, 12), Vector2(1, 13), Vector2(1, 14),
	#Vector2(1, 15), Vector2(1, 16), Vector2(1, 17),
	#Vector2(2, 7), Vector2(2, 8), Vector2(2, 9), Vector2(2, 10),
	#Vector2(2, 11), Vector2(2, 12), Vector2(2, 13), Vector2(2, 14),
	#Vector2(2, 15), Vector2(2, 16), Vector2(2, 17), 
	#Vector2(3, 7), Vector2(3, 8), Vector2(3, 9), Vector2(3, 10),
	#Vector2(3, 11), Vector2(3, 12), Vector2(3, 13), Vector2(3, 14),
	#Vector2(3, 15), Vector2(3, 16), Vector2(3, 17), 
	#Vector2(4, 7), Vector2(4, 8), Vector2(4, 9), Vector2(4, 10),
	#Vector2(4, 11), Vector2(4, 12), Vector2(4, 13), Vector2(4, 14),
	#Vector2(4, 15), Vector2(4, 16), Vector2(4, 17), 
#]

var cam : Camera3D

var resetCol : Color = Color(1, 1, 1, 1)
var highlightedPlotCol : Color = Color(.5, .5, 1, 1)
var selectedPlotCol : Color = Color(.5, 1, .5, 1)

var selectedPlotPreview : Node3D
var selectedPlot : Node3D

signal plotBuySignal 

func _ready() -> void:
	Global.switchSystemSignal.connect(SwitchToLandMode)
	cam = Global.camController.get_node("Camera3D")
	
func _process(delta: float) -> void:
	if Global.currentMode == 1 and Global.buildSys.buildMode == 4: 
		MouseRaycast(delta)

func MouseRaycast(delta : float):
	#region Raycast Setup
	var rayOrigin = Vector3()
	var rayEnd = Vector3()
	var rayCol

	var spaceState = cam.get_world_3d().direct_space_state
	var mousePos = get_viewport().get_mouse_position()
	rayOrigin = cam.project_ray_origin(mousePos)
	rayEnd = rayOrigin + cam.project_ray_normal(mousePos) * 100
	
	var query : PhysicsRayQueryParameters3D
	
	# Set the collision value to 6 so it only affects floors
	# And the gridCollider (incase of being on a new floor)
	query = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd, 16);
		
	var intersection = spaceState.intersect_ray(query)
	
	#endregion 
	
	if !intersection.is_empty():
		if Global.mouseHover:
			ResetHighlightedPlot()
			return
			
		if selectedPlot:
			return
			
		var objCollider : StaticBody3D
		
		objCollider = intersection["collider"]
		objCollider.get_node("../GridChunk").modulate = highlightedPlotCol
		
		for edge in objCollider.get_node("../Edges").get_children():
			edge.get_surface_override_material(0).set_shader_parameter("newColor", highlightedPlotCol)
		
		objCollider.get_node("../Edges").visible = true
		
		# An edge case if the mouse jumps from one object to another
		if objCollider.get_parent() != selectedPlotPreview:
			ResetHighlightedPlot()
			selectedPlotPreview = objCollider.get_parent()
		
		if Input.is_action_just_pressed("Place"):
			selectedPlotPreview = null
			selectedPlot = objCollider.get_parent()
			objCollider.get_node("../GridChunk").modulate = selectedPlotCol
			for edge in objCollider.get_node("../Edges").get_children():
				edge.get_surface_override_material(0).set_shader_parameter("newColor", selectedPlotCol)
			plotBuySignal.emit(objCollider.get_parent())
	else:
		ResetHighlightedPlot()
			
func ResetHighlightedPlot():
	if selectedPlotPreview and is_instance_valid(selectedPlotPreview):
		selectedPlotPreview.get_node("GridChunk").modulate = resetCol
		selectedPlotPreview.get_node("Edges").visible = false
		selectedPlotPreview = null

func ResetSelectedPlot():
	if selectedPlot and is_instance_valid(selectedPlot):
		selectedPlot.get_node("GridChunk").modulate = resetCol
		selectedPlot.get_node("Edges").visible = false
		selectedPlot = null
		
func SwitchToLandMode():
	if Global.currentMode == 1:
		var neighbours = [Vector2(0, 6), Vector2(0, -6), Vector2(6,0), Vector2(-6, 0)]
		for child in get_children():
			for neighbour in neighbours:
				if Vector2(child.position.x, child.position.z) + neighbour in ownedPlots:
					child.visible = true
					child.get_node("StaticBody3D/CollisionShape3D").disabled = false
	else:
		for child in get_children():
			child.visible = false
			child.get_node("StaticBody3D/CollisionShape3D").disabled = true
		ResetHighlightedPlot()
		ResetSelectedPlot()

# connected via signal in gridsys
func EstablishPlots():
	for plot in availableLandPlots:
		var newPlot = landPlotPref.instantiate()
		newPlot.global_position = Vector3(plot.x + .5, .01, plot.y + .5)
		add_child(newPlot)
		
		newPlot.visible = false
		newPlot.get_node("StaticBody3D/CollisionShape3D").disabled = true
		
		if Vector2(plot.x + .5, plot.y + .5) in startingPlotPositions:
			startingPlots.append(newPlot)
	
	await get_child(get_children().size() - 1).extentsCalculated
	
	for plot in startingPlots:
		BuyPlot(plot, true)
	
	
func BuyPlot(plot, startingPlot : bool = false):
	if !startingPlot:
		if Global.playerMoney < Global.landPrice:
			ResetHighlightedPlot()
			ResetSelectedPlot()
			return
		Global.playerMoney -= Global.landPrice
		Global.landPrice += 750
		Global.uiSys.MoneyUpdate()
	
	var grassCells : Array = []
	for x in (plot.cellExtents[1].x - plot.cellExtents[0].x) + 1:
		for y in (plot.cellExtents[1].y - plot.cellExtents[0].y) + 1:
			ownedCells.append(Vector2(plot.cellExtents[0].x + x, plot.cellExtents[0].y + y))
			grassCells.append(Vector2(plot.cellExtents[0].x + x, plot.cellExtents[0].y + y))
	ownedPlots.append(Vector2(plot.position.x, plot.position.z))
	Global.gridSys.EstablishGrass(grassCells)
	
	Global.floatingGridSys.UpdateBuildGrid(Vector2(plot.position.x, plot.position.z))
	Global.floatingGridSys.GridUpdate()
	
	plot.queue_free()
	
	ResetHighlightedPlot()
	ResetSelectedPlot()
	SwitchToLandMode()
	
