extends Control

@onready var stockSys : Node3D = get_tree().current_scene.get_node("StockSystem")

var stockMenuOpen : bool = false

func _ready() -> void:
	EstablishUI()
	
func EstablishUI():
	EstablishStock()

func EstablishStock():
	for stockType in stockSys.stockInventory:
		if stockType == 000:
			continue
		var newHBox = HBoxContainer.new()
		$Stock.add_child(newHBox)
		var nameLabel = Label.new()
		var countLabel = Label.new()
		nameLabel.text = stockSys.stockInventory[stockType]["name"] + ": "
		countLabel.text = str(stockSys.stockInventory[stockType]["amount"])
		newHBox.add_child(nameLabel)
		newHBox.add_child(countLabel)
		
		stockSys.stockInventory[stockType]["countLabel"] = countLabel
	
func StockUpdate():
	for stockType in stockSys.stockInventory:
		if stockType == 000:
			continue
		var stockLabel = stockSys.stockInventory[stockType]["countLabel"]
		var amount = stockSys.stockInventory[stockType]["amount"]
		stockLabel.text = str(amount)

func ShelfUpdate(shelf : Node3D):
	var stockName : String = stockSys.stockInventory[shelf.stockType]["name"]
	$Shelf/HBoxContainer/Label.text = "Current Shelf: " + shelf.name
	$Shelf/HBoxContainer2/Label.text = "Stock Type: " + stockName
	$Shelf/HBoxContainer4/Label.text = "Max Amount: " + str(shelf.maxStock)
	$Shelf/HBoxContainer3/Label.text = "Stock Amount: " + str(shelf.currentStock)

func OpenStockMenu(shelf : Node3D):
	stockMenuOpen = true
	
	for child in $StockMenu.get_children():
		child.queue_free()
	if get_tree().get_nodes_in_group("ReturnButton"):
		get_tree().get_nodes_in_group("ReturnButton")[0].queue_free()
		
	#$StockMenu.position = get_viewport().get_mouse_position()
	for stockType in stockSys.stockInventory:
		if stockType == 000:
			continue
		var stockButton = Button.new()
		stockButton.text = "Stock with " + stockSys.stockInventory[stockType]["name"]
		$StockMenu.add_child(stockButton)
		
		stockButton.pressed.connect(stockSys.StockShelf.bind(
			stockType,
			shelf
		))
		ConnectMouseHover(stockButton)
	var returnButton : Button = Button.new()
	returnButton.text = "Return"
	add_child(returnButton)
	returnButton.add_to_group("ReturnButton")
	returnButton.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	returnButton.pressed.connect(stockSys.ExitStock)
	ConnectMouseHover(returnButton)
		
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
