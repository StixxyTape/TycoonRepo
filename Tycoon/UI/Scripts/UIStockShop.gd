extends Control

var basket : Array

func _ready() -> void:
	CreateStockShopButton()

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
		
	for stockType in Global.stockSys.stockInventory:
		if stockType == 000:
			continue
		var stockHBox = HBoxContainer.new()
		stockHBox.add_to_group(get_parent().resetGroup)
		$StockShopMenu.add_child(stockHBox)
		
		var stockLabel = Label.new()
		stockLabel.text = "Purchase " + Global.stockSys.stockInventory[stockType]["name"]
		stockHBox.add_child(stockLabel)

		#var stockPurchaseButton = Button.new()
		#stockPurchaseButton
		#$StockShopMenu.add_child(stockButton)
		
		#stockButton.pressed.connect(Global.stockSys.StockShelf.bind(
			#stockType,
			#shelf
		#))
		#ConnectMouseHover(stockButton)
		
	get_parent().CreateReturnButton(CloseStockShop)

func CloseStockShop():
	get_parent().MenuUpdate()
