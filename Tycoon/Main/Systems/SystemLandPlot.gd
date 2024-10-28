extends Node3D

var landPlotPref : PackedScene = preload("res://LandPlots/LandPlot.tscn")

var availableLandPlots : PackedVector2Array = []

var ownedCells : PackedVector2Array = []

var startingPlots : Array = []
var startingPlotPositions : PackedVector2Array = [
	Vector2(2.5, 8.5),
	Vector2(2.5, 14.5)
]

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
	if Global.currentMode == 3: 
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
	if Global.currentMode == 3:
		for child in get_children():
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
		newPlot.global_position = Vector3(plot.x + .5, 0, plot.y + .5)
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
			
	for x in (plot.cellExtents[1].x - plot.cellExtents[0].x) + 1:
		for y in (plot.cellExtents[1].y - plot.cellExtents[0].y) + 1:
			ownedCells.append(Vector2(plot.cellExtents[0].x + x, plot.cellExtents[0].y + y))
	
	Global.floatingGridSys.UpdateBuildGrid(Vector2(plot.position.x, plot.position.z))
	
	plot.queue_free()
	
	ResetHighlightedPlot()
	ResetSelectedPlot()
	
