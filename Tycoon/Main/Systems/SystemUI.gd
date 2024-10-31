extends Control

var resetGroup : String = "UIReset"

func _ready() -> void:
	Global.switchSystemSignal.connect(MenuUpdate)
	Global.landSys.plotBuySignal.connect(OpenPlotBuyMenu)
	ResetUI()
	MenuUpdate()
	EstablishUI()
	
func ResetUI():
	for child in get_tree().get_nodes_in_group("UIReset"):
		child.queue_free()
		
	$StockShop.currentStockType = 000
	$StockShop.currentQuantity = 0
	$StockShop.basket.clear()
	
func MenuUpdate():
	ResetUI()
	
	if Global.currentMode == 1:
		OpenBuildMenu()
	elif Global.currentMode == 2:
		$StockShop.CreateStockShopButton()
		
	EstablishPhaseButton()
	EstablishSaveLoad()
	
func MoneyUpdate():
	$MoneyLabel.text = str("$", Global.playerMoney)
	
func StockUpdate():
	for stockType in Global.stockSys.stockInventory:
		if stockType == 000:
			continue
		var stockLabel = Global.stockSys.stockInventory[stockType]["countLabel"]
		var amount = Global.stockSys.stockInventory[stockType]["amount"]
		stockLabel.text = str(amount)

func ShelfUpdate(shelf : Node3D):
	var stockName : String = Global.stockSys.stockInventory[shelf.stockType]["name"]
	$Shelf/HBoxContainer/Label.text = "Current Shelf: " + shelf.name
	$Shelf/HBoxContainer2/Label.text = "Stock Type: " + stockName
	$Shelf/HBoxContainer4/Label.text = "Max Amount: " + str(
		shelf.GetShelfState().maxStock)
	$Shelf/HBoxContainer3/Label.text = "Stock Amount: " + str(
		shelf.GetShelfState().currentStock)
		

func EstablishUI():
	EstablishStock()
	MoneyUpdate()
	
func EstablishStock():
	for stockType in Global.stockSys.stockInventory:
		if stockType == 000:
			continue
		var newHBox = HBoxContainer.new()
		#newHBox.add_to_group(resetGroup)
		$Stock.add_child(newHBox)
		var nameLabel = Label.new()
		var countLabel = Label.new()
		nameLabel.text = Global.stockSys.stockInventory[stockType]["name"] + ": "
		countLabel.text = str(Global.stockSys.stockInventory[stockType]["amount"])
		newHBox.add_child(nameLabel)
		newHBox.add_child(countLabel)
		
		Global.stockSys.stockInventory[stockType]["countLabel"] = countLabel
	
func EstablishSaveLoad():
	var saveButton = Button.new()
	saveButton.text = "Save"
	saveButton.focus_mode = Control.FOCUS_NONE
	$SaveMenu.add_child(saveButton)
	
	saveButton.add_to_group(resetGroup)
	saveButton.pressed.connect(SaveLoad.SaveGame)
	ConnectMouseHover(saveButton)
	
	var loadButton = Button.new()
	loadButton.text = "Load"
	loadButton.focus_mode = Control.FOCUS_NONE
	$SaveMenu.add_child(loadButton)
	
	loadButton.add_to_group(resetGroup)
	loadButton.pressed.connect(SaveLoad.LoadGame)
	ConnectMouseHover(loadButton)

func EstablishPhaseButton():
	var phaseButton : Button = Button.new()
	phaseButton.text = "Move To Action Phase"
	phaseButton.add_to_group(resetGroup)
	
	phaseButton.set_anchors_and_offsets_preset(PRESET_BOTTOM_RIGHT)
	phaseButton.position.x += -50
	phaseButton.position.y += -75
	
	phaseButton.focus_mode = Control.FOCUS_NONE
	phaseButton.pressed.connect(Global.ChangePhase.bind(true))
	
	ConnectMouseHover(phaseButton)
	add_child(phaseButton)

func EstablishTimeControls():
	var timeControlBox : HBoxContainer = HBoxContainer.new()
	timeControlBox.add_to_group(resetGroup)
	
	add_child(timeControlBox)
	
	var speedOptions : Array = [1, 2, 4]
	
	for speed in speedOptions:
		var newTimeButton : Button = Button.new()
		
		newTimeButton.text = str(speed, "x speed")
		newTimeButton.focus_mode = Control.FOCUS_NONE
		newTimeButton.pressed.connect(Global.ChangeActionTime.bind(speed))

		ConnectMouseHover(newTimeButton)
		timeControlBox.add_child(newTimeButton)
		
	# We set the preset after adding children to account for it not being misaligned
	timeControlBox.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	timeControlBox.position.y = 50
	
func OpenBuildMenu():
	ResetUI()
	
	var objButton = Button.new()
	objButton.add_to_group(resetGroup)
	objButton.text = "Build Objects"
	objButton.focus_mode = Control.FOCUS_NONE
	$BuildMenus/BuildMenu.add_child(objButton)
	
	objButton.pressed.connect(Global.buildSys.SwapBuildMode.bind(
		1
	))
	objButton.pressed.connect(OpenBuildMenu)
	objButton.pressed.connect(OpenBuildShopMenu.bind(1))
	ConnectMouseHover(objButton)
	
	var edgeButton = Button.new()
	edgeButton.add_to_group(resetGroup)
	edgeButton.text = "Build Edges"
	edgeButton.focus_mode = Control.FOCUS_NONE
	$BuildMenus/BuildMenu.add_child(edgeButton)
	
	edgeButton.pressed.connect(Global.buildSys.SwapBuildMode.bind(
		2
	))
	edgeButton.pressed.connect(OpenBuildMenu)
	ConnectMouseHover(edgeButton)
	
	var floorButton = Button.new()
	floorButton.add_to_group(resetGroup)
	floorButton.text = "Build Floors"
	floorButton.focus_mode = Control.FOCUS_NONE
	$BuildMenus/BuildMenu.add_child(floorButton)
	
	floorButton.pressed.connect(Global.buildSys.SwapBuildMode.bind(
		3
	))
	floorButton.pressed.connect(OpenBuildMenu)
	ConnectMouseHover(floorButton)
	
	var landButton = Button.new()
	landButton.add_to_group(resetGroup)
	landButton.text = "Buy Land"
	landButton.focus_mode = Control.FOCUS_NONE
	$BuildMenus/BuildMenu.add_child(landButton)
	
	landButton.pressed.connect(Global.buildSys.SwapBuildMode.bind(
		4
	))
	landButton.pressed.connect(OpenBuildMenu)
	ConnectMouseHover(landButton)
	
	var deleteButton = Button.new()
	deleteButton.add_to_group(resetGroup)
	deleteButton.text = "Delete"
	deleteButton.focus_mode = Control.FOCUS_NONE
	$BuildMenus/BuildMenu.add_child(deleteButton)
	
	deleteButton.pressed.connect(Global.buildSys.SwapBuildMode.bind(
		0
	))
	deleteButton.pressed.connect(OpenBuildMenu)
	ConnectMouseHover(deleteButton)
	

func OpenBuildShopMenu(menuMode : int):
	match menuMode:
		1:
			OpenBuildObjects()
	
func OpenBuildObjects():
	var structureDic = Global.buildSys.structureDic
	for obj in structureDic:
		var objButton = Button.new()
		objButton.add_to_group(resetGroup)
		objButton.text = str("Place ", structureDic[obj]["name"], " - $", structureDic[obj]["cost"])
		objButton.focus_mode = Control.FOCUS_NONE
		$BuildMenus/BuildObjectsMenu.add_child(objButton)

		objButton.pressed.connect(Global.buildSys.SwapBuildPref.bind(
			structureDic[obj]["prefab"], 1
		))
		ConnectMouseHover(objButton)

func OpenStockMenu(shelf : Node3D):
	ResetUI()
		
	var fullStockButton = Button.new()
	fullStockButton.add_to_group(resetGroup)
	fullStockButton.text = "Fully stock"
	$StockMenu.add_child(fullStockButton)
	
	fullStockButton.pressed.connect(Global.stockSys.FullyStockShelf.bind(
		shelf
	))
	ConnectMouseHover(fullStockButton)
	
	#$StockMenu.position = get_viewport().get_mouse_position()
	for stockType in Global.stockSys.stockInventory:
		if stockType == 000:
			continue
		var stockButton = Button.new()
		stockButton.add_to_group(resetGroup)
		stockButton.text = "Stock with " + Global.stockSys.stockInventory[stockType]["name"]
		$StockMenu.add_child(stockButton)
		
		stockButton.pressed.connect(Global.stockSys.StockShelf.bind(
			stockType,
			shelf
		))
		ConnectMouseHover(stockButton)

func OpenPlotBuyMenu(plot):
	var plotButton = Button.new()
	plotButton.add_to_group(resetGroup)
	plotButton.text = "Buy this plot for $" + str(Global.landPrice)
	add_child(plotButton)
	
	plotButton.set_anchors_and_offsets_preset(PRESET_CENTER)
	
	plotButton.pressed.connect(Global.landSys.BuyPlot.bind(plot))
	plotButton.pressed.connect(MenuUpdate)
	ConnectMouseHover(plotButton)
	
	var returnButton = CreateReturnButton(MenuUpdate)
	returnButton.pressed.connect(Global.landSys.ResetSelectedPlot)
	returnButton.pressed.connect(Global.landSys.ResetHighlightedPlot)
	
func ConnectMouseHover(element):
	element.mouse_entered.connect(Global.SetHoverMode.bind(
		true
	))
	element.mouse_exited.connect(Global.SetHoverMode.bind(
		false
	))

func CreateReturnButton(ButtonConnection):
	if get_tree().get_nodes_in_group("ReturnButton"):
		get_tree().get_nodes_in_group("ReturnButton")[0].queue_free()
	var returnButton : Button = Button.new()
	returnButton.text = "Return"
	add_child(returnButton)
	returnButton.add_to_group("ReturnButton")
	returnButton.add_to_group(resetGroup)
	returnButton.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	returnButton.position.y = 50
	returnButton.pressed.connect(ButtonConnection)
	ConnectMouseHover(returnButton)
	
	# return the button incase extra connections need to be made
	return returnButton
