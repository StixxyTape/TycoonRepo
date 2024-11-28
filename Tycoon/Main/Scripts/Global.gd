extends Node

#region References
@onready var stockSys : Node3D = get_tree().current_scene.get_node("StockSystem")
@onready var uiSys : Control = get_tree().current_scene.get_node("UISystem")
@onready var gridSys : Node3D = get_tree().current_scene.get_node("GridSystem")
@onready var buildSys : Node3D = get_tree().current_scene.get_node("BuildSystem")
@onready var customerSys : Node3D = get_tree().current_scene.get_node("CustomerSystem")
@onready var landSys : Node3D = get_tree().current_scene.get_node("LandPlotSystem")
@onready var floatingGridSys : Node3D = get_tree().current_scene.get_node("FloatingGridSystem")

@onready var camController : Node3D = get_tree().current_scene.get_node("CamMover")

#endregion

#region Systems 
# 0: Default, 1: Build Mode, 2: Stock Mode, 3: Land Mode
var currentMode : int = 0

#var buildMode : bool = false
#var stockMode : bool = true
#var landMode : bool = false

#endregion

#region Camera
var camCanMove : bool = true

#endregion

#region GeneralStates
var stocking : bool = false

# If the mouse is hovering over UI elements
var mouseHover : bool = false

#endregion

#region Signals
# Called to reset things when switching between systems
signal switchSystemSignal
signal switchPhaseSignal

signal actionTimeSignal

#endregion

#region PlayerStats
var playerMoney : int = 1000
var landPrice : int =  750

#endregion

#region Phases
# If false, action phase is active
var preparationPhase : bool = true

# A custom time for controlling variables during the action phase
var actionPhaseTimeScale : float = 1

#endregion

var loading : bool = false

func _process(delta: float) -> void:
	GlobalInputManager()
	
func GlobalInputManager():
	if Input.is_action_just_pressed("SwitchMode") and preparationPhase:
		currentMode += 1
		currentMode = wrapi(currentMode, 0, 3)
		print(currentMode)
		camCanMove = true
		switchSystemSignal.emit()
		
func SetHoverMode(mode):
	mouseHover = mode
	
func UpdateUI():
	uiSys.StockUpdate()
	uiSys.MoneyUpdate()
	
func ChangePhase(toActionPhase : bool = true):
	if toActionPhase:
		preparationPhase = false
		currentMode = 0
		uiSys.ResetUI()
		customerSys.BeginCustomerSpawn(randi_range(1, 10), 2, .5)
		uiSys.EstablishTimeControls()
	else:
		preparationPhase = true
		ChangeActionTime()
		uiSys.ResetUI()
		uiSys.MenuUpdate()
		
	switchPhaseSignal.emit()

func ChangeActionTime(timeScale : float = 1):
	actionPhaseTimeScale = timeScale
	actionTimeSignal.emit()
