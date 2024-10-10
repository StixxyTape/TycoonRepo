extends Node

#region References
@onready var stockSys : Node3D = get_tree().current_scene.get_node("StockSystem")
@onready var uiSys : Control = get_tree().current_scene.get_node("UISystem")
@onready var gridSys : Node3D = get_tree().current_scene.get_node("GridSystem")
@onready var buildSys : Node3D = get_tree().current_scene.get_node("BuildSystem")
@onready var customerSys : Node3D = get_tree().current_scene.get_node("CustomerSystem")

@onready var camController : Node3D = get_tree().current_scene.get_node("CamMover")

#endregion

#region Systems 
var buildMode : bool = true
var stockMode : bool = false

var customersSpawning : bool = false

#endregion

#region Camera
var camCanMove : bool = true

#endregion

var stocking : bool = false

# If the mouse is hovering over UI elements
var mouseHover : bool = false

#region Signals
# Called to reset things when switching between systems
signal switchSignal 

signal spawnCustomerSignal

#endregion
	
func _process(delta: float) -> void:
	GlobalInputManager()
	
func GlobalInputManager():
	if Input.is_action_just_pressed("SwitchMode"):
		buildMode = !buildMode
		stockMode = !stockMode
		switchSignal.emit()
	if Input.is_action_just_pressed("CustomerSpawn"):
		spawnCustomerSignal.emit()
		
func SetHoverMode(mode):
	mouseHover = mode
	
func UpdateUI():
	uiSys.StockUpdate()


	
