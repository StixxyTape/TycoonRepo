extends Control

var stockMenuOpen : bool = false

func _ready() -> void:
	Global.switchSignal.connect(MenuUpdate)
	EstablishUI()
	
func MenuUpdate():
	HideBuildShopMenus()
	if !Global.buildMode:
		$BuildMenus/BuildMenu.visible = false
	else:
		$BuildMenus/BuildMenu.visible = true
		
func EstablishUI():
	EstablishStock()
	EstablishSaveLoad()
	EstablishBuild()
	EstablishBuildObjects()
	HideBuildShopMenus()
	
func EstablishStock():
	for stockType in Global.stockSys.stockInventory:
		if stockType == 000:
			continue
		var newHBox = HBoxContainer.new()
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
	
	saveButton.pressed.connect(SaveLoad.SaveGame)
	ConnectMouseHover(saveButton)
	
	var loadButton = Button.new()
	loadButton.text = "Load"
	loadButton.focus_mode = Control.FOCUS_NONE
	$SaveMenu.add_child(loadButton)
	
	loadButton.pressed.connect(SaveLoad.LoadGame)
	ConnectMouseHover(loadButton)

func EstablishBuild():
	var objButton = Button.new()
	objButton.text = "Build Objects"
	objButton.focus_mode = Control.FOCUS_NONE
	$BuildMenus/BuildMenu.add_child(objButton)
	
	objButton.pressed.connect(Global.buildSys.SwapBuildMode.bind(
		1
	))
	objButton.pressed.connect(HideBuildShopMenus)
	objButton.pressed.connect(OpenBuildShopMenu.bind("BuildObjectsMenu"))
	ConnectMouseHover(objButton)
	
	var edgeButton = Button.new()
	edgeButton.text = "Build Edges"
	edgeButton.focus_mode = Control.FOCUS_NONE
	$BuildMenus/BuildMenu.add_child(edgeButton)
	
	edgeButton.pressed.connect(Global.buildSys.SwapBuildMode.bind(
		2
	))
	edgeButton.pressed.connect(HideBuildShopMenus)
	ConnectMouseHover(edgeButton)
	
	var floorButton = Button.new()
	floorButton.text = "Build Floors"
	floorButton.focus_mode = Control.FOCUS_NONE
	$BuildMenus/BuildMenu.add_child(floorButton)
	
	floorButton.pressed.connect(Global.buildSys.SwapBuildMode.bind(
		3
	))
	floorButton.pressed.connect(HideBuildShopMenus)
	ConnectMouseHover(floorButton)
	
	var deleteButton = Button.new()
	deleteButton.text = "Delete"
	deleteButton.focus_mode = Control.FOCUS_NONE
	$BuildMenus/BuildMenu.add_child(deleteButton)
	
	deleteButton.pressed.connect(Global.buildSys.SwapBuildMode.bind(
		0
	))
	deleteButton.pressed.connect(HideBuildShopMenus)
	ConnectMouseHover(deleteButton)

func EstablishBuildObjects():
	var structureDic = Global.buildSys.structureDic
	for obj in structureDic:
		var objButton = Button.new()
		objButton.text = str("Place ", structureDic[obj]["name"])
		objButton.focus_mode = Control.FOCUS_NONE
		$BuildMenus/BuildObjectsMenu.add_child(objButton)
		
		objButton.pressed.connect(Global.buildSys.SwapBuildPref.bind(
			obj, 1
		))
		ConnectMouseHover(objButton)
	
func HideBuildShopMenus():
	for child in $BuildMenus.get_children():
		if child.name != "BuildMenu":
			child.visible = false
				
func OpenBuildShopMenu(menu : String):
	get_node("BuildMenus/" + menu).visible = true
		
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

func OpenStockMenu(shelf : Node3D):
	stockMenuOpen = true
	
	for child in $StockMenu.get_children():
		child.queue_free()
	if get_tree().get_nodes_in_group("ReturnButton"):
		get_tree().get_nodes_in_group("ReturnButton")[0].queue_free()
		
	var fullStockButton = Button.new()
	fullStockButton.text = "Fully stock"
	$StockMenu.add_child(fullStockButton)
	
	fullStockButton.pressed.connect(Global.stockSys.FullyStockShelf.bind(
		shelf
	))
	#$StockMenu.position = get_viewport().get_mouse_position()
	for stockType in Global.stockSys.stockInventory:
		if stockType == 000:
			continue
		var stockButton = Button.new()
		stockButton.text = "Stock with " + Global.stockSys.stockInventory[stockType]["name"]
		$StockMenu.add_child(stockButton)
		
		stockButton.pressed.connect(Global.stockSys.StockShelf.bind(
			stockType,
			shelf
		))
		ConnectMouseHover(stockButton)
	ConnectMouseHover(fullStockButton)
	CreateReturnButton()
		
func CloseStockMenu():
	stockMenuOpen = false
	for child in $StockMenu.get_children():
		child.queue_free()
	if get_tree().get_nodes_in_group("ReturnButton"):
		get_tree().get_nodes_in_group("ReturnButton")[0].queue_free()

func ConnectMouseHover(element):
	element.mouse_entered.connect(Global.SetHoverMode.bind(
		true
	))
	element.mouse_exited.connect(Global.SetHoverMode.bind(
		false
	))

func CreateReturnButton():
	var returnButton : Button = Button.new()
	returnButton.text = "Return"
	add_child(returnButton)
	returnButton.add_to_group("ReturnButton")
	returnButton.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	returnButton.pressed.connect(Global.stockSys.ExitStock)
	ConnectMouseHover(returnButton)
