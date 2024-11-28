extends Node3D

var gridChunk : PackedScene = preload("res://VFX/BuildGrid/GridChunk.tscn")

func _ready() -> void:
	Global.switchSystemSignal.connect(GridUpdate)
	Global.switchPhaseSignal.connect(GridUpdate)
	
func GridUpdate():
	if !Global.preparationPhase:
		HideBuildGrid()
		return
		
	if Global.currentMode == 1:
		pass
		ShowBuildGrid()
	else:
		pass
		HideBuildGrid()
	
func UpdateBuildGrid(newPos : Vector2):
	var newGridChunk : Sprite3D = gridChunk.instantiate()
	newGridChunk.position = Vector3(newPos.x, .01, newPos.y)
	newGridChunk.visible = false
	$GridChunks.add_child(newGridChunk)
	
func ShowBuildGrid():
	for child in $GridChunks.get_children():
		child.visible = true

func HideBuildGrid():
	for child in $GridChunks.get_children():
		child.visible = false
