extends Node

#region References
var uiSys : Control
var camController : Node3D

#endregion

#region Systems 
var buildMode : bool = true

var stockMode : bool = false
# A bool to check if the player has zoomed in on a stockable (diff from stockMode)
var stocking : bool = false

#endregion

#region Camera
var camCanMove : bool = true

#endregion

# If the mouse is hovering over UI elements
var mouseHover : bool = false

# A signal called to reset things when switching between systems
signal switchSignal 

func _ready() -> void:
	uiSys = get_tree().current_scene.get_node("UISystem")
	camController = get_tree().current_scene.get_node("CamMover")
	
func _process(delta: float) -> void:
	GlobalInputManager()
	
func GlobalInputManager():
	if Input.is_action_just_pressed("SwitchMode"):
		buildMode = !buildMode
		stockMode = !stockMode
		switchSignal.emit()

func SetHoverMode(mode):
	mouseHover = mode
	
func UpdateUI():
	uiSys.StockUpdate()
