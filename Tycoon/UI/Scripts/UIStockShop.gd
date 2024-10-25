extends Control

var customQuantityBox : PackedScene = preload("res://UI/Scenes/CustomQuantityBox.tscn")

var stockSelectButtonGroup : String = "StockSelectButton"
var currentStockType : int = 000

var quantityPresets : Array = [1, 5, 10, 20, 50]
var currentQuantity : float = 0

var basket : Dictionary = {}

func _ready() -> void:
	CreateStockShopButton()
	$StockShopMenu.child_order_changed.connect(AddResetGroup)

# Gets the most recently added child and adds it to the reset group
func AddResetGroup():
	if $StockShopMenu != null and $StockShopMenu.get_children().size() > 0:
		$StockShopMenu.get_child($StockShopMenu.get_children().size() - 1).add_to_group(get_parent().resetGroup)
	
func CreateStockShopButton():
	var stockShopButton = Button.new()
	stockShopButton.text = "Open Stock Shop"
	stockShopButton.add_to_group(get_parent().resetGroup)
	stockShopButton.set_anchors_and_offsets_preset(PRESET_CENTER_TOP)
	stockShopButton.position.y = 50
	stockShopButton.pressed.connect(OpenStockShop)
	add_child(stockShopButton)
	
func OpenStockShop():
	get_parent().ResetUI()
	
	var stockSelectLabel : Label = Label.new()
	stockSelectLabel.text = "Choose Stock"
	$StockShopMenu.add_child(stockSelectLabel)
	
	for stockType in Global.stockSys.stockInventory:
		if stockType == 000:
			continue
		var stockSelect : Button = Button.new()
		var buttonStr : String = str(
			"Purchase " + Global.stockSys.stockInventory[stockType]["name"] + 
			" - " + "$" + str(Global.stockSys.stockInventory[stockType]["purchasePrice"]))
		CreateButton(stockSelect, buttonStr, $StockShopMenu)
		
		stockSelect.add_to_group(stockSelectButtonGroup)
		
		stockSelect.pressed.connect(SelectStock.bind(
			stockType,
			stockSelect
		))
		stockSelect.pressed.connect(UpdateAddBasketText)
		
	var quantitySelectLabel : Label = Label.new()
	quantitySelectLabel.text = "Choose Quantity"
	$StockShopMenu.add_child(quantitySelectLabel)
	
	var quantityMenu : HBoxContainer = HBoxContainer.new()
	quantityMenu.alignment = BoxContainer.ALIGNMENT_CENTER
	quantityMenu.name = "QuantityMenu"
	$StockShopMenu.add_child(quantityMenu)
	
	for quantity in quantityPresets:
		var quantitySelect : Button = Button.new()
		CreateButton(quantitySelect, str(quantity), quantityMenu)

		quantitySelect.pressed.connect(SelectQuantity.bind(
			quantity,
			quantitySelect
		))
		quantitySelect.pressed.connect(UpdateAddBasketText)
	
	var customQuantityButton : Button = customQuantityBox.instantiate()
	get_parent().ConnectMouseHover(customQuantityButton)
	customQuantityButton.pressed.connect(SelectQuantity.bind(
		"Custom",
		customQuantityButton
	))
	customQuantityButton.pressed.connect(UpdateAddBasketText)
	customQuantityButton.valueChanged.connect(CustomQuantityUpdate)
	$StockShopMenu.add_child(customQuantityButton)
	
	# An invisible label to add some space for the add to basket button
	var bufferLabel : Label = Label.new()
	$StockShopMenu.add_child(bufferLabel)
	
	var addToBasketLabel : Label = Label.new()
	addToBasketLabel.name = "AddToBasketLabel"
	addToBasketLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$StockShopMenu.add_child(addToBasketLabel)
	
	var purchaseButton : Button = Button.new()
	CreateButton(purchaseButton, "Purchase", $StockShopMenu)
	purchaseButton.toggle_mode = false
	purchaseButton.pressed.connect(PurchaseStock)
	
	get_parent().CreateReturnButton(CloseStockShop)
	

func SelectStock(stockType, currentButton):
	for child in $StockShopMenu.get_children():
		if child == currentButton:
			continue
		if child.is_in_group(stockSelectButtonGroup):
			child.button_pressed = false
			
	currentStockType = stockType

func SelectQuantity(quantity, currentButton):
	if currentButton.button_pressed == false:
		currentQuantity = 0
		return
		
	var quantityMenu = get_node("StockShopMenu/QuantityMenu")
	for child in quantityMenu.get_children():
		if child == currentButton:
			continue
		child.button_pressed = false
	if str(quantity) != "Custom":
		get_node("StockShopMenu/CustomQuantityBox").button_pressed = false
		currentQuantity = quantity
	else:
		currentQuantity = int(get_node("StockShopMenu/CustomQuantityBox").text)
		

func CustomQuantityUpdate(newQuantity):
	currentQuantity = newQuantity
	UpdateAddBasketText()
	
func UpdateAddBasketText():
	if currentQuantity != 0 and currentStockType != 000:
		var basketStr = (str(currentQuantity) + "x" + " " + 
		Global.stockSys.stockInventory[currentStockType]["name"] + " -  $" + 
		str(Global.stockSys.stockInventory[currentStockType]["purchasePrice"] * currentQuantity)
		)
		$StockShopMenu.get_node("AddToBasketLabel").text = basketStr
	else:
		$StockShopMenu.get_node("AddToBasketLabel").text = ""

func PurchaseStock():
	var totalCost : float = currentQuantity * Global.stockSys.stockInventory[currentStockType]["purchasePrice"]
	
	if Global.playerMoney >= totalCost:
		Global.playerMoney -= totalCost
		Global.stockSys.stockInventory[currentStockType]["amount"] += currentQuantity
		Global.UpdateUI()
	
		
func CloseStockShop():
	get_parent().MenuUpdate()

func CreateButton(button, buttonText, buttonParent):
	button.text = buttonText
	
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true

	get_parent().ConnectMouseHover(button)
	buttonParent.add_child(button)
